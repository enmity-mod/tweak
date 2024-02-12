#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Commands.h"
#import "Plugins.h"
#import "Utilities.h"
#import "Theme.h"

#define ENMITY_PATH [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Documents/enmity.bundle"]
#define ENMITY_SOURCE [NSURL URLWithString:@"enmity"]
#define VERSION @"2.2.6"
#define TYPE @"Regular"

// Disable logs in release mode
#ifdef DEBUG
#   define IS_DEBUG true
#   define NSLog(fmt, ... ) NSLog((@"[Enmity] " fmt), ##__VA_ARGS__);
#else
#   define IS_DEBUG false
#   define NSLog(...) (void)0
#endif