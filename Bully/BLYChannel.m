//
//  BLYChannel
//  Bully
//
//  Created by Sam Soffes on 6/1/12.
//  Copyright (c) 2012-2014 Sam Soffes. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:

//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "BLYChannel.h"
#import "BLYChannelPrivate.h"
#import "BLYClientPrivate.h"
#import "BLYEvent.h"

NSString * const BLYChannelReceivedEventNotification = @"BLYChannelReceivedEventNotification";

@implementation BLYChannel

@synthesize client = _client;
@synthesize name = _name;
@synthesize subscriptions = _subscriptions;
@synthesize authenticationBlock = _authenticationBlock;
@synthesize errorBlock = _errorBlock;

- (void)bindToEvent:(NSString *)eventName block:(BLYChannelEventBlock)block {
	[self.subscriptions setObject:block forKey:eventName];
}


- (void)unbindEvent:(NSString *)eventName {
	[self.subscriptions removeObjectForKey:eventName];
}


- (void)unsubscribe {
	NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
								self.name, @"channel",
								nil];
	[self.client _sendEvent:@"pusher:unsubscribe" dictionary:dictionary];
	[self.client _removeChannel:self];
}


- (BOOL)isPrivate {
	return [self.name hasPrefix:@"private-"];
}


- (BOOL)isPresence {
    return [self.name hasPrefix:@"presence-"];
}


- (NSDictionary *)authenticationParameters {
	return [[NSDictionary alloc] initWithObjectsAndKeys:
			self.name, @"channel_name",
			self.client.socketID, @"socket_id",
			nil];
}


- (NSData *)authenticationParametersData {
	return [NSJSONSerialization dataWithJSONObject:self.authenticationParameters options:0 error:nil];
}


- (void)subscribeWithAuthentication:(NSDictionary *)authentication {
	NSMutableDictionary *dictionary = nil;
	if (authentication) {
		dictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
					  self.name, @"channel",
					  [authentication objectForKey:@"auth"], @"auth",
					  nil];
        id channelData = [authentication objectForKey:@"channel_data"];
        if ([self isPresence] && channelData) {
            [dictionary setObject:channelData forKey:@"channel_data"];
        }
        
	} else {
		dictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
					  self.name, @"channel",
					  nil];
	}
	[self.client _sendEvent:@"pusher:subscribe" dictionary:dictionary];
}


#pragma mark - Private

- (id)_initWithName:(NSString *)name client:(BLYClient *)client  authenticationBlock:(BLYChannelAuthenticationBlock)authenticationBlock {
	if ((self = [super init])) {
		self.name = name;
		self.client = client;
		self.authenticationBlock = authenticationBlock;
		self.subscriptions = [[NSMutableDictionary alloc] init];
	}
	return self;
}


- (void)_subscribe {
    if ([self isPrivate] || [self isPresence]) {
		if (!self.client.socketID) {
			return;
		}

		if (self.authenticationBlock) {
			self.authenticationBlock(self);
		}
		return;
	}

	[self subscribeWithAuthentication:nil];
}

- (void)_dispatchEvent:(BLYEvent*)event {

    if (event.messageDeserializationError && self.errorBlock) {
        self.errorBlock(event.messageDeserializationError, BLYErrorTypeJSONParser);
    }

    // See if they are bound to this event
    BLYChannelEventBlock block = [self.subscriptions objectForKey:event.name];
    if (block) block(event);
    

    //also dispatch an event notification
    [[NSNotificationCenter defaultCenter] postNotificationName:BLYChannelReceivedEventNotification object:event.channel userInfo:[NSDictionary dictionaryWithObject:event forKey:kBLYEventUserInfoKey]];

}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, name: '%@'>", NSStringFromClass([self class]), self, _name];
}

@end
