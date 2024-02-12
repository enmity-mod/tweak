#import <Foundation/Foundation.h>

%hook NSFileManager
	- (NSURL*)containerURLForSecurityApplicationGroupIdentifier:(NSString*)identifier {
		if (identifier != nil) {
			NSError *error;

			NSFileManager *manager = [NSFileManager defaultManager];
			NSURL *url = [manager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];

			if (error) {
				NSLog(@"[Error] Failed getting documents directory: %@", error);
				return %orig(identifier);
			}

			return url;
		}

		return %orig(identifier);
	}
%end