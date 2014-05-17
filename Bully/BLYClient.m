//
//  BLYClient
//  Bully
//
//  Created by Sam Soffes on 6/1/12.
//  Copyright (c) 2012-2014 Sam Soffes. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:

//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "BLYClient.h"
#import "BLYClientPrivate.h"
#import "BLYChannel.h"
#import "BLYChannelPrivate.h"
#import "Reachability.h"
#import "BLYEventPrivate.h"
#import "NSTimer+BLYWeakTimerAdditions.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h> // For background notifications
#endif

NSString *const BLYClientErrorDomain = @"BLYClientErrorDomain";

NSString *const BLYClientReceivedEventNotification = @"BLYClientReceivedEventNotification";
NSString *const kBLYEventUserInfoKey = @"event";

@implementation BLYClient {
	Reachability *_reachability;

#if TARGET_OS_IPHONE
	BOOL _appIsBackgrounded;
#endif
    
    NSTimer *_pingTimer;
}

@synthesize socketID = _socketID;
@synthesize delegate = _delegate;
@synthesize webSocket = _webSocket;
@synthesize appKey = _appKey;
@synthesize connectedChannels = _connectedChannels;
@synthesize automaticallyReconnect = _automaticallyReconnect;

#if TARGET_OS_IPHONE
@synthesize automaticallyDisconnectInBackground = _automaticallyDisconnectInBackground;
#endif


#pragma mark - Accessors

- (void)setWebSocket:(SRWebSocket *)webSocket {
	if (_webSocket) {
		_webSocket.delegate = nil;
		[_webSocket close];
	}

	_webSocket = webSocket;
	_webSocket.delegate = self;
}


#pragma mark - Class Methods


+ (NSString *)version {
	return @"0.2.2";
}

#pragma mark - init

- (id)initWithAppKey:(NSString *)appKey delegate:(id<BLYClientDelegate>)delegate {
    return [self initWithAppKey:appKey delegate:delegate hostName:@"ws.pusherapp.com"];
}

- (id)initWithAppKey:(NSString *)appKey delegate:(id<BLYClientDelegate>)delegate hostName:(NSString *)hostName {
    if ((self = [super init])) {
		self.appKey = appKey;
		self.delegate = delegate;
        
		// Automatically reconnect by default
		_automaticallyReconnect = YES;
        
        _hostName = hostName;
        
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
#if TARGET_OS_IPHONE
		// Assume we don't start in the background
		_appIsBackgrounded = NO;
        
		// Automatically disconnect in the background by default
		_automaticallyDisconnectInBackground = YES;
        
		// Listen for background changes
		[notificationCenter addObserver:self selector:@selector(_appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[notificationCenter addObserver:self selector:@selector(_appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
#endif
        
		// Start reachability
		_reachability = [Reachability reachabilityWithHostname:_hostName];
		[_reachability startNotifier];
		[notificationCenter addObserver:self selector:@selector(_reachabilityChanged:) name:kReachabilityChangedNotification object:_reachability];
        
		// Connect!
		[self connect];
	}
	return self;
}

- (void)dealloc {
	[_reachability stopNotifier];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
	_automaticallyReconnect = NO;
    
    [self _pingStopTimer];

#if TARGET_OS_IPHONE
	_automaticallyDisconnectInBackground = NO;
#endif

	[self disconnect];
}


#pragma mark - Subscribing

- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName {
	return [self subscribeToChannelWithName:channelName authenticationBlock:nil];
}


- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName authenticationBlock:(BLYChannelAuthenticationBlock)authenticationBlock {
	return [self subscribeToChannelWithName:channelName authenticationBlock:authenticationBlock errorBlock:nil];
}

- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName authenticationBlock:(BLYChannelAuthenticationBlock)authenticationBlock errorBlock:(BLYErrorBlock)errorBlock {
    BLYChannel *channel = [_connectedChannels objectForKey:channelName];
	if (channel) {
		return channel;
	}
    
	channel = [[BLYChannel alloc] _initWithName:channelName client:self authenticationBlock:authenticationBlock];
    channel.errorBlock = errorBlock;
	[channel _subscribe];
	[_connectedChannels setObject:channel forKey:channelName];
	return channel;
}


#pragma mark - Unsubscribe all

- (void)unsubscribeAll {
    NSArray *channels = [_connectedChannels allValues];
    [channels makeObjectsPerformSelector:@selector(unsubscribe)];
    self.connectedChannels = [NSMutableDictionary dictionary];
}


#pragma mark - Accessing

- (BLYChannel *)channelWithName:(NSString *)channelName {
    return [_connectedChannels objectForKey:channelName];
}


#pragma mark - Managing the Connection

- (void)connect {
	if ([self isConnected]) {
		return;
	}

	NSString *urlString = [[NSString alloc] initWithFormat:@"wss://%@/app/%@?protocol=6&client=bully&version=%@&flash=false", self.hostName, self.appKey, [[self class] version]];
	NSURL *url = [[NSURL alloc] initWithString:urlString];
	self.webSocket = [[SRWebSocket alloc] initWithURL:url];
	[self.webSocket open];

	if (!self.connectedChannels) {
		self.connectedChannels = [[NSMutableDictionary alloc] init];
	}
}


- (void)disconnect {
	if (![self isConnected]) {
		return;
	}

	// In case the connection was disconnected do not reconnect automatically
	[self _handleDisconnectAllowAutomaticReconnect:NO error:nil];
}



- (BOOL)isConnected {
	return self.webSocket != nil;
}


#pragma mark - Private

- (void)_sendEvent:(NSString *)eventName dictionary:(NSDictionary *)dictionary {
	if (self.webSocket.readyState != SR_OPEN) {
		return;
	}
    
    if (!eventName || eventName.length == 0){
        NSLog(@"[BULLY] Error: _sendEvent requires an eventName to be specified. Bailing.");
        return;
    }
    
	NSDictionary *object = [[NSDictionary alloc] initWithObjectsAndKeys:
							eventName, @"event",
							dictionary ?: @{}, @"data",
							nil];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    // We need to send the data as UTF8 encoded string,
    // otherwise it will be interpreted as binary data
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	[self.webSocket send:jsonString];
}


- (void)_reconnectChannels {
	for (NSString *channelName in self.connectedChannels) {
		BLYChannel *channel = [self.connectedChannels objectForKey:channelName];
		[channel _subscribe];
	}
}


- (void)_removeChannel:(BLYChannel *)channel {
	if (!channel) {
		return;
	}

	[self.connectedChannels removeObjectForKey:channel.name];
}

- (void)_handleDisconnectAllowAutomaticReconnect:(BOOL)allowReconnect error:(NSError *)error {
	self.webSocket = nil;
    
	// Notify delegate about the disconnection
	if ([self.delegate respondsToSelector:@selector(bullyClient:didDisconnectWithError:)]) {
		[self.delegate bullyClient:self didDisconnectWithError:error];
	}
    
	self.socketID = nil;
    
	// If we are not allowed to reconnect due to the pusher connection protocol
	// or if we shouldn't auto reconnect, stop
	if (!allowReconnect || !_automaticallyReconnect) {
		return;
	}
    
	// If it disconnected but Pusher is reachable
	if ([_reachability isReachable]) {
#if TARGET_OS_IPHONE
		// If the app is in the background and we automatically disconnect in the background, don't reconnect. Duh.
		if (_appIsBackgrounded && _automaticallyDisconnectInBackground) {
			return;
		}
#endif
		[self connect];
	}
}

- (void)_reconnectAfterDelay {
	// TODO: add delegate method?
	// bullyClient:WillReconnectAfterDelay:
#if DEBUG
	NSLog(@"[Bully] Reconnecting after 3 second delay");
#endif
    
	// back off for 3 seconds
	dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
	dispatch_after(timeout, dispatch_get_main_queue(), ^(void){
		if (_automaticallyReconnect) {
			[self connect];
		}
	});
}


#if TARGET_OS_IPHONE
- (void)_appDidEnterBackground:(NSNotification *)notificaiton {
	_appIsBackgrounded = YES;

	if (_automaticallyDisconnectInBackground) {
		[self disconnect];
	}
}


- (void)_appDidBecomeActive:(NSNotification *)notification {
	if (!_appIsBackgrounded) {
		return;
	}

	_appIsBackgrounded = NO;

	if (_automaticallyDisconnectInBackground) {
		[self connect];
	}
}
#endif


- (void)_reachabilityChanged:(NSNotification *)notification {
#if TARGET_OS_IPHONE
	// If the app is in the background, ignore the notificaiton
	if (_appIsBackgrounded) {
		return;
	}
#endif

	if ([_reachability isReachable]) {
		// If Pusher became reachable, reconnect
		[self connect];
	} else {
		// Disconnect if we lost the connection to Pusher
		[self disconnect];
	}
}


#pragma mark - Private - Ping-Pong
const NSTimeInterval BLYWebsocketPingTimeInterval = (2.0 * 60.0); // 2 minutes

- (void)_pingStartTimer {
    if (!_pingTimer){
        _pingTimer = [NSTimer bly_scheduledTimerWithTimeInterval:BLYWebsocketPingTimeInterval weakTarget:self selector:@selector(_pingTimerFired:) userInfo:nil repeats:YES];
    }
}

- (void)_pingStopTimer {
    [_pingTimer invalidate];
    _pingTimer = nil;
}

- (void)_pingNoteWebsocketMessageReceived {
    if (!_pingTimer) [self _pingStartTimer];

    // Bump the next fire date
    _pingTimer.fireDate = [NSDate dateWithTimeIntervalSinceNow:BLYWebsocketPingTimeInterval];
}

- (void)_sendPing {
    [self _sendEvent:@"pusher:ping" dictionary:nil];
}

- (void)_sendPong {
    [self _sendEvent:@"pusher:pong" dictionary:nil];
}


- (void)_pingTimerFired:(NSTimer *)timer {
    [self _sendPing];
}

#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)messageString {
//	NSLog(@"webSocket:didReceiveMessage: %@", messageString);

	NSData *messageData = [(NSString *)messageString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *message = [NSJSONSerialization JSONObjectWithData:messageData options:NSJSONReadingAllowFragments error:nil];

	// Get event out of Pusher message
    BLYEvent *event = [[BLYEvent alloc] _initWithRawEventDictionary:message andClient:self];

    // Error; Bail
    if (!event) {
        NSLog(@"[Bully] Error: unable to create event from message:'%@'", messageString);
        return;
    }
    
	// Check for pusher:connect_established
	if ([event.name isEqualToString:@"pusher:connection_established"]) {
		self.socketID = [event.message objectForKey:@"socket_id"];
		if ([self.delegate respondsToSelector:@selector(bullyClientDidConnect:)]) {
			[self.delegate bullyClientDidConnect:self];
		}
        [self _reconnectChannels];
        [self _pingStartTimer];
		return;
	}

    // Note websocket still connected
    [self _pingNoteWebsocketMessageReceived];

    // Check for ping message; respond with pong
	if ([event.name isEqualToString:@"pusher:ping"]) {
        [self _sendPong];
        return;
    }
    
    // Ignore pong events
	if ([event.name isEqualToString:@"pusher:pong"]) {
        return;
    }
    
    
    // Send a generic event notification, for all events other than connection established stuff
    [[NSNotificationCenter defaultCenter] postNotificationName:BLYClientReceivedEventNotification object:self userInfo:[NSDictionary dictionaryWithObject:event forKey:kBLYEventUserInfoKey]];

    if ([self.delegate respondsToSelector:@selector(bullyClient:didReceiveEvent:)]) {
        [self.delegate bullyClient:self didReceiveEvent:event];
    }
    
	// Dispatch channel events using the respective channel
	if (event.channel) {
        [event.channel _dispatchEvent:event];
		return;
	}
    
    if (event.channelName) {
    #if DEBUG
            NSLog(@"[Bully] Event sent to unsubscribed(unknown) channel: %@", event.channelName);
    #endif
		return;
    }

    
    // Check for pusher:error
    if ([event.name isEqualToString:@"pusher:error"]) {
        // find error code and error message
        NSInteger errorCode = 0;
        NSString *eventCode = [event.message objectForKey:@"code"];
        if ([eventCode respondsToSelector:@selector(integerValue)]) {
            errorCode = [eventCode integerValue];
        }
        NSString *errorMessage = [event.message objectForKey:@"message"];
        
        NSError *error = [NSError errorWithDomain:BLYClientErrorDomain code:errorCode userInfo:@{@"reason": errorMessage}];
        
        if ([self.delegate respondsToSelector:@selector(bullyClient:didReceiveError:)]) {
            [self.delegate bullyClient:self didReceiveError:error];
        }
        return;
    }
    
    
	// Other events
#if DEBUG
	NSLog(@"[Bully] Unknown event: %@", message);
#endif
}


- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
//	NSLog(@"webSocket:didFailWithError: %@", error);
	[self _handleDisconnectAllowAutomaticReconnect:NO error:error];
	[self _reconnectAfterDelay];
}


- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    [self _pingStopTimer];
	
    // Check for error codes based on the Pusher Websocket protocol
	// See http://pusher.com/docs/pusher_protocol
	// Protocol >= 6 also exposes a human-readable reason why the disconnect happened
	NSError *error = [NSError errorWithDomain:BLYClientErrorDomain code:code userInfo:@{@"reason": reason}];
    
	// 4000-4099 -> The connection SHOULD NOT be re-established unchanged.
	if (code >= 4000 && code <= 4099) {
		// Do not reconnect
		[self _handleDisconnectAllowAutomaticReconnect:NO error:error];
		return;
	}
    
	// 4200-4299 -> The connection SHOULD be re-established immediately.
	if(code >= 4200 && code <= 4299) {
		// Connect immediately
		[self _handleDisconnectAllowAutomaticReconnect:YES error:error];
		return;
    }
    
	// Handle all other error codes
	// i.e. 4100-4199 -> The connection SHOULD be re-established after backing off.
	[self _handleDisconnectAllowAutomaticReconnect:NO error:error];
	[self _reconnectAfterDelay];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, hostName: '%@'>", NSStringFromClass([self class]), self, _hostName];
}

@end
