//
//  BLYClient
//  Bully
//
//  Created by Sam Soffes on 6/1/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//

#import "BLYClient.h"
#import "BLYClientPrivate.h"
#import "BLYChannel.h"
#import "BLYChannelPrivate.h"
#import "Reachability.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h> // For background notificaitons
#endif

@implementation BLYClient {
	Reachability *_reachability;

#if TARGET_OS_IPHONE
	BOOL _appIsBackgrounded;
#endif
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
	return @"0.2.0";
}


#pragma mark - NSObject

- (void)dealloc {
	[_reachability stopNotifier];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	_automaticallyReconnect = NO;
	_automaticallyDisconnectInBackground = NO;
	[self disconnect];
}


#pragma mark - Initializer

- (id)initWithAppKey:(NSString *)appKey delegate:(id<BLYClientDelegate>)delegate {
    return [self initWithAppKey:appKey delegate:delegate hostName:nil];
}

- (id)initWithAppKey:(NSString *)appKey delegate:(id<BLYClientDelegate>)delegate hostName:(NSString *)hostName {
    if ((self = [super init])) {
		self.appKey = appKey;
		self.delegate = delegate;
        
		// Automatically reconnect by default
		_automaticallyReconnect = YES;
        
        if (hostName != nil) {
            _hostName = hostName;
        } else {
            _hostName = @"ws.pusherapp.com";
        }
        
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
		_reachability = [Reachability reachabilityWithHostname:self.hostName];
		[_reachability startNotifier];
		[notificationCenter addObserver:self selector:@selector(_reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
        
		// Connect!
		[self connect];
	}
	return self;
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


#pragma mark - Managing the Connection

- (void)connect {
	if ([self isConnected]) {
		return;
	}

	NSString *urlString = [[NSString alloc] initWithFormat:@"wss://%@/app/%@?protocol=5&client=bully&version=%@&flash=false", self.hostName, self.appKey, [[self class] version]];
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

	self.webSocket = nil;
	if ([self.delegate respondsToSelector:@selector(bullyClientDidDisconnect:)]) {
		[self.delegate bullyClientDidDisconnect:self];
	}
	self.socketID = nil;

	// If we shouldn't auto reconnect, stop
	if (!_automaticallyReconnect) {
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


- (BOOL)isConnected {
	return self.webSocket != nil;
}


#pragma mark - Private

- (void)_sendEvent:(NSString *)eventName dictionary:(NSDictionary *)dictionary {
	if (self.webSocket.readyState != SR_OPEN) {
		return;
	}
    
	NSDictionary *object = [[NSDictionary alloc] initWithObjectsAndKeys:
							eventName, @"event",
							dictionary, @"data",
							nil];
	[self.webSocket send:[NSJSONSerialization dataWithJSONObject:object options:NSJSONReadingAllowFragments error:nil]];
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


#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)messageString {
    //  NSLog(@"webSocket:didReceiveMessage: %@", messageString);
    
	NSData *messageData = [(NSString *)messageString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *message = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:nil];
    
	// Get event out of Pusher message
	NSString *eventName = [message objectForKey:@"event"];
	id eventMessage = [message objectForKey:@"data"];
    NSError *jsonError = nil;
    NSData *eventMessageData = nil;
	if (eventMessage && [eventMessage isKindOfClass:[NSString class]]) {
		eventMessageData = [eventMessage dataUsingEncoding:NSUTF8StringEncoding];
		eventMessage = [NSJSONSerialization JSONObjectWithData:eventMessageData options:0 error:&jsonError];
	}
    
	// Check for pusher:connect_established
	if ([eventName isEqualToString:@"pusher:connection_established"]) {
		self.socketID = [eventMessage objectForKey:@"socket_id"];
		if ([self.delegate respondsToSelector:@selector(bullyClientDidConnect:)]) {
			[self.delegate bullyClientDidConnect:self];
		}
		[self _reconnectChannels];
		return;
	}
    
	// Check for channel events
	NSString *channelName = [message objectForKey:@"channel"];
	if (channelName) {
		// Find channel
		BLYChannel *channel = [self.connectedChannels objectForKey:channelName];
        
		// Ensure the user is subscribed to the channel
		if (channel) {
            
            if (jsonError != nil && channel.errorBlock != nil) {
                channel.errorBlock(jsonError, BLYErrorTypeJSONParser);
            }
            
			// See if they are binded to this event
			BLYChannelEventBlock block = [channel.subscriptions objectForKey:eventName];
			if (block) {
				// Call their block with the event data
				block(eventMessage);
			}
			return;
		}
        
#if DEBUG
		NSLog(@"[Bully] Event sent to unsubscribed channel: %@", message);
#endif
		return;
	}
    
	// Other events
#if DEBUG
	NSLog(@"[Bully] Unknown event: %@", message);
#endif
}


- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
//	NSLog(@"webSocket:didFailWithError: %@", error);
	self.webSocket = nil;
}


- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
//	NSLog(@"webSocket:didCloseWithCode: %i reason: %@ wasClean: %i", code, reason, wasClean);
	[self disconnect];
}

@end
