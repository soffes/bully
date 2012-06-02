//
//  BLYChannel
//  Bully
//
//  Created by Sam Soffes on 6/1/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//

#import "BLYChannel.h"
#import "BLYChannelPrivate.h"
#import "BLYClientPrivate.h"

@implementation BLYChannel

@synthesize client;

@synthesize name = _name;
@synthesize subscriptions = _subscriptions;

- (id)initWithName:(NSString *)name {
	if ((self = [super init])) {
		self.name = name;
		self.subscriptions = [[NSMutableDictionary alloc] init];
	}
	return self;
}


- (void)bindToEvent:(NSString *)eventName block:(BLYChannelEventBlock)block {
	[self.subscriptions setObject:block forKey:eventName];
}


- (void)unbindEvent:(NSString *)eventName {
	[self.subscriptions removeObjectForKey:eventName];
}


- (void)unsubscribe {
	[self.client _unsubscribeChannel:self];
}

@end
