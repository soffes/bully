//
//  BLYChannel
//  Bully
//
//  Created by Sam Soffes on 6/1/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BLYClient;
@class BLYChannel;

typedef void (^BLYChannelEventBlock)(id message);
typedef void (^BLYChannelAuthenticationBlock)(BLYChannel *channel);

@interface BLYChannel : NSObject

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, weak, readonly) BLYClient *client;
@property (nonatomic, copy) BLYChannelAuthenticationBlock authenticationBlock;
@property (nonatomic, strong, readonly) NSDictionary *authenticationParameters;
@property (nonatomic, strong, readonly) NSData *authenticationParametersData;

- (BOOL)isPrivate;

- (void)bindToEvent:(NSString *)eventName block:(BLYChannelEventBlock)block;
- (void)unbindEvent:(NSString *)eventName;

- (void)subscribeWithAuthentication:(NSDictionary *)authentication;
- (void)unsubscribe;

@end
