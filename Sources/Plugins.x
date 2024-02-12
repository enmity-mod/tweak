#import "../Headers/Enmity.h"

// Get the path of a plugin via it's name
NSString* getPluginPath(NSString *name) {
  NSArray* plugins = getPlugins();

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"filename == %@", name];
	NSArray *results = [plugins filteredArrayUsingPredicate:predicate];

	NSLog(@"%@", results);

  if ([results count] != 0) {
		return results[0];
	}

	return @"";
}

// Get the name of a plugin via it's url
NSString* getPluginName(NSURL *url) {
  NSString *stripped = [[url lastPathComponent] stringByReplacingOccurrencesOfString:@".disable" withString:@""];
  return [stripped stringByReplacingOccurrencesOfString:@".js" withString:@""];
}

// Get the list of installed plugins
NSArray* getPlugins() {
  NSArray *files = readFolder(PLUGINS_PATH);
  NSMutableArray *plugins = [[NSMutableArray alloc] init];

	for (NSString *plugin in files) {
    @try {
			if (![plugin containsString:@".js"]) {
				continue;
			}

			NSError *error;

			NSString *path = [NSString pathWithComponents:@[PLUGINS_PATH, plugin]];
			NSString *bundle = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];

			if (error != nil) {
				@throw error;
			}

			[plugins addObject:@{
				@"path": path,
				@"filename": plugin,
				@"bundle": bundle
			}];
		} @catch (NSException *e) {
			NSLog(@"Failed to initialize plugin %@: %@", plugin, e);
		}
  }

  return [plugins copy];
}

// Check if a plugin exists
BOOL checkPlugin(NSString *name) {
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *path = getPluginPath(name);

  if ([fileManager fileExistsAtPath:path]) {
    return true;
  }

  return false;
}

// Install a plugin from an URL
BOOL installPlugin(NSURL *url) {
  NSString *name = getPluginName(url);
  NSString *dest = getPluginPath(name);

	NSLog(@"destination: %@", dest);
  if ([dest isEqualToString:@""]) {
    dest = [NSString stringWithFormat:@"%@/%@.js", PLUGINS_PATH, name];
		NSLog(@"new destination: %@", dest);
  }

	NSLog(@"Started downloading...");
  BOOL success = downloadFile(url.absoluteString, dest);
	NSLog(@"Downloaded.");

  return success;
}

// Delete a plugin
BOOL deletePlugin(NSString *name) {
  if (!checkPlugin(name)) {
    return false;
  }

  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *err;
  [fileManager removeItemAtPath:getPluginPath(name) error:&err];

  if (err) {
    return false;
  }

  return true;
}

// Disable a plugin
BOOL disablePlugin(NSString *name) {
  NSString *path = getPluginPath(name);

  if (!isEnabled(path)) {
    return false;
  }

  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *err;
  [fileManager
    moveItemAtPath:path
    toPath:[NSString stringWithFormat:@"%@/%@", PLUGINS_PATH, [NSString stringWithFormat:@"%@.js.disable", name]]
    error:&err];

  if (err) {
    return false;
  }

  return true;
}

// Enable a plugin
BOOL enablePlugin(NSString *name) {
  NSString *path = getPluginPath(name);

  if (isEnabled(path)) {
    return false;
  }

  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSError *err;
  [fileManager
    moveItemAtPath:path
    toPath:[NSString stringWithFormat:@"%@/%@", PLUGINS_PATH, [NSString stringWithFormat:@"%@.js", name]]
    error:&err];

  if (err) {
    return false;
  }

  return true;
}

// Check if a plugin is enabled
BOOL isEnabled(NSString *name) {
 return ![name containsString:@".disable"];
}

// Wrap a plugin
NSString* wrapPlugin(NSString *code, NSString *name) {
  NSString* plugin = [NSString stringWithFormat:@""\
    "(() => {"\
      "try {"\
        "%@"\
      "} catch(err) {"\
        "const error = new Error(`Fatal error with %@: ${err}`);"\
        "console.error(error.stack);"\
      "}"\
    "})();", code, name
  ];

  return plugin;
}