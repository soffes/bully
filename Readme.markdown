# Bully

Bully is a simple [Pusher](http://pusher.com) Objective-C client with some neat stuff.

**Note:** This is a work in progress. Presence channels and triggering events aren't supported yet. Proceed with caution.

## Neat Stuff

Bully keeps track of all of your subscribed channels and bound events. If you disconnect (when your app enters the background, loses reachability, or whatever) and then reconnect, Bully will automatically resubscribe to all of your channels and bind your events.

Bully is really simple. It's not even 300 lines of code. Since you can use it without CocoaPods, you can add it as a subproject to allow for easy debugging. You can of course use it with CocoaPods if that's more your style too.


## Example Usage

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
