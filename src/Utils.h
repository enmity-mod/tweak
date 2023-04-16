#import "../headers/RCTBridge.h"
#import "../headers/RCTRootView.h"
#import "../headers/RCTCxxBridge.h"

# ifdef THEOS_PACKAGE_INSTALL_PREFIX
#   define BUNDLE_PATH @THEOS_PACKAGE_INSTALL_PREFIX "/Library/Application Support/Enmity/EnmityFiles.bundle"
# else
#   define BUNDLE_PATH @"/Library/Application Support/Enmity/EnmityFiles.bundle"
# endif

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