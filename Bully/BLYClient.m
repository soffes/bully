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

@implementation BLYClient

@synthesize socketID = _socketID;
@synthesize delegate = _delegate;
@synthesize webSocket = _webSocket;
@synthesize appKey = _appKey;
@synthesize connectedChannels = _connectedChannels;

- (void)setWebSocket:(SRWebSocket *)webSocket {
	if (_webSocket) {
		_webSocket.delegate = nil;
		[_webSocket close];
	}

	_webSocket = webSocket;
	_webSocket.delegate = self;
}


+ (NSString *)version {
	return @"0.1.0";
}


- (id)initWithAppKey:(NSString *)appKey delegate:(id<BLYClientDelegate>)delegate {
	if ((self = [super init])) {
		self.appKey = appKey;
		self.delegate = delegate;
		[self connect];
	}
	return self;
}


- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName {
	return [self subscribeToChannelWithName:channelName authenticationBlock:nil];
}


- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName authenticationBlock:(BLYChannelAuthenticationBlock)authenticationBlock {
	BLYChannel *channel = [_connectedChannels objectForKey:channelName];
	if (channel) {
		return channel;
	}

	channel = [[BLYChannel alloc] initWithName:channelName client:self authenticationBlock:authenticationBlock];
	[channel subscribe];
	[_connectedChannels setObject:channel forKey:channelName];
	return channel;
}


- (void)connect {
	if (self.webSocket) {
		return;
	}
	
	NSString *urlString = [[NSString alloc] initWithFormat:@"wss://ws.pusherapp.com/app/%@?protocol=5&client=bully&version=%@&flash=false", self.appKey, [[self class] version]];
	NSURL *url = [[NSURL alloc] initWithString:urlString];
	self.webSocket = [[SRWebSocket alloc] initWithURL:url];
	[self.webSocket open];

	if (!self.connectedChannels) {
		self.connectedChannels = [[NSMutableDictionary alloc] init];
	}
}


- (void)disconnect {
	self.webSocket = nil;
	if ([self.delegate respondsToSelector:@selector(bullyClientDidDisconnect:)]) {
		[self.delegate bullyClientDidDisconnect:self];
	}
	self.socketID = nil;
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
	[self.webSocket send:[NSJSONSerialization dataWithJSONObject:object options:0 error:nil]];
}


- (void)_reconnectChannels {
	for (NSString *channelName in self.connectedChannels) {
		BLYChannel *channel = [self.connectedChannels objectForKey:channelName];
		[channel subscribe];
	}
}


- (void)_removeChannel:(BLYChannel *)channel {
	if (!channel) {
		return;
	}
	
	[self.connectedChannels removeObjectForKey:channel.name];
}


#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)messageString {
//	NSLog(@"webSocket:didReceiveMessage: %@", messageString);
	
	NSData *messageData = [(NSString *)messageString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *message = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:nil];

	// Get event out of Pusher message
	NSString *eventName = [message objectForKey:@"event"];
	id eventMessage = [message objectForKey:@"data"];
	if (eventMessage && [eventMessage isKindOfClass:[NSString class]]) {
		NSData *eventMessageData = [eventMessage dataUsingEncoding:NSUTF8StringEncoding];
		eventMessage = [NSJSONSerialization JSONObjectWithData:eventMessageData options:0 error:nil];
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
			// See if they are binded to this event
			BLYChannelEventBlock block = [channel.subscriptions objectForKey:eventName];
			if (block) {
				// Call their block with the event data
				block(eventMessage);
			}
		}
	}
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
