//
//  FMErrors.h
//  FMSocker
//
//  Created by Hannes Ljungberg on 29/09/15.
//  Copyright © 2015 5 Monkeys Agency AB. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const FMErrorDomain;

enum {
    FMSockerInvalidDataError = 1000,
    FMSockerDataParseError,
};
