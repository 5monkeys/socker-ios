//
//  FMWebSocketClient.h
//  FMSocker
//
//  Created by Hannes Ljungberg on 24/09/15.
//  Copyright © 2015 5 Monkeys Agency AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMSockerMessage;

typedef void (^FMSockerMessageCompletionBlock)(FMSockerMessage *message, NSError *error);

@interface FMSockerClient : NSObject

+ (instancetype)sharedClient;

- (void)subscribe:(NSString *)channel completion:(FMSockerMessageCompletionBlock)completion;
- (void)unsubscribe:(NSString *)channel;
- (void)unsubscribeAll;
- (void)disconnect;
- (void)connect;

@end
