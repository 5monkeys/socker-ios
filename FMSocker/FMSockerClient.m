//
//  FMWebSocketClient.m
//  FMSocker
//
//  Created by Hannes Ljungberg on 24/09/15.
//  Copyright © 2015 5 Monkeys Agency AB. All rights reserved.
//

#import "FMSockerClient.h"

#import "FMSockerMessage.h"

#import "SRWebSocket.h"

@interface FMSockerClient () <SRWebSocketDelegate>

@property (nonatomic, strong) SRWebSocket *webSocket;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, strong) NSMutableDictionary *subscriptions;
@property (nonatomic, strong) NSMutableArray *messageQueue;
@property (nonatomic, strong) NSString *webSocketURL;

@end

@implementation FMSockerClient

+ (instancetype)sharedClient
{
    static FMSockerClient *sharedClient;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      sharedClient = [[self alloc] init];
    });

    return sharedClient;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.subscriptions = [NSMutableDictionary dictionary];
        self.messageQueue = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    [self disconnect];
}

- (void)connect
{
    [self disconnect];
    self.webSocket = [[SRWebSocket alloc]
        initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@""]]];
    self.webSocket.delegate = self;
    [self.webSocket open];
}

- (void)disconnect
{
    self.webSocket.delegate = nil;
    [self.webSocket close];
    self.webSocket = nil;
}

- (BOOL)isConnected
{
    return self.webSocket.readyState == SR_OPEN;
}

- (BOOL)isClosed
{
    return self.webSocket.readyState == SR_CLOSED;
}

- (void)subscribe:(NSString *)channel completion:(FMSockerMessageCompletionBlock)completion
{
    self.subscriptions[channel] = completion;
    [self sendMessage:@"subscribe" data:channel];
}

- (void)unsubscribe:(NSString *)channel
{
    [self.subscriptions removeObjectForKey:channel];
    if (![self isConnected]) {
        return;
    }
    [self sendMessage:@"unsubscribe" data:channel];
}

- (void)unsubscribeAll
{
    for (NSString *channel in self.subscriptions) {
        [self unsubscribe:channel];
    }
}

- (void)sendMessage:(NSString *)channel data:(id)data
{
    FMSockerMessage *message = [[FMSockerMessage alloc] initWithName:channel andData:data];
    NSError *error;
    NSString *messageString = [message toString:&error];
    if (!error) {
        if (![self isConnected]) {
            [self.messageQueue addObject:messageString];
        }
        else {
            [self.webSocket send:messageString];
        }
    }
    else {
        NSLog(@"Failed to send message on channel %@ with error %@", channel, [error localizedDescription]);
    }
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"Websocket Connected");
    for (NSString *messageData in self.messageQueue) {
        [self.webSocket send:messageData];
    }
    [self.messageQueue removeAllObjects];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"Websocket Failed With Error %@", error);
    self.webSocket = nil;
    [self.subscriptions removeAllObjects];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"Received: %@", message);
    if (![message isKindOfClass:[NSString class]]) {
        NSLog(@"Got invalid message, must be string");
        return;
    }
    NSError *error;
    FMSockerMessage *sockerMessage = [FMSockerMessage messageFromString:(NSString *)message error:&error];
    FMSockerMessageCompletionBlock subscriptionCompletion = self.subscriptions[sockerMessage.name];
    if (subscriptionCompletion) {
        if (!error && sockerMessage) {
            subscriptionCompletion(sockerMessage, nil);
        }
        else {
            subscriptionCompletion(nil, error);
        }
    }
    else {
        NSLog(@"Got message on channel %@ without matching subscription", sockerMessage.name);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"Websocket closed with code %ld reason: %@", (long)code, reason);
    // TODO: Handle reconnecting
    self.webSocket = nil;
    [self.subscriptions removeAllObjects];
}

@end
