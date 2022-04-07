#import "../headers/RCTBridge.h"
#import "../headers/RCTRootView.h"
#import "../headers/RCTCxxBridge.h"

#define GITHUB_HASH @"https://github.com/enmity-mod/enmity/releases/latest/download/hash"
#define REMOTE_HASH @"https://files.enmity.app/hash"
#define BUNDLE_PATH @"/Library/Application Support/Enmity/EnmityFiles.bundle"

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