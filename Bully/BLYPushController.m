//
//  BLYPushController.m
//  Bully
//
//  Created by Sam Soffes on 9/13/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//

#import "BLYPushController.h"
#import "Reachability.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIApplication.h> // For background notificaitons
#endif

@interface BLYPushController ()
@property (nonatomic, strong, readwrite) BLYClient *client;
- (void)_reachabilityChanged:(NSNotification *)notification;

#if TARGET_OS_IPHONE
- (void)_appDidEnterBackground:(NSNotification *)notificaiton;
- (void)_appDidBecomeActive:(NSNotification *)notification;
#endif
@end

@implementation BLYPushController {
	Reachability *_reachability;
	BOOL _appIsBackgrounded;
}

@synthesize client = _client;

#pragma mark - NSObject

- (id)initWithAppKey:(NSString *)appKey {
	if ((self = [super init])) {
		_client = [[BLYClient alloc] initWithAppKey:appKey delegate:self];
		_appIsBackgrounded = NO;

#if TARGET_OS_IPHONE
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(_appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
		[notificationCenter addObserver:self selector:@selector(_appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
#endif

		_reachability = [Reachability reachabilityWithHostname:@"ws.pusherapp.com"];
		[_reachability startNotifier];
		[notificationCenter addObserver:self selector:@selector(_reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
	}
	return self;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.client disconnect];
}


#pragma mark - Private

#if TARGET_OS_IPHONE
- (void)_appDidEnterBackground:(NSNotification *)notificaiton {
	_appIsBackgrounded = YES;
	[self.client disconnect];
}


- (void)_appDidBecomeActive:(NSNotification *)notification {
	_appIsBackgrounded = NO;
	[self.client connect];
}
#endif


- (void)_reachabilityChanged:(NSNotification *)notification {
	// If the app is in the background, ignore the notificaiton
	if (_appIsBackgrounded) {
		return;
	}

	if ([_reachability isReachable]) {
		// If Pusher became reachable, reconnect
		[self.client connect];
	} else {
		// Disconnect if we lost the connection to Pusher
		[self.client disconnect];
	}
}


#pragma mark - BLYClientDelegate

- (void)bullyClientDidDisconnect:(BLYClient *)client {
	// If it disconnected but Pusher is reachable and it's not in the background, reconnect
	if (!_appIsBackgrounded && [_reachability isReachable]) {
		[client connect];
	}
}

@end
