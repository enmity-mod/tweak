#import <UIKit/UIView.h>

@class NSDictionary, NSString, RCTBridge, UIViewController;

@interface RCTRootView : UIView
{
    RCTBridge *_bridge;
}

@property(readonly, nonatomic) RCTBridge *bridge; // @synthesize bridge=_bridge;

@end