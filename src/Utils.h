#import "../headers/RCTBridge.h"
#import "../headers/RCTRootView.h"
#import "../headers/RCTCxxBridge.h"

BOOL checkForUpdate();
BOOL downloadFile(NSString *source, NSString *dest);

BOOL checkFileExists(NSString *path);
BOOL createFolder(NSString *path);
NSArray* readFolder(NSString *path);

void alert(NSString *message);
void confirm(NSString *title, NSString *message, void (^confirmed)(void));