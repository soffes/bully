//
//  BLYClientPrivate.h
//  Bully
//
//  Created by Sam Soffes on 6/2/12.
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
#import <SocketRocket/SRWebSocket.h>
#import "BLYClient.h"

@class BLYChannel;

@interface BLYClient () <SRWebSocketDelegate>

@property (nonatomic, strong, readwrite) NSString *socketID;
@property (nonatomic, weak, readwrite) id<BLYClientDelegate> delegate;
@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, strong) NSMutableDictionary *connectedChannels;


- (void)_sendEvent:(NSString *)eventName dictionary:(NSDictionary *)dictionary;
- (void)_reconnectChannels;
- (void)_removeChannel:(BLYChannel *)channel;
- (void)_reachabilityChanged:(NSNotification *)notification;
- (void)_handleDisconnectAllowAutomaticReconnect:(BOOL)allowReconnect error:(NSError *)error;
- (void)_reconnectAfterDelay;

// ping-pong
extern const NSTimeInterval BLYWebsocketPingTimeInterval;

- (void)_pingStartTimer;
- (void)_pingStopTimer;
- (void)_pingNoteWebsocketMessageReceived;
- (void)_sendPing;
- (void)_sendPong;
- (void)_pingTimerFired:(NSTimer *)timer;

#if TARGET_OS_IPHONE
- (void)_appDidEnterBackground:(NSNotification *)notificaiton;
- (void)_appDidBecomeActive:(NSNotification *)notification;
#endif

@end
