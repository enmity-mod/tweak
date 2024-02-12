@import Foundation;
#import "RCTCxxBridge.h"

@interface RCTBridge {
  RCTCxxBridge *_batchedBridge;
}

@property(retain) RCTCxxBridge *batchedBridge;

@end
