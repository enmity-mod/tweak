#import "../headers/RCTBridge.h"
#import "../headers/RCTRootView.h"
#import "../headers/RCTCxxBridge.h"

#define GITHUB_HASH @"https://github.com/enmity-mod/enmity/releases/latest/download/hash"
#define REMOTE_HASH @"https://files.enmity.app/hash"

NSString* getDownloadURL();
BOOL checkForUpdate();
NSString* getHash(NSString *url);
BOOL compareRemoteHashes();
BOOL compareLocalHashes();
BOOL downloadFile(NSString *source, NSString *dest);

BOOL checkFileExists(NSString *path);
BOOL createFolder(NSString *path);
NSArray* readFolder(NSString *path);

void alert(NSString *message);
void confirm(NSString *title, NSString *message, void (^confirmed)(void));