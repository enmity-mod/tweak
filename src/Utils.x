#import "Enmity.h"

// Check for update
BOOL checkForUpdate() {
  NSMutableURLRequest *enmityFile = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:ENMITY_URL]];
  NSHTTPURLResponse *response;
  NSError *err;

  [enmityFile setValue:@"HEAD" forKey:@"HTTPMethod"];
  [NSURLConnection sendSynchronousRequest:enmityFile returningResponse:&response error:&err];

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
	NSURL *url = [NSURL URLWithString:source];
  NSLog(@"downloadFile: %@", url.absoluteString);
	NSData *data = [NSData dataWithContentsOfURL:url];

	if (data) {
		[data writeToFile:dest atomically:YES];
    return true;
	}

  return false;
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