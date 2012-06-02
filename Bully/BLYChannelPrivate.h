//
//  BLYChannelPrivate.h
//  Bully
//
//  Created by Sam Soffes on 6/2/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//

#import "BLYChannel.h"

@class BLYClient;

@interface BLYChannel ()

@property (nonatomic, weak) BLYClient *client;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong) NSMutableDictionary *subscriptions;

- (id)initWithName:(NSString *)name;

@end
