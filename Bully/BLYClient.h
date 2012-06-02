//
//  BLYClient
//  Bully
//
//  Created by Sam Soffes on 6/1/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^BLYChannelEventBlock)(id message);

@class BLYChannel;

@interface BLYClient : NSObject

@property (nonatomic, strong, readonly) NSString *socketID;

+ (NSString *)version;

- (id)initWithAppKey:(NSString *)appKey;

- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName;
//- (void)bindToEvent:(NSString *)eventName block:(BLYChannelEventBlock)block;

- (void)connect;
- (void)disconnect;

@end
