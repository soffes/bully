//
//  BLYPushController.h
//  Bully
//
//  Created by Sam Soffes on 9/13/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//
//
// This class is an abstract class intended to make working with Pusher easier. It automatically disconnects and
// reconnects at the appropriate times so you don't have to worry about it.
//
// You will most likely want to do three things in your subclass:
//
//   1. Provide a class method that returns a shared instance.
//
//   2. Provide various properties for your objects and the corresponding Pusher channel. For example, have a `user`
//      property and a `userChannel` property. When you set `user` unsubscribe from the previous `userChannel` and then
//      subscribe to whatever you need to subscribe to.
//
//   3. Override `bullyClientDidConnect:` and store `client.socketID`. You will most likely want to send this in every
//      request as described here: http://pusher.com/docs/server_api_guide/server_excluding_recipients
//

#import <Foundation/Foundation.h>
#import "BLYClient.h"

@class BLYChannel;

@interface BLYPushController : NSObject <BLYClientDelegate>

@property (nonatomic, strong, readonly) BLYClient *client;

- (id)initWithAppKey:(NSString *)appKey;

@end
