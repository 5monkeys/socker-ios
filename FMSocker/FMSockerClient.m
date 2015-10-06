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
@property (nonatomic, copy) NSURL *URL;

@end

@implementation FMSockerClient

- (instancetype)initWithURL:(NSURL *)URL
{
    if (self = [super init]) {
        _subscriptions = [NSMutableDictionary dictionary];
        _messageQueue = [NSMutableArray array];
        _URL = URL;
    }
    return self;
}

- (void)connect
{
    [self disconnect];
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:self.URL]];
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

- (void)subscribeOnChannel:(NSString *)channel onMessage:(FMSockerMessageReceivedBlock)onMessageBlock;
{
    self.subscriptions[channel] = onMessageBlock;
    [self sendData:channel onChannel:@"subscribe"];
}

- (void)unsubscribeChannel:(NSString *)channel
{
    [self.subscriptions removeObjectForKey:channel];
    if (![self isConnected]) {
        return;
    }
    [self sendData:channel onChannel:@"unsubscribe"];
}

- (void)unsubscribeAll
{
    for (NSString *channel in self.subscriptions.allKeys) {
        [self unsubscribeChannel:channel];
    }
}

- (void)sendSockerMessage:(FMSockerMessage *)message error:(NSError **)errorPtr
{
    NSString *messageString = [message toStringAndReturnError:errorPtr];
    if (!*errorPtr) {
        if (![self isConnected]) {
            [self.messageQueue addObject:messageString];
        }
        else {
            [self.webSocket send:messageString];
        }
    }
    else {
        NSLog(@"Failed to send message on channel %@ with error %@", message.name, [*errorPtr localizedDescription]);
    }
}

- (void)sendData:(id)data onChannel:(NSString *)channel
{
    FMSockerMessage *message = [[FMSockerMessage alloc] initWithName:channel andData:data];
    NSError *error;
    [self sendSockerMessage:message error:&error];
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
    FMSockerMessageReceivedBlock messageReceivedBlock = self.subscriptions[sockerMessage.name];
    if (messageReceivedBlock) {
        if (!error && sockerMessage) {
            messageReceivedBlock(sockerMessage, nil);
        }
        else {
            messageReceivedBlock(nil, error);
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
