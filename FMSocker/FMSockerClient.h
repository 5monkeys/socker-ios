//
//  FMWebSocketClient.h
//  FMSocker
//
//  Created by Hannes Ljungberg on 24/09/15.
//  Copyright © 2015 5 Monkeys Agency AB. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SRWebSocket.h"

@class FMSockerMessage;

typedef void (^FMSockerMessageReceivedBlock)(FMSockerMessage *message, NSError *error);

@interface FMSockerClient : NSObject <SRWebSocketDelegate>

- (instancetype)initWithURL:(NSURL *)URL;

- (void)subscribeOnChannel:(NSString *)channel onMessage:(FMSockerMessageReceivedBlock)onMessageBlock;
- (void)unsubscribeChannel:(NSString *)channel;
- (void)unsubscribeAll;
- (void)disconnect;
- (void)connect;
- (BOOL)sendSockerMessage:(FMSockerMessage *)message error:(NSError **)errorPtr;

@property (nonatomic, strong, readonly) NSMutableDictionary *subscriptions;

@end
