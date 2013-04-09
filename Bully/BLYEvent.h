//
//  BLYEvent.h
//  Bully
//
//  Created by Skylar Schipper on 4/9/13.
//  Copyright (c) 2013 Sam Soffes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLYEvent : NSObject

/** Set authentication details

 */
+ (void)setAppID:(NSNumber *)appID key:(NSString *)key secret:(NSString *)secret;

#pragma mark -
#pragma mark - Creating An Event

// Name of the event
@property (nonatomic, strong) NSString *name;

// Array of channel names to post the event to
@property (nonatomic, strong) NSArray *channels;

// The data to send in the event
@property (nonatomic, strong) NSDictionary *data;

+ (instancetype)eventWithName:(NSString *)name channels:(NSArray *)channels data:(NSDictionary *)data;

// Trigger an event and send it to Pusher
- (void)trigger;

// Trigger an event and send it to Pusher with a completion block
- (void)triggerWithCompletion:(void(^)(BLYEvent *event, NSUInteger statusCode, NSDictionary *response))completion;

@end
