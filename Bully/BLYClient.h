//
//  BLYClient
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

#import <Foundation/Foundation.h>
#import "BLYChannel.h"
#import "BLYEvent.h"

@protocol BLYClientDelegate;

@interface BLYClient : NSObject

// error domain for client errors
extern NSString *const BLYClientErrorDomain;

// event notification
extern NSString * const BLYClientReceivedEventNotification;
extern NSString * const kBLYEventUserInfoKey;

@property (nonatomic, strong, readonly) NSString *socketID;
@property (nonatomic, weak, readonly) id<BLYClientDelegate> delegate;
@property (nonatomic, assign) BOOL automaticallyReconnect; // Default is YES

@property (nonatomic, strong, readonly) NSString *hostName;

#if TARGET_OS_IPHONE
@property (nonatomic, assign) BOOL automaticallyDisconnectInBackground; // Default is YES
#endif

// Bully Version
+ (NSString *)version;

// Initializer
- (id)initWithAppKey:(NSString *)appKey delegate:(id<BLYClientDelegate>)delegate;
- (id)initWithAppKey:(NSString *)appKey delegate:(id<BLYClientDelegate>)delegate hostName:(NSString *)hostName;

// Subscribing
- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName;
- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName authenticationBlock:(BLYChannelAuthenticationBlock)authenticationBlock;
- (BLYChannel *)subscribeToChannelWithName:(NSString *)channelName authenticationBlock:(BLYChannelAuthenticationBlock)authenticationBlock errorBlock:(BLYErrorBlock)errorBlock;

// Accessing
- (BLYChannel *)channelWithName:(NSString *)channelName; //channel, or nil if not existant

// Unsubscribe all
- (void)unsubscribeAll;

// Managing the Connection
- (void)connect;
- (void)disconnect;
- (BOOL)isConnected;

@end


@protocol BLYClientDelegate <NSObject>

@optional

- (void)bullyClientDidConnect:(BLYClient *)client;
- (void)bullyClient:(BLYClient *)client didReceiveEvent:(BLYEvent *)event;
- (void)bullyClient:(BLYClient *)client didReceiveError:(NSError *)error;
- (void)bullyClient:(BLYClient *)client didDisconnectWithError:(NSError *)error;

@end