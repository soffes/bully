//
//  BLYChannel
//  Bully
//
//  Created by Sam Soffes on 6/1/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLYClient.h"

@interface BLYChannel : NSObject

@property (nonatomic, strong, readonly) NSString *name;

- (void)bindToEvent:(NSString *)eventName block:(BLYChannelEventBlock)block;
- (void)unbindEvent:(NSString *)eventName;

- (void)unsubscribe;

@end
