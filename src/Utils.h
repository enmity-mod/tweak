#import "../headers/RCTBridge.h"
#import "../headers/RCTRootView.h"
#import "../headers/RCTCxxBridge.h"

#define BUNDLE_PATH @"/Library/Application Support/Enmity/EnmityFiles.bundle"

#ifdef BETA
#   define IS_BLEEDING_EDGE true
#   define ENMITY_URL @"https://raw.githubusercontent.com/enmity-mod/enmity/main/dist/Enmity.js"
#else
#   define IS_BLEEDING_EDGE false
#   define ENMITY_URL @"https://files.enmity.app/Enmity.js"
#endif

NSString* getDownloadURL();
BOOL checkForUpdate();
BOOL downloadFile(NSString *source, NSString *dest);

BOOL checkFileExists(NSString *path);
BOOL createFolder(NSString *path);
NSArray* readFolder(NSString *path);

NSString* getBundlePath();
NSString* getFileFromBundle(NSString *bundlePath, NSString *fileName);

void alert(NSString *message);
void confirm(NSString *title, NSString *message, void (^confirmed)(void));