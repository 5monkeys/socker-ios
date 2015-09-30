//
//  FMSockerMessage.h
//  FMSocker
//
//  Created by Hannes Ljungberg on 24/09/15.
//  Copyright © 2015 5 Monkeys Agency AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FMSockerMessage : NSObject

+ (instancetype)messageFromString:(NSString *)string error:(NSError **)errorPtr;
- (instancetype)initWithName:(NSString *)name andData:(id)data;
- (NSString *)toStringAndReturnError:(NSError **)errorPtr;

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) id data;

@end
