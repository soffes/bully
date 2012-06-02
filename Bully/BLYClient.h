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

@property (nonatomic, strong, readonly) NSString *socketID;
@property (nonatomic, weak, readonly) id<BLYClientDelegate> delegate;

+ (NSString *)version;

- (id)initWithAppKey:(NSString *)appKey delegate:(id<BLYClientDelegate>)delegate;

- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName;
- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName authenticationBlock:(BLYChannelAuthenticationBlock)authenticationBlock;

- (void)connect;
- (void)disconnect;
- (BOOL)isConnected;

@end


@protocol BLYClientDelegate <NSObject>

@optional

- (void)bullyClientDidConnect:(BLYClient *)client;
- (void)bullyClient:(BLYClient *)client didReceiveError:(NSError *)error;
- (void)bullyClientDidDisconnect:(BLYClient *)client;

@end