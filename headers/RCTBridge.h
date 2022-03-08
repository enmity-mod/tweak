#import <objc/NSObject.h>
#import "RCTCxxBridge.h"

@class NSArray, NSDictionary, NSLock, NSString, NSURL;

@interface RCTBridge
{
    RCTCxxBridge *_batchedBridge;
}

@property(retain) RCTCxxBridge *batchedBridge;

@end
