//
//  BLYEventPrivate.h
//  Bully
//
//  Created by Skylar Schipper on 4/10/13.
//  Copyright (c) 2013 Sam Soffes. All rights reserved.
//

#import "BLYEvent.h"

@interface BLYEvent ()

- (NSURLRequest *)eventRequestWithAppID:(NSString *)appID key:(NSString *)key secret:(NSString *)secret;

@end
