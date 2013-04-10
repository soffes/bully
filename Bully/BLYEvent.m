//
//  BLYEvent.m
//  Bully
//
//  Created by Skylar Schipper on 4/9/13.
//  Copyright (c) 2013 Sam Soffes. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#import "BLYEvent.h"

@implementation BLYEvent

+ (instancetype)eventWithName:(NSString *)name channels:(NSArray *)channels data:(NSDictionary *)data {
    BLYEvent *event = [[[self class] alloc] init];
    event.name = name;
    event.channels = channels;
    event.data = data;
    return event;
}

- (NSURLRequest *)eventRequestWithAppID:(NSString *)appID key:(NSString *)key secret:(NSString *)secret {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self _URLWithAppID:appID]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSData *bodyData = [self _bodyData];
    request.HTTPBody = bodyData;
    [request setValue:[NSString stringWithFormat:@"%d",[bodyData length]] forHTTPHeaderField:@"Content-Length"];
    
    NSNumber *time = @([[NSDate date] timeIntervalSince1970]);
     [self _signRequest:&request body:[[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding] timestamp:time key:key secret:secret];
    
    return request;
}

#pragma mark -
#pragma mark - Private methods
- (NSURL *)_URLWithAppID:(NSString *)appID {
    NSString *urlString = [NSString stringWithFormat:@"http://api.pusherapp.com/apps/%@/events",appID];
    return [NSURL URLWithString:urlString];
}
- (NSData *)_bodyData {
    NSString *eventData = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:self.data options:0 error:nil] encoding:NSUTF8StringEncoding];
    NSDictionary *eventJSON = (@{
                               @"name" : self.name,
                               @"channels" : self.channels,
                               @"data" : eventData
                               });
    return [NSJSONSerialization dataWithJSONObject:eventJSON options:0 error:nil];
}

#pragma mark -
#pragma mark - Authentication
- (void)_signRequest:(NSMutableURLRequest *__autoreleasing *)request body:(NSString *)body timestamp:(NSNumber *)timestamp key:(NSString *)key secret:(NSString *)secret {
    NSString *md5Body = [self _md5String:body];
    NSURL *url = [*request URL];
    NSString *path = [url path];
    NSString *secretString = [NSString stringWithFormat:@"%@\n%@\nauth_key=%@&auth_timestamp=%@&auth_version=1.0&body_md5=%@",[*request HTTPMethod],path,key,timestamp,md5Body];
    NSString *signature = [self _hmac256Key:secret data:secretString];
    NSString *urlString = [url absoluteString];
    urlString = [urlString stringByAppendingFormat:@"?auth_key=%@&auth_timestamp=%@&auth_version=1.0&body_md5=%@&auth_signature=%@",key,timestamp,md5Body,signature];
    [*request setURL:[NSURL URLWithString:urlString]];
}

#pragma mark -
#pragma mark - Hash methods
- (NSString *)_md5String:(NSString *)body {
    const char *ptr = [body UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x",md5Buffer[i]];
    }
    return output;
}
- (NSString *)_hmac256Key:(NSString *)key data:(NSString *)data {
    const char *cKey = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", cHMAC[i]];
    }
    return hash;
}


@end
