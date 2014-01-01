//
//  BLYClientPrivate.h
//  Bully
//
//  Created by Sam Soffes on 6/2/12.
//  Copyright (c) 2012-2014 Sam Soffes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>
#import "BLYClient.h"

@class BLYChannel;

@interface BLYClient () <SRWebSocketDelegate>

@property (nonatomic, strong, readwrite) NSString *socketID;
@property (nonatomic, weak, readwrite) id<BLYClientDelegate> delegate;
@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, strong) NSMutableDictionary *connectedChannels;


- (void)_sendEvent:(NSString *)eventName dictionary:(NSDictionary *)dictionary;
- (void)_reconnectChannels;
- (void)_removeChannel:(BLYChannel *)channel;
- (void)_reachabilityChanged:(NSNotification *)notification;
- (void)_handleDisconnectAllowAutomaticReconnect:(BOOL)allowReconnect error:(NSError *)error;
- (void)_reconnectAfterDelay;

#if TARGET_OS_IPHONE
- (void)_appDidEnterBackground:(NSNotification *)notificaiton;
- (void)_appDidBecomeActive:(NSNotification *)notification;
#endif

@end
