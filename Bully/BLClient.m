//
//  BLClient.m
//  Bully
//
//  Created by Sam Soffes on 6/1/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//

#import "BLClient.h"
#import "BLChannel.h"
#import <SocketRocket/SRWebSocket.h>

@interface BLClient () <SRWebSocketDelegate>
@property (nonatomic, strong, readwrite) NSString *socketID;
@property (nonatomic, strong) SRWebSocket *webSocket;

- (void)_sendEvent:(NSString *)eventName dictionary:(NSDictionary *)dictionary;
@end

@implementation BLClient {
	NSMutableDictionary *_connectedChannels;
}

@synthesize socketID = _socketID;
@synthesize eventBlock = _eventBlock;
@synthesize webSocket = _webSocket;

+ (NSString *)version {
	return @"0.1.0";
}


- (id)initWithAppKey:(NSString *)appKey {
	if ((self = [super init])) {
		// Connect to Pusher
		NSString *urlString = [[NSString alloc] initWithFormat:@"wss://ws.pusherapp.com/app/%@?protocol=5&client=bully&version=%@&flash=false", appKey, [[self class] version]];
		NSURL *url = [[NSURL alloc] initWithString:urlString];
		self.webSocket = [[SRWebSocket alloc] initWithURL:url];
		self.webSocket.delegate = self;
		[self.webSocket open];

		_connectedChannels = [[NSMutableDictionary alloc] init];
	}
	return self;
}


- (BLChannel *)subscribe:(NSString *)channelName {
	BLChannel *channel = [_connectedChannels objectForKey:channelName];
	if (channel) {
		return channel;
	}

	[self _sendEvent:@"pusher:subscribe" dictionary:[[NSDictionary alloc] initWithObjectsAndKeys:
													 channelName, @"channel",
													 nil]];
	return nil;
}


#pragma mark - Private

- (void)_sendEvent:(NSString *)eventName dictionary:(NSDictionary *)dictionary {
	NSDictionary *object = [[NSDictionary alloc] initWithObjectsAndKeys:
							eventName, @"event",
							dictionary, @"data",
							nil];
	[self.webSocket send:[NSJSONSerialization dataWithJSONObject:object options:0 error:nil]];
}


#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
	NSLog(@"webSocketDidOpen: %@", webSocket);
}


- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
	NSData *messageData = [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:nil];
	NSLog(@"webSocket:didReceiveMessage: %@", dictionary);

	if ([[dictionary objectForKey:@"event"] isEqualToString:@"pusher:connection_established"]) {
		[self subscribe:@"test1"];
	}
}


- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
	NSLog(@"webSocket:didFailWithError: %@", error);
}


- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
	NSLog(@"webSocket:didCloseWithCode: %i reason: %@ wasClean: %i", code, reason, wasClean);
}

@end
