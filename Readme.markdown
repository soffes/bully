# Bully

Simple Pusher Objective-C client.

**Note:** This is a work in progress. Presence channels aren't supported yet. Proceed with caution.

## Example Usage

``` objective-c
// Create the client
BLYClient *client = [[BLYClient alloc] initWithAppKey:@"YOUR_PUSHER_KEY" delegate:self];

// Subscribe to a channel
BLYChannel *chatChannel = [client subscribeToChannelWithName:@"chat"];

// Bind to an event
[chatChannel bindToEvent:@"new-message" block:^(id message) {
  // `message` is a dictionary of the Pusher message
  NSLog(@"New message: %@", [message objectForKey:@"text"]);
}];

// Subscribe to a private channel
BLYChannel *userChannel = [client subscribeToChannelWithName:@"private-user-42" authenticationBlock:^(BLYChannel *channel) {
  // Hit your server to authenticate
  // When you have the response, tell the channel so it can connect:
  [channel subscribeWithAuthentication:responseObject];
}];
```
