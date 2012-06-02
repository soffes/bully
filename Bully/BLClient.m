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
@end

@implementation BLClient

@synthesize socketID = _socketID;
@synthesize webSocket = _webSocket;

+ (NSString *)version {
	return @"0.1.0";
}


- (id)initWithAppKey:(NSString *)appKey {
	if ((self = [super init])) {
		NSString *urlString = [[NSString alloc] initWithFormat:@"wss://ws.pusherapp.com/app/%@?protocol=5&client=bully&version=%@&flash=false", appKey, [[self class] version]];
		NSURL *url = [[NSURL alloc] initWithString:urlString];
		self.webSocket = [[SRWebSocket alloc] initWithURL:url];
		self.webSocket.delegate = self;
		[self.webSocket open];
	}
	return self;
}


- (BLChannel *)subscribe:(NSString *)channelName {
	return nil;
}


#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
	NSLog(@"webSocketDidOpen: %@", webSocket);
}


- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
	NSData *messageData = [(NSString *)message dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:messageData options:0 error:nil];
	NSLog(@"webSocket:didReceiveMessage: %@", dictionary);

}


- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
	NSLog(@"webSocket:didFailWithError: %@", error);
}


- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
	NSLog(@"webSocket:didCloseWithCode: %i reason: %@ wasClean: %i", code, reason, wasClean);
}

@end
