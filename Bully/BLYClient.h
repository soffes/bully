//
//  BLYClient
//  Bully
//
//  Created by Sam Soffes on 6/1/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLYChannel.h"

@protocol BLYClientDelegate;

@interface BLYClient : NSObject

// error domain for client errors
extern NSString *const BLYClientErrorDomain;

@property (nonatomic, strong, readonly) NSString *socketID;
@property (nonatomic, weak, readonly) id<BLYClientDelegate> delegate;
@property (nonatomic, assign) BOOL automaticallyReconnect; // Default is YES

@property (nonatomic, strong, readonly) NSString *hostName;

#if TARGET_OS_IPHONE
@property (nonatomic, assign) BOOL automaticallyDisconnectInBackground; // Default is YES
#endif

// Bully Version
+ (NSString *)version;

// Initializer
- (id)initWithAppKey:(NSString *)appKey delegate:(id<BLYClientDelegate>)delegate;
- (id)initWithAppKey:(NSString *)appKey delegate:(id<BLYClientDelegate>)delegate hostName:(NSString *)hostName;

// Subscribing
- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName;
- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName authenticationBlock:(BLYChannelAuthenticationBlock)authenticationBlock;
- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName authenticationBlock:(BLYChannelAuthenticationBlock)authenticationBlock errorBlock:(BLYErrorBlock)errorBlock;

// Unsubscribe all
- (void)unsubscribeAll;

// Managing the Connection
- (void)connect;
- (void)disconnect;
- (BOOL)isConnected;

@end


@protocol BLYClientDelegate <NSObject>

@optional

- (void)bullyClientDidConnect:(BLYClient *)client;
- (void)bullyClient:(BLYClient *)client didReceiveError:(NSError *)error;
- (void)bullyClientDidDisconnect:(BLYClient *)client __attribute__((deprecated("Use bullyClient:didDisconnectWithError instead")));
- (void)bullyClient:(BLYClient *)client didDisconnectWithError:(NSError *)error;

@end
