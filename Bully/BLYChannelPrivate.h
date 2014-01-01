//
//  BLYChannelPrivate.h
//  Bully
//
//  Created by Sam Soffes on 6/2/12.
//  Copyright (c) 2012-2014 Sam Soffes. All rights reserved.
//

#import "BLYChannel.h"

@class BLYClient;

@interface BLYChannel ()

@property (nonatomic, weak, readwrite) BLYClient *client;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong) NSMutableDictionary *subscriptions;

- (id)_initWithName:(NSString *)name client:(BLYClient *)client authenticationBlock:(BLYChannelAuthenticationBlock)authenticationBlock;
- (void)_subscribe;

@end
