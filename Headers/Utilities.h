#import "./Discord/RCTBridge.h"
#import "./Discord/RCTRootView.h"
#import "./Discord/RCTCxxBridge.h"

# ifdef THEOS_PACKAGE_INSTALL_PREFIX
#   define BUNDLE_PATH @THEOS_PACKAGE_INSTALL_PREFIX "/Library/Application Support/Enmity/EnmityResources.bundle"
# else
#   define BUNDLE_PATH @"/Library/Application Support/Enmity/EnmityResources.bundle"
# endif

NSString* getDownloadURL();
BOOL checkForUpdate();
BOOL downloadFile(NSString *source, NSString *dest);

BOOL checkFileExists(NSString *path);
BOOL createFolder(NSString *path);
NSArray* readFolder(NSString *path);

NSString* makeJSON(NSArray *array);
NSString* getBundlePath();
NSData* getFileFromBundle(NSString *fileName, NSString *extension);

void alert(NSString *message);
void confirm(NSString *title, NSString *message, void (^confirmed)(void));