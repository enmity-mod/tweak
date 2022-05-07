#import "Enmity.h"
#import <CommonCrypto/CommonDigest.h>

// Get the download url for Enmity.js
NSString* getDownloadURL() {
  if (!IS_DEBUG) {
    return ENMITY_URL;
  }

  return [NSString stringWithFormat:@"http://%@:8080/Enmity.js", DEBUG_IP];
}

// Check for update
BOOL checkForUpdate() {
  if (IS_DEBUG || IS_BLEEDING_EDGE) {
    return true;
  }
  
  NSMutableURLRequest *enmityRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:getDownloadURL()]];
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

  // Force update if Enmity.js couldn't be found
  if (!checkFileExists(ENMITY_PATH)) {
    return true;
  }

  return false;
}

NSString* getHash(NSString *url) {
  NSMutableURLRequest *hashRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
  NSError *err;
  NSData *hash = [NSURLConnection sendSynchronousRequest:hashRequest returningResponse:nil error:&err];

  if (err) {
    return nil;
  }

  return [[NSString alloc] initWithData:hash encoding:NSUTF8StringEncoding];
}

// Make sure the Enmity hash matches with the github hash
BOOL compareRemoteHashes() {
  if (IS_DEBUG || IS_BLEEDING_EDGE) {
    return true;
  }

  NSString *githubHash = getHash(GITHUB_HASH);
  if (githubHash == nil) {
    return false;
  }

  NSString *remoteHash = getHash(REMOTE_HASH);
  if (remoteHash == nil) {
    return false;
  }

  return [githubHash isEqualToString:remoteHash];
}

// Make sure the downloaded Enmity file matches with the Github hash
BOOL compareLocalHashes() {
  if (IS_DEBUG || IS_BLEEDING_EDGE) {
    return true;
  }

  NSString *githubHash = getHash(GITHUB_HASH);
  if (githubHash == nil) {
    return false;
  }

  NSError *err;
  NSData *enmityFile = [NSData dataWithContentsOfFile:ENMITY_PATH options:0 error:&err];
  if (err) {
    return false;
  }

  unsigned char enmityRawHash[CC_SHA256_DIGEST_LENGTH];
	CC_SHA256(enmityFile.bytes, enmityFile.length, enmityRawHash);

  NSMutableString *enmityHash = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
	for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
		[enmityHash appendFormat:@"%02x", enmityRawHash[i]];
	}

  return [githubHash isEqualToString:enmityHash];
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