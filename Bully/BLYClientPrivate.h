//
//  BLYClientPrivate.h
//  Bully
//
//  Created by Sam Soffes on 6/2/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

@class BLYChannel;

@interface BLYClient () <SRWebSocketDelegate>

@property (nonatomic, strong, readwrite) NSString *socketID;
@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, strong) NSMutableDictionary *connectedChannels;

- (void)_sendEvent:(NSString *)eventName dictionary:(NSDictionary *)dictionary;
- (void)_reconnectChannels;
- (void)_unsubscribeChannel:(BLYChannel *)channel;

@end
