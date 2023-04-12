#import "../headers/RCTBridge.h"
#import "../headers/RCTRootView.h"
#import "../headers/RCTCxxBridge.h"

#define BUNDLE_PATH @THEOS_PACKAGE_INSTALL_PREFIX "/Library/Application Support/Enmity/EnmityFiles.bundle"

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