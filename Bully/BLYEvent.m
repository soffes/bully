//
//  BLYEvent.m
//  Bully
//
//  Created by Richard Heard on 17/05/2014.
//  Copyright (c) 2014 Richard Heard. All rights reserved.
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

#import "BLYEventPrivate.h"
#import "BLYChannel.h"
#import "BLYClient.h"


@implementation BLYEvent

- (instancetype)_initWithRawEventDictionary:(NSDictionary *)dict andClient:(BLYClient *)client {
    self = [super init];
    
    if (self) {
        _client = client;
        _rawEvent = dict;
        
        //parse out the junk we need
        _name = [dict objectForKey:@"event"];
        _message = [dict objectForKey:@"data"];
        
        if (_message && [_message isKindOfClass:[NSString class]]) {
            NSData *messageData = [_message dataUsingEncoding:NSUTF8StringEncoding];
            NSError *jsonError;
            id decodedMessage = [NSJSONSerialization JSONObjectWithData:messageData options:NSJSONReadingAllowFragments error:&jsonError];
            if (decodedMessage){
                _message = decodedMessage;
            } else {
                _messageDeserializationError = jsonError;
            }
        }
        
        _channelName = [dict objectForKey:@"channel"];
        if (_channelName) _channel = [_client channelWithName:_channelName];

    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, name: '%@', message: '%@', client: %p, channel: %p>", NSStringFromClass([self class]), self, _name, _message ? : _rawEvent, _client, _channel];
}

@end
