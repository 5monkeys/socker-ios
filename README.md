Socker iOS client
============
[![Build Status](https://travis-ci.org/5monkeys/socker-ios.svg)](https://travis-ci.org/5monkeys/socker-ios)

An iOS client for communicating with a [socker](https://github.com/5monkeys/socker) websocket server which supports subscribing on multiple channels on a single connection. It is based on the very good [SocketRocket](https://github.com/square/SocketRocket) library.

## Installation
Add the following to your `Podfile` and run `pod install`
```bash
pod 'FMSocker'
```

## Usage

Import the library:

```objective-c
#import <FMSocker/FMSocker.h>
```

Initiate the client with a url to your socker server:
```objective-c
FMSockerClient *sockerClient = [[FMSockerClient alloc] initWithURL:[NSURL URLWithString:@"wss://example.com"]];

// Connect to the server
[sockerClient connect];
```

Subscribe on channels:
```objective-c
// Subscribe on foo channel
[sockerClient subscribeOnChannel:@"foo"
                       onMessage:^(FMSockerMessage *message, NSError *error){
                           if (!error) {
                               NSLog(@"Got message on channel %@ with payload %@", message.name, message.data);
                           } else {
                               NSLog(@"Failed to parse message %@", [error localizedDescription]);
                           }
                       }];
// Subscribe on bar channel
[sockerClient subscribeOnChannel:@"bar"
                       onMessage:^(FMSockerMessage *message, NSError *error){
                           if (!error) {
                               NSLog(@"Got message on channel %@ with payload %@", message.name, message.data);
                           } else {
                               NSLog(@"Failed to parse message %@", [error localizedDescription]);
                           }
                       }];
```

Send messages:
```objective-c
// Create a socker message
FMSockerMessage *message = [[FMSockerMessage alloc] initWithName:@"testchannel" andData:@[ @"foo", @"bar" ]];

// Initiate the client with a url to your socker server
FMSockerClient *sockerClient = [[FMSockerClient alloc] initWithURL:[NSURL URLWithString:@"wss://example.com"]];

// Connect to the server
[sockerClient connect];

// Send the message
NSError *error;
[sockerClient sendSockerMessage:message error:&error];

```

Unsubscribe channels:
```objective-c
// Unsubscribe channel named foo
[sockerClient unsubscribeChannel:@"foo"];
```

Unsubscribe all channels:
```objective-c
[sockerClient unsubscribeAll];
```

Disconnect websocket:
```objective-c
[sockerClient disconnect];
```
