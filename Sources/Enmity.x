#import "../Headers/Enmity.h"
#import "../Headers/Utilities.h"
#import "../Headers/Plugins.h"

%hook RCTCxxBridge
	- (void)executeApplicationScript:(NSData *)script url:(NSURL *)url async:(BOOL)async {
		// Apply React DevTools patch if its enabled
		#if DEVTOOLS == 1
			@try {
				NSData *devtools = getFileFromBundle(@"devtools", @"bundle");

				NSLog(@"Attempting to execute DevTools bundle...");
				%orig(devtools, ENMITY_SOURCE, async);
				NSLog(@"Successfully executed DevTools bundle.");
			} @catch(NSException *e) {
				NSLog(@"React DevTools failed to initialize. %@", e);
			}
		#endif

		// Apply modules patch
		@try {
			NSData *modules = getFileFromBundle(@"modules", @"bundle");

			NSLog(@"Attempting to execute modules patch...");
			%orig(modules, ENMITY_SOURCE, async);
			NSLog(@"Successfully executed modules patch.");
		} @catch(NSException *e) {
			NSLog(@"Modules patch injection failed, expect issues. %@", e);
			alert(@"Failed to grab internal Discord modules. please report this to the developers.");
			return %orig(script, url, async);
		}

		NSLog(@"Injecting discord's bundle");
		%orig(script, url, async);

		// Check for updates
		if (checkForUpdate()) {
			downloadFile(getDownloadURL(), ENMITY_PATH);
		}

		// Check if Enmity was downloaded properly
		if (!checkFileExists(ENMITY_PATH)) {
			return alert(@"Bundle not found, please report this to the developers.");
		}

		NSLog(@"Pre-loading plugins.");
		NSArray *plugins = getPlugins();
		NSString *json = makeJSON(plugins);

		NSString *js = [NSString stringWithFormat:@"this.ENMITY_PLUGINS = %@", json];
		%orig([js dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, async);

		// Inject Enmity script
		@try {
			NSError* error = nil;
			NSData* enmity = [NSData dataWithContentsOfFile:ENMITY_PATH options:0 error:&error];

			if (error) {
				@throw [[NSException alloc] initWithName:error.domain
					reason:error.localizedDescription
					userInfo:nil
				];
			}

			NSLog(@"Attempting to execute bundle...");
			%orig(enmity, ENMITY_SOURCE, async);
			NSLog(@"Enmity's bundle successfully executed.");
		} @catch(NSException *e) {
			NSLog(@"Failed to load enmity bundle, enmity will not work. %@", e);
			return alert(@"Failed to load Enmity's bundle. Please report this to the developers.");
		}
	}
%end

%ctor {
  createFolder(PLUGINS_PATH);
  createFolder(THEMES_PATH);
}