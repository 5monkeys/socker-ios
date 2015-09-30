//
//  FMSockerMessageTests.m
//  FMSockerMessageTests
//
//  Created by Hannes Ljungberg on 29/09/15.
//  Copyright © 2015 5 Monkeys Agency AB. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FMSockerMessage.h"
#import "FMErrors.h"

@interface FMSockerMessageTests : XCTestCase

@end

@implementation FMSockerMessageTests

- (void)testValidJSONObjectMessageString
{
    NSString *validString = [NSString stringWithFormat:@"test|{\"foo\": \"bar\"}"];
    NSError *error;
    FMSockerMessage *message = [FMSockerMessage messageFromString:validString error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(message.name);
    XCTAssertNotNil(message.data);
    XCTAssertEqualObjects(message.name, @"test");
    XCTAssertEqualObjects(message.data, @{ @"foo" : @"bar" });
}

- (void)testValidJSONListMessageString
{
    NSString *validString = [NSString stringWithFormat:@"test|[\"foo\",\"bar\"]"];
    NSError *error;
    FMSockerMessage *message = [FMSockerMessage messageFromString:validString error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(message.name);
    XCTAssertNotNil(message.data);
    XCTAssertEqualObjects(message.name, @"test");
    NSArray *data = @[ @"foo", @"bar" ];
    XCTAssertEqualObjects(message.data, data);
}

- (void)testValidStringMessageString
{
    NSString *validString = [NSString stringWithFormat:@"test|\"foo|asd\""];
    NSError *error;
    FMSockerMessage *message = [FMSockerMessage messageFromString:validString error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(message.name);
    XCTAssertNotNil(message.data);
    XCTAssertEqualObjects(message.name, @"test");
    XCTAssertEqualObjects(message.data, @"foo|asd");
}

- (void)testInvalidMessageString
{
    NSString *missingDelimiterString = [NSString stringWithFormat:@"test"];
    NSError *error;
    FMSockerMessage *message = [FMSockerMessage messageFromString:missingDelimiterString error:&error];
    XCTAssertNil(message);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, FMErrorDomain);
    XCTAssertEqual(error.code, FMSockerDataParseError);
}

- (void)testMissingChannelNameString
{
    NSString *missingDelimiterString = [NSString stringWithFormat:@"|{\"foo\": \"bar\"}"];
    NSError *error;
    FMSockerMessage *message = [FMSockerMessage messageFromString:missingDelimiterString error:&error];
    XCTAssertNil(message);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, FMErrorDomain);
    XCTAssertEqual(error.code, FMSockerDataParseError);
}

- (void)testErrorPrefixString
{
    NSString *missingDelimiterString = [NSString stringWithFormat:@"#test|{\"foo\": \"bar\"}"];
    NSError *error;
    FMSockerMessage *message = [FMSockerMessage messageFromString:missingDelimiterString error:&error];
    XCTAssertNil(message);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, FMErrorDomain);
    XCTAssertEqual(error.code, FMSockerInvalidDataError);
}

- (void)testValidDictionaryPayloadToString
{
    FMSockerMessage *message = [[FMSockerMessage alloc] initWithName:@"test" andData:@{ @"foo" : @"bar" }];
    NSError *error;
    NSString *messageString = [message toStringAndReturnError:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(messageString);
    XCTAssertEqualObjects(messageString, @"test|{\"foo\":\"bar\"}");
}

- (void)testValidArrayPayloadToString
{
    FMSockerMessage *message = [[FMSockerMessage alloc] initWithName:@"test" andData:@[ @"foo", @"bar" ]];
    NSError *error;
    NSString *messageString = [message toStringAndReturnError:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(messageString);
    XCTAssertEqualObjects(messageString, @"test|[\"foo\",\"bar\"]");
}

- (void)testValidStringPayloadToString
{
    FMSockerMessage *message = [[FMSockerMessage alloc] initWithName:@"test" andData:@"foo"];
    NSError *error;
    NSString *messageString = [message toStringAndReturnError:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(messageString);
    XCTAssertEqualObjects(messageString, @"test|\"foo\"");
}

- (void)testInvalidPayloadToString
{
    FMSockerMessage *message = [[FMSockerMessage alloc] initWithName:@"test" andData:nil];
    NSError *error;
    XCTAssertThrowsSpecific([message toStringAndReturnError:&error], NSException);

}


@end
