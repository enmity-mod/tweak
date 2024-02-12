#import "../Headers/Enmity.h"
#import <CommonCrypto/CommonDigest.h>

NSString *etag = nil;
NSString *bundle = nil;

NSString* getDownloadURL() {
  if (!IS_DEBUG) {
    return @"https://raw.githubusercontent.com/enmity-mod/enmity/main/dist/enmity.bundle";
  }

  return [NSString stringWithFormat:@"http://%@:8080/enmity.bundle", DEBUG_IP];
}

NSString* makeJSON(NSArray *array) {
	NSError *error;
	NSData *data = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];

	if (error != nil) {
		return @"[]";
	} else {
		return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}
}

BOOL checkForUpdate() {
	__block BOOL result = false;
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	dispatch_queue_attr_t qos = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, -1);
	dispatch_queue_t queue = dispatch_queue_create("updater", qos);
	__block NSException *exception;

	NSURL *url = [NSURL URLWithString:getDownloadURL()];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

	[request setHTTPMethod:@"HEAD"];

  request.timeoutInterval = 1.0;
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;

	dispatch_async(queue, ^{
		@try {
			NSURLSession *session = [NSURLSession sharedSession];
			NSURLSessionTask *task = [session dataTaskWithRequest:request
				completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
					NSHTTPURLResponse *http = (NSHTTPURLResponse*) response;
					NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];

					if (error != nil || [http statusCode] != 200) {
						exception = [[NSException alloc] initWithName:@"UpdateCheckFailed" reason:error.localizedDescription userInfo:nil];
					} else {
						NSString *tag = [settings stringForKey:@"enmity-etag"];
						NSDictionary *headers = [http allHeaderFields];
						NSString *header = headers[@"etag"];

						result = ![header isEqualToString:tag];

						if (result) {
							etag = header;
							NSLog(@"Detected new update.")
						} else {
							NSLog(@"No updates found.")
						}
					}

					dispatch_semaphore_signal(semaphore);
				}
			];

			[task resume];
		} @catch (NSException *e) {
			exception = e;
			dispatch_semaphore_signal(semaphore);
		}
	});

	// Freeze the main thread until the request is complete
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

	if (exception) {
		NSLog(@"Encountered error while checking for updates. (%@)", exception);
		alert(@"Failed to check for updates, bundle may be out of date. Please report this to the developers.");
		result = false;
	}

	return result;
}

BOOL downloadFile(NSString *source, NSString *dest) {
	__block BOOL result = false;
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	dispatch_queue_attr_t qos = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, -1);
	dispatch_queue_t queue = dispatch_queue_create("download", qos);
	__block NSException *exception;

	NSURL *url = [NSURL URLWithString:source];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

  request.timeoutInterval = 5.0;
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;

	dispatch_async(queue, ^{
		@try {
			NSURLSession *session = [NSURLSession sharedSession];
			NSURLSessionTask *task = [session dataTaskWithRequest:request
				completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
					if (error != nil) {
						NSLog(@"Got error: %@.", error);
						exception = [[NSException alloc] initWithName:@"DownloadFailed" reason:error.localizedDescription userInfo:nil];
					} else {
						[data writeToFile:dest atomically:YES];
						result = true;
					}

					dispatch_semaphore_signal(semaphore);
				}
			];

			[task resume];
		} @catch (NSException *e) {
			NSLog(@"Got error: %@.", e);
			exception = e;
			dispatch_semaphore_signal(semaphore);
		}
	});

	// Freeze the main thread until the request is complete
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

	if (exception) {
		NSLog(@"Failed to download %@ to %@. (%@)", source, dest, exception);
		result = false;
	}

	return result;
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

  NSError *error;
  NSArray *files = [fileManager contentsOfDirectoryAtPath:path error:&error];
  if (error) {
    return [[NSArray alloc] init];
  }

  return files;
}

NSString* getBundlePath() {
	if (bundle) {
		NSLog(@"Using cached bundle URL.");
		return bundle;
	}

	NSFileManager *manager = [NSFileManager defaultManager];
	if ([manager fileExistsAtPath:BUNDLE_PATH]) {
    return BUNDLE_PATH;
  }

	// Attempt to get the bundle from an exact path
	NSString *exact = @"/Library/Application Support/Enmity/EnmityResources.bundle";
	if ([manager fileExistsAtPath:exact]) {
		bundle = exact;
		return exact;
	}

	// Fall back to a relative path on non-jailbroken devices
	NSURL *url = [[NSBundle mainBundle] bundleURL];
  NSString *relative = [NSString stringWithFormat:@"%@/EnmityResources.bundle", [url path]];

	if ([manager fileExistsAtPath:relative]) {
		bundle = relative;
    return relative;
  }

  return nil;
}

// Get a file from the bundle
NSData* getFileFromBundle(NSString *fileName, NSString *extension) {
	NSBundle *bundle = [NSBundle bundleWithPath:getBundlePath()];
	if (bundle == nil) {
    return nil;
  }

	NSError *error = nil;
  NSString *path = [bundle pathForResource:fileName ofType:extension];
  NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];

	if (error) {
		return nil;
	}

  return data;
}

// Create an alert prompt
void alert(NSString *message) {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Enmity" message:message preferredStyle:UIAlertControllerStyleAlert];

	// Buttons
  UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil];
	UIAlertAction *server = [UIAlertAction actionWithTitle:@"Join Server" style:UIAlertActionStyleDefault
		handler: ^(UIAlertAction *action) {
			NSURL *URL = [NSURL URLWithString:@"https://discord.com/invite/rMdzhWUaGT"];
			UIApplication *application = [UIApplication sharedApplication];

			[application openURL:URL options:@{} completionHandler:nil];
		}
	];

  [alert addAction:confirm];
  [alert addAction:server];

  dispatch_async(dispatch_get_main_queue(), ^{
		UIViewController *controller = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
		[controller presentViewController:alert animated:YES completion:nil];
	});
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

	dispatch_async(dispatch_get_main_queue(), ^{
		UIViewController *controller = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
		[controller presentViewController:alert animated:YES completion:nil];
	});
}

%group Debug
	%hook NSError
		- (id) initWithDomain:(id)domain code:(int)code userInfo:(id)userInfo {
			NSLog(@"[Error] Initialized with info: %@ %@ %d", userInfo, domain, code);
			return %orig();
		};

		+ (id) errorWithDomain:(id)domain code:(int)code userInfo:(id)userInfo {
			NSLog(@"[Error] Initialized with info: %@ %@ %d", userInfo, domain, code);
			return %orig();
		};
	%end

	%hook NSException
		- (id) initWithName:(id)name reason:(id)reason userInfo:(id)userInfo {
			NSLog(@"[Exception] Initialized with info: %@ %@ %@", userInfo, name, reason);
			return %orig();
		};

		+ (id) exceptionWithName:(id)name reason:(id)reason userInfo:(id)userInfo {
			NSLog(@"[Exception] Initialized with info: %@ %@ %@", userInfo, name, reason);
			return %orig();
		};
	%end
%end

%ctor {
	%init();

	if (IS_DEBUG) {
		%init(Debug);
	}
}