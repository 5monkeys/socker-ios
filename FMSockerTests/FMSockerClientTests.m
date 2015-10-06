//
//  FMSockerClientTests.m
//  FMSocker
//
//  Created by Hannes Ljungberg on 30/09/15.
//  Copyright © 2015 5 Monkeys Agency AB. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>
#import "SRWebSocket.h"

#import "FMSockerClient.h"
#import "FMSockerMessage.h"

@interface FMSockerClientTests : XCTestCase

@end

@implementation FMSockerClientTests

- (void)testSubscribe
{
    FMSockerClient *sockerClient = [[FMSockerClient alloc] initWithURL:[NSURL URLWithString:@"wss://example.com"]];
    [sockerClient subscribeOnChannel:@"test"
                           onMessage:^(FMSockerMessage *message, NSError *error){
                           }];
    XCTAssertNotNil(sockerClient.subscriptions[@"test"]);
}

- (void)testDidReciveMessage
{
    FMSockerClient<SRWebSocketDelegate> *sockerClient = (FMSockerClient<SRWebSocketDelegate> *)[[FMSockerClient alloc]
        initWithURL:[NSURL URLWithString:@"wss://example.com"]];
    __block BOOL block1Ran = NO;
    __block BOOL block2Ran = NO;
    [sockerClient subscribeOnChannel:@"test"
                           onMessage:^(FMSockerMessage *message, NSError *error) {
                             XCTAssertNil(error);
                             XCTAssertNotNil(message);
                             block1Ran = YES;
                           }];
    [sockerClient subscribeOnChannel:@"test2"
                           onMessage:^(FMSockerMessage *message, NSError *error) {
                             block2Ran = YES;
                           }];

    NSString *messageString = @"test|{\"foo\": \"bar\"}";
    [sockerClient webSocket:nil didReceiveMessage:messageString];
    XCTAssertTrue(block1Ran);
    XCTAssertFalse(block2Ran);

    block1Ran = NO;
    block2Ran = NO;
    NSString *messageString2 = @"test2|{\"foo\": \"bar\"}";
    [sockerClient webSocket:nil didReceiveMessage:messageString2];
    XCTAssertFalse(block1Ran);
    XCTAssertTrue(block2Ran);

    block1Ran = NO;
    block2Ran = NO;
    NSString *messageString3 = @"tes3|{\"foo\": \"bar\"}";
    [sockerClient webSocket:nil didReceiveMessage:messageString3];
    XCTAssertFalse(block1Ran);
    XCTAssertFalse(block2Ran);
}

- (void)testUnsubscribe
{
    FMSockerClient<SRWebSocketDelegate> *sockerClient = (FMSockerClient<SRWebSocketDelegate> *)[[FMSockerClient alloc]
        initWithURL:[NSURL URLWithString:@"wss://example.com"]];
    __block BOOL block1Ran = NO;
    __block BOOL block2Ran = NO;
    [sockerClient subscribeOnChannel:@"test"
                           onMessage:^(FMSockerMessage *message, NSError *error) {
                             block1Ran = YES;
                           }];
    [sockerClient subscribeOnChannel:@"test2"
                           onMessage:^(FMSockerMessage *message, NSError *error) {
                             block2Ran = YES;
                           }];

    NSString *messageString = @"test|{\"foo\": \"bar\"}";
    [sockerClient unsubscribeChannel:@"test"];
    [sockerClient webSocket:nil didReceiveMessage:messageString];

    NSString *messageString2 = @"test2|{\"foo\": \"bar\"}";
    [sockerClient webSocket:nil didReceiveMessage:messageString2];
    XCTAssertTrue(block2Ran);
}

- (void)testUnsubscribeAll
{
    FMSockerClient<SRWebSocketDelegate> *sockerClient = (FMSockerClient<SRWebSocketDelegate> *)[[FMSockerClient alloc]
        initWithURL:[NSURL URLWithString:@"wss://example.com"]];
    __block BOOL block1Ran = NO;
    __block BOOL block2Ran = NO;
    [sockerClient subscribeOnChannel:@"test"
                           onMessage:^(FMSockerMessage *message, NSError *error) {
                             XCTAssertNil(error);
                             XCTAssertNotNil(message);
                             block1Ran = YES;
                           }];
    [sockerClient subscribeOnChannel:@"test2"
                           onMessage:^(FMSockerMessage *message, NSError *error) {
                             block2Ran = YES;
                           }];

    [sockerClient unsubscribeAll];
    NSString *messageString = @"test|{\"foo\": \"bar\"}";
    [sockerClient webSocket:nil didReceiveMessage:messageString];
    XCTAssertFalse(block1Ran);

    NSString *messageString2 = @"test2|{\"foo\": \"bar\"}";
    [sockerClient webSocket:nil didReceiveMessage:messageString2];
    XCTAssertFalse(block2Ran);
}

- (void)testDidFailWithError
{
    FMSockerClient<SRWebSocketDelegate> *sockerClient = (FMSockerClient<SRWebSocketDelegate> *)[[FMSockerClient alloc]
        initWithURL:[NSURL URLWithString:@"wss://example.com"]];
    NSError *error = [NSError errorWithDomain:@"testerror" code:1 userInfo:nil];
    [sockerClient webSocket:nil didFailWithError:error];
}

- (void)testDidCloseWithCode
{
    FMSockerClient<SRWebSocketDelegate> *sockerClient = (FMSockerClient<SRWebSocketDelegate> *)[[FMSockerClient alloc]
        initWithURL:[NSURL URLWithString:@"wss://example.com"]];
    [sockerClient webSocket:nil didCloseWithCode:1 reason:@"test" wasClean:YES];
}

- (void)testConnectionQueueNotConnected
{
    FMSockerClient<SRWebSocketDelegate> *sockerClient = (FMSockerClient<SRWebSocketDelegate> *)[[FMSockerClient alloc]
        initWithURL:[NSURL URLWithString:@"wss://example.com"]];

    id socketMock = [OCMockObject mockForClass:[SRWebSocket class]];
    [sockerClient setValue:socketMock forKey:@"webSocket"];
    OCMStub([socketMock send:[OCMArg any]]);

    // Test sending message not connected
    OCMStub([socketMock readyState]).andReturn(SR_CLOSED);
    FMSockerMessage *message2 = [[FMSockerMessage alloc] initWithName:@"test" andData:@{ @"foo" : @"bar" }];
    [sockerClient sendSockerMessage:message2];
    XCTAssertEqual([[sockerClient valueForKey:@"messageQueue"] count], 1);

    [sockerClient webSocketDidOpen:socketMock];
    XCTAssertEqual([[sockerClient valueForKey:@"messageQueue"] count], 0);

    NSError *error;
    OCMVerify([socketMock send:[message2 toStringAndReturnError:&error]]);
}

- (void)testConnectionQueueConnected
{
    FMSockerClient<SRWebSocketDelegate> *sockerClient = (FMSockerClient<SRWebSocketDelegate> *)[[FMSockerClient alloc]
        initWithURL:[NSURL URLWithString:@"wss://example.com"]];

    id socketMock = [OCMockObject mockForClass:[SRWebSocket class]];
    [sockerClient setValue:socketMock forKey:@"webSocket"];
    OCMStub([socketMock send:[OCMArg any]]);

    // Test sending message connected
    OCMStub([socketMock readyState]).andReturn(SR_OPEN);
    FMSockerMessage *message1 = [[FMSockerMessage alloc] initWithName:@"test" andData:@{ @"foo" : @"bar" }];
    [sockerClient sendSockerMessage:message1];
    XCTAssertEqual([[sockerClient valueForKey:@"messageQueue"] count], 0);
}

- (void)testConnect
{
    FMSockerClient<SRWebSocketDelegate> *sockerClient = (FMSockerClient<SRWebSocketDelegate> *)[[FMSockerClient alloc]
        initWithURL:[NSURL URLWithString:@"wss://example.com"]];

    [sockerClient connect];
}

- (void)testDisconnect
{
    FMSockerClient<SRWebSocketDelegate> *sockerClient = (FMSockerClient<SRWebSocketDelegate> *)[[FMSockerClient alloc]
        initWithURL:[NSURL URLWithString:@"wss://example.com"]];

    [sockerClient disconnect];
}

@end
