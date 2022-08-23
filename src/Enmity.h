#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Commands.h"
#import "Plugins.h"
#import "Utils.h"
#import "Theme.h"

#define ENMITY_PATH [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Documents/Enmity.js"]
#define ENMITY_SOURCE [NSURL URLWithString:@"enmity"]

// Whether to inject react devtools or not
#ifdef DEVTOOLS
#    define DEVTOOLS_ENABLED true
#else
#    define DEVTOOLS_ENABLED false
#endif

// Define the URL used to download Enmity, also disable logs in release mode
#ifdef DEBUG
#   define IS_DEBUG true
#		define NSLog(fmt, ... ) NSLog((@"[Enmity-iOS] " fmt), ##__VA_ARGS__);
#else
#   define IS_DEBUG false
#		define NSLog(...) (void)0
#endif
