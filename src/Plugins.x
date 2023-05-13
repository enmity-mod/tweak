#import "Enmity.h"

// Get the path of a plugin via it's name
NSString* getPluginPath(NSString *name) {
  NSArray* plugins = getPlugins();

  for (NSString *plugin in plugins) {
    if ([plugin containsString:name]) {
      return [NSString stringWithFormat:@"%@/%@", PLUGINS_PATH, plugin];
    }
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
    if (![plugin containsString:@".js"]) {
      continue;
    }

    [plugins addObject:plugin];
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
  NSString *pluginName = getPluginName(url);
  NSString *dest = getPluginPath(pluginName);

  if ([dest isEqualToString:@""]) {
    dest = [NSString stringWithFormat:@"%@/%@.js", PLUGINS_PATH, pluginName];
  }

  BOOL success = downloadFile(url.absoluteString, dest);

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