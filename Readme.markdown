# Bully

Bully is a simple [Pusher](http://pusher.com) Objective-C client with some neat stuff.

## Neat Stuff

**This is a work in progress.** Presence channels and triggering events aren't supported yet. Proceed with caution. If you're looking for a full featured Objective-C client, checkout [libPusher](https://github.com/lukeredpath/libPusher) by [Luke Redpath](https://github.com/lukeredpath).

Bully keeps track of all of your subscribed channels and bound events. If you disconnect (when your app enters the background, loses reachability, or whatever) and then reconnect, Bully will automatically resubscribe to all of your channels and bind your events. Currently monitoring reachability is up to you. I'm considering moving this into Bully. If you call `[client connect]` it will automatically connect to any channels previously connected.

Bully is really simple. Since you can use it without CocoaPods, you can add it as a subproject to allow for easy debugging. You can of course use it with CocoaPods if that's more your style too.

Bully tries to mirror the [Pusher JavaScript library](http://pusher.com/docs/client_api_guide)'s API as much as possible. Things are a bit more verbose to match the Objective-C style, but it's still pretty short.

## Example Usage

#### Import the headers

``` objective-c
#import <Bully/Bully.h>
```

Simple as that.

#### Creating a client

``` objective-c
BLYClient *client = [[BLYClient alloc] initWithAppKey:@"YOUR_PUSHER_KEY" delegate:self];
```

It is recommended that you set your client to an instance variable so it stays around and keeps its connection to Pusher open.

#### Subscribe to a channel

``` objective-c
BLYChannel *chatChannel = [client subscribeToChannelWithName:@"chat"];
```

#### Bind to an event

``` objective-c
[chatChannel bindToEvent:@"new-message" block:^(id message) {
  // `message` is a dictionary of the Pusher message
  NSLog(@"New message: %@", [message objectForKey:@"text"]);
}];
```

#### Subscribe to a private channel

Supply a `authenticationBlock` when connecting to a private channel. This will get called whenever the channel connects so it can authenticate. If the client reconnects after losing reachability, it will call the `authenticationBlock` again.

``` objective-c
BLYChannel *userChannel = [client subscribeToChannelWithName:@"private-user-42" authenticationBlock:^(BLYChannel *channel) {
  // Hit your server to authenticate with `channel.authenticationParameters` or `channel.authenticationParametersData`
  // When you have the response, tell the channel so it can connect:
  [channel subscribeWithAuthentication:responseObject];
}];
```

Here's an example using [AFNetworking](https://github.com/afnetworking/afnetworking), but you can use whatever you want.

``` objective-c
BLYChannel *userChannel = [client subscribeToChannelWithName:@"private-user-42" authenticationBlock:^(BLYChannel *channel) {
  [[MyHTTPClient sharedClient] postPath:@"/pusher/auth" parameters:channel.authenticationParameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
    [channel subscribeWithAuthentication:responseObject];
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Failed to authorize Pusher channel: %@", error);
  }];
}];
```

## Adding to Your Project

This is a bit tedious since Apple doesn't allow for iOS frameworks (without hacks) or other easier ways of add dependencies to a project. You can use [CocoaPods](http://cocoapods.org) instead if you prefer (see below).

1. Add Bully as a [git submodule](http://schacon.github.com/git/user-manual.html#submodules). Here's how to add it as a submodule:

    $ cd rootOfYourGitRepo
    $ git submodule add https://github.com/samsoffes/bully.git Vendor/Bully
    $ git submodule update --init --recursive 

2. Add `Vendor/Bully/Bully.xcodeproj` to your Xcode project.

3. Select your main Xcode project from the top of the sidebar in Xcode and then select the target you want to add Bully to.

4. Select the *Build Phases* tab.

5. Under the *Target Dependencies* group, click the plus button, select *Bully* from the menu, and choose *Add*.

6. Under the *Link Binary With Libraries* group, click the plus button, select `libBully.a` from the menu, and choose *Add*. Be sure you have `CFNetwork.framework` added to your project as well. If you don't go ahead and add it too.

7. Choose the *Build Settings* tab. Make sure *All* in the top left of the bar under the tabs.

8. Add `Vendor/Bully` to *Header Search Path*. Don't click the *Recursive* checkbox and make sure you added it to *Header Search Path* and **not** *User Header Search Path*

9. Add `-all_load -ObjC` to *Other Linker Flags*.

That's it. The annoying part is over. Now to the fun part.

### CocoaPods

If you are using [CocoaPods](http://cocoapods.org) then just add next line to your Podfile:

``` ruby
dependency 'Bully'
```

Now run `pod install` to install the dependency.

## License & Thanks

Bully is released under the [MIT license](https://github.com/samsoffes/bully/blob/master/LICENSE), so do whatever you want to it.

Bully uses [SocketRocket](https://github.com/square/SocketRocket) by [Square](https://github.com/square), which is fantastic. Thanks to [Pusher](http://pusher.com) for being awesome. 
