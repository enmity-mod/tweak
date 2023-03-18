#import "Enmity.h"
#import <CommonCrypto/CommonDigest.h>

// Get the download url for Enmity.js
NSString* getDownloadURL() {
  return @"https://raw.githubusercontent.com/acquitelol/enmity/themer-rewrite/dist/Enmity.js";
}

// Check for update
BOOL checkForUpdate() {
  if (!checkFileExists(ENMITY_PATH)) {
    return true;
  }

  NSMutableURLRequest *enmityRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.github.com/repos/acquitelol/enmity/commits?path=dist%2FEnmity.js&page=1&per_page=1"]];
  enmityRequest.timeoutInterval = 5.0;
  enmityRequest.cachePolicy = NSURLRequestReloadIgnoringCacheData;
  NSHTTPURLResponse *response;
  NSError *err;

  [enmityRequest setValue:@"HEAD" forKey:@"HTTPMethod"];
  [NSURLConnection sendSynchronousRequest:enmityRequest returningResponse:&response error:&err];

  if (err) {
    return false;
  }

  if ([response respondsToSelector:@selector(allHeaderFields)]) {
    NSDictionary *headers = [response allHeaderFields];
    NSString *lastModified = [headers valueForKey:@"Last-Modified"];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *enmityVersion = [userDefaults stringForKey:@"enmity-version"];

    if (!enmityVersion || ![enmityVersion isEqualToString:lastModified]) {
      [userDefaults setObject:lastModified forKey:@"enmity-version"];
      return true;
    }
  }

  return false;
}

// Download a file
BOOL downloadFile(NSString *source, NSString *dest) {
  NSMutableURLRequest *downloadRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:source]];
  downloadRequest.cachePolicy = NSURLRequestReloadIgnoringCacheData;
  NSError *err;

  NSData *data = [NSURLConnection sendSynchronousRequest:downloadRequest returningResponse:nil error:&err];

  if (err) {
    return false;
  }

  if (data) {
    [data writeToFile:dest atomically:YES];
    return true;
  }

  return true;
}

// Check if a file exists
BOOL checkFileExists(NSString *path) {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  return [fileManager fileExistsAtPath:path];
}

// Create a folder
BOOL createFolder(NSString *path) {
  NSFileManager *fileManager = [NSFileManager defaultManager];

  if ([fileManager fileExistsAtPath:path]) {
    return true;
  }

  NSError *err;
  [fileManager
    createDirectoryAtPath:path
    withIntermediateDirectories:false
    attributes:nil
    error:&err];

  if (err) {
    return false;
  }

  return true;
}

// Read a folder
NSArray* readFolder(NSString *path) {
  NSFileManager *fileManager = [NSFileManager defaultManager];

  NSError *err;
  NSArray *files = [fileManager contentsOfDirectoryAtPath:path error:&err];
  if (err) {
    return [[NSArray alloc] init];
  }

  return files;
}

// Get the Enmity bundle path
NSString* getBundlePath() {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:BUNDLE_PATH]) {
    return BUNDLE_PATH;
  }

  NSURL *appFolder = [[NSBundle mainBundle] bundleURL];
  NSString *bundlePath = [NSString stringWithFormat:@"%@/EnmityFiles.bundle", [appFolder path]];
  if ([fileManager fileExistsAtPath:bundlePath]) {
    return bundlePath;
  }

  return nil;
}

// Get a file from the bundle
NSString* getFileFromBundle(NSString *bundlePath, NSString *fileName) {
  NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
  if (bundle == nil) {
    return nil;
  }

  NSString *filePath = [bundle pathForResource:fileName ofType:@"js"];
  NSData *fileData = [NSData dataWithContentsOfFile:filePath options:0 error:nil];

  return [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
}

// Create an alert prompt
void alert(NSString *message) {
  UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Alert"
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *confirmButton = [UIAlertAction
                                    actionWithTitle:@"Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:nil];

  [alert addAction:confirmButton];

  UIViewController *viewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
  [viewController presentViewController:alert animated:YES completion:nil];
}

// Create a confirmation prompt
void confirm(NSString *title, NSString *message, void (^confirmed)(void)) {
  UIAlertController *alert = [UIAlertController
                                  alertControllerWithTitle:title
                                  message:message
                                  preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction *confirmButton = [UIAlertAction
                                    actionWithTitle:@"Confirm"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction *action) {
                                      confirmed();
                                    }];

  UIAlertAction *cancelButton = [UIAlertAction
                                  actionWithTitle:@"Cancel"
                                  style:UIAlertActionStyleCancel
                                  handler:nil];

  [alert addAction:cancelButton];
  [alert addAction:confirmButton];

  UIViewController *viewController = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
  [viewController presentViewController:alert animated:YES completion:nil];
}