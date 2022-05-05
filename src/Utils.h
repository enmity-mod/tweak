#import "../headers/RCTBridge.h"
#import "../headers/RCTRootView.h"
#import "../headers/RCTCxxBridge.h"

#define GITHUB_HASH @"https://github.com/enmity-mod/enmity/releases/latest/download/hash"
#define REMOTE_HASH @"https://files.enmity.app/hash"
#define BUNDLE_PATH @"/Library/Application Support/Enmity/EnmityFiles.bundle"

#if BLEEDING_EDGE == 1
#   define IS_BLEEDING_EDGE true
#   define ENMITY_URL @"https://raw.githubusercontent.com/enmity-mod/enmity/main/dist/Enmity.js"
#else 
#   define IS_BLEEDING_EDGE false
#   define ENMITY_URL @"https://files.enmity.app/Enmity.js"
#endif

NSString* getDownloadURL();
BOOL checkForUpdate();
NSString* getHash(NSString *url);
BOOL compareRemoteHashes();
BOOL compareLocalHashes();
BOOL downloadFile(NSString *source, NSString *dest);

BOOL checkFileExists(NSString *path);
BOOL createFolder(NSString *path);
NSArray* readFolder(NSString *path);

NSString* getBundlePath();
NSString* getFileFromBundle(NSString *bundlePath, NSString *fileName);

void alert(NSString *message);
void confirm(NSString *title, NSString *message, void (^confirmed)(void));