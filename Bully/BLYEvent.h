//
//  BLYEvent.h
//  Bully
//
//  Created by Skylar Schipper on 4/9/13.
//  Copyright (c) 2013 Sam Soffes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLYEvent : NSObject

#pragma mark -
#pragma mark - Creating An Event

// Name of the event
@property (nonatomic, strong) NSString *name;

// Array of channel names to post the event to
@property (nonatomic, strong) NSArray *channels;

// The data to send in the event
@property (nonatomic, strong) NSDictionary *data;

+ (instancetype)eventForChannels:(NSArray *)channels name:(NSString *)name data:(NSDictionary *)data;

@end
