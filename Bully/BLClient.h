//
//  BLClient.h
//  Bully
//
//  Created by Sam Soffes on 6/1/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^BLClientEventBlock)(NSString *eventName, id message);

@class BLChannel;

@interface BLClient : NSObject

@property (nonatomic, strong, readonly) NSString *socketID;
@property (nonatomic, copy) BLClientEventBlock eventBlock;

+ (NSString *)version;

- (id)initWithAppKey:(NSString *)appKey;

- (BLChannel *)subscribe:(NSString *)channelName;

@end
