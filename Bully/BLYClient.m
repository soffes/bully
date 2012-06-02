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


- (id)initWithAppKey:(NSString *)appKey {
	if ((self = [super init])) {
		self.appKey = appKey;
		[self connect];
	}
	return self;
}


- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName {
	BLYChannel *channel = [_connectedChannels objectForKey:channelName];
	if (channel) {
		return channel;
	}

	[self _sendEvent:@"pusher:subscribe" dictionary:[[NSDictionary alloc] initWithObjectsAndKeys:
													 channelName, @"channel",
													 nil]];

	channel = [[BLYChannel alloc] initWithName:channelName];
	channel.client = self;
	[_connectedChannels setObject:channel forKey:channelName];
	return channel;
}


- (void)connect {
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
		[self _sendEvent:@"pusher:subscribe" dictionary:[[NSDictionary alloc] initWithObjectsAndKeys:
														 channelName, @"channel",
														 nil]];
	}
}


- (void)_unsubscribeChannel:(BLYChannel *)channel {
	if (!channel) {
		return;
	}
	
	[self _sendEvent:@"pusher:unsubscribe" dictionary:[[NSDictionary alloc] initWithObjectsAndKeys:
													 channel.name, @"channel",
													 nil]];
	[self.connectedChannels removeObjectForKey:channel.name];
}


#pragma mark - SRWebSocketDelegate

//- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
//	NSLog(@"webSocketDidOpen: %@", webSocket);
//}


- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)messageString {
	NSData *messageData = [(NSString *)messageString dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *message = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:nil];

	// Get event name out of Pusher message
	NSString *eventName = [message objectForKey:@"event"];

	// Check for pusher:connect_established
	if ([eventName isEqualToString:@"pusher:connection_established"]) {
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
				block([message objectForKey:@"data"]);
			}
		}
	}
}


//- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
//	NSLog(@"webSocket:didFailWithError: %@", error);
//}
//
//
//- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
//	NSLog(@"webSocket:didCloseWithCode: %i reason: %@ wasClean: %i", code, reason, wasClean);
//}

@end
