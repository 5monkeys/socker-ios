//
//  FMSockerMessage.m
//  FMSocker
//
//  Created by Hannes Ljungberg on 24/09/15.
//  Copyright © 2015 5 Monkeys Agency AB. All rights reserved.
//

#import "FMSockerMessage.h"
#import "FMErrors.h"

@interface FMSockerMessage ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) id data;

@end

@implementation FMSockerMessage

- (instancetype)initWithName:(NSString *)name andData:(id)data
{
    if (self = [super init]) {
        _name = name;
        _data = data;
    }
    return self;
}

+ (instancetype)messageFromString:(NSString *)string error:(NSError **)errorPtr
{
    // Check for error prefix
    if ([string hasPrefix:@"#"]) {
        *errorPtr = [NSError errorWithDomain:FMErrorDomain code:FMSockerInvalidDataError userInfo:nil];
        return nil;
    }
    NSRange range = [string rangeOfString:@"|"];

    // Check for socker protocol fullfilment
    if (range.location == NSNotFound) {
        *errorPtr = [NSError errorWithDomain:FMErrorDomain code:FMSockerDataParseError userInfo:nil];
        return nil;
    }
    // Parse payload
    NSString *name = [string substringToIndex:range.location];
    if ([name length] == 0) {
        // Missing channel
        *errorPtr = [NSError errorWithDomain:FMErrorDomain code:FMSockerDataParseError userInfo:nil];
        return nil;
    }
    NSData *jsonData = [[string substringFromIndex:range.location + range.length] dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:errorPtr];
    if (*errorPtr) {
        return nil;
    }
    return [[FMSockerMessage alloc] initWithName:name andData:jsonObject];
}

- (NSString *)toStringAndReturnError:(NSError **)errorPtr
{
    NSString *payload;
    if ([self.data isKindOfClass:[NSArray class]] || [self.data isKindOfClass:[NSDictionary class]]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.data options:kNilOptions error:errorPtr];
        if (*errorPtr) {
            return nil;
        }
        payload = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    else if ([self.data isKindOfClass:[NSString class]]) {
        payload = [NSString stringWithFormat:@"\"%@\"", self.data];
    }
    else {
        @throw [NSException exceptionWithName:@"Invalid socker payload"
                                       reason:@"Payload is not JSON-serializable or NSString"
                                     userInfo:nil];
    }

    return [NSString stringWithFormat:@"%@|%@", self.name, payload];
}

@end
