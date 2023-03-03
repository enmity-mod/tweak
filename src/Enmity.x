#import "Enmity.h"
#import "Utils.h"
#import "Plugins.h"

%hook RCTCxxBridge

- (void)executeApplicationScript:(NSData *)script url:(NSURL *)url async:(BOOL)async {
  NSString *bundlePath = getBundlePath();

  // Apply React DevTools patch if its enabled
  @try {
    NSString *devtoolsBundle = getFileFromBundle(bundlePath, @"devtools");
    NSData *devtools = [devtoolsBundle dataUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"Injecting React DevTools patch");
    %orig(devtools, ENMITY_SOURCE, false);
  } @catch(NSException *e) {
    NSLog(@"React DevTools failed to initialize. %@", e);
  }

  // Apply modules patch
  @try {
    NSString *modulesBundle = getFileFromBundle(bundlePath, @"modules");
    NSData *modules = [modulesBundle dataUsingEncoding:NSUTF8StringEncoding];

    NSLog(@"Injecting modules patch");
    %orig(modules, ENMITY_SOURCE, false);
  } @catch(NSException *e) {
    NSLog(@"Modules patch injection failed, expect issues. %@", e);
  }

  // Apply theme patch
  NSString *theme = getTheme();
  if (theme != nil) {
    @try {
      NSString *json = getThemeJSON(theme);
      NSString *themeBundle = [NSString stringWithFormat:getFileFromBundle(bundlePath, @"themes"), json];
      NSData* theme = [themeBundle dataUsingEncoding:NSUTF8StringEncoding];

      NSLog(@"Injecting theme patch");
      %orig(theme, ENMITY_SOURCE, false);
    } @catch(NSException *e) {
      NSLog(@"Theme patch injection failed, expect unthemed areas. %@", e);
    }
  }

  NSLog(@"Injecting discord's bundle");
  %orig(script, url, false);

  // Check for updates
  if (checkForUpdate()) {
    NSLog(@"Downloading Enmity.js to %@", ENMITY_PATH);
    downloadFile(getDownloadURL(), ENMITY_PATH);
  }

  // Check if Enmity was downloaded properly
  if (!checkFileExists(ENMITY_PATH)) {
    NSLog(@"Enmity.js not found");
    %orig([@"alert(`Enmity.js couldn't be found, please try restarting Discord.`);" dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);
    return;
  }

  // Global values
  NSString *debugState = [NSString stringWithFormat:@"window.enmity_debug = %s;", "true"];
  %orig([debugState dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);

  // Initialize addon states
  NSString *addonInit = @"window.plugins = { enabled: [], disabled: [] };";
  %orig([addonInit dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);

  // Inject themes
  NSArray *themesList = getThemes();
  if (theme == nil) theme = @"";

  NSMutableArray *themes = [[NSMutableArray alloc] init];
  for (NSString *theme in themesList) {
    @try {
      NSString *themeJson = getThemeJSON(theme);
      [themes addObject:themeJson];
    } @catch(NSException *e) {
      // RIP.
    }
  }

  @try {
    NSString *themesBundle = [NSString stringWithFormat:@"window.themes = {}; window.themes.list = [%@]; window.themes.theme = \"%@\";", [themes componentsJoinedByString:@","], theme];

    NSLog(@"Injecting themes storage patch.");
    %orig([themesBundle dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);
  } @catch(NSException *e) {
    NSLog(@"Failed to inject themes storage patch. %@", e);
  }

  // Inject Enmity script
  @try {
    NSError* error = nil;
    NSData* enmity = [NSData dataWithContentsOfFile:ENMITY_PATH options:0 error:&error];
    if (error) {
      NSLog(@"Couldn't load Enmity.js");
      return;
    }

    NSString *code = [[NSString alloc] initWithData:enmity encoding:NSUTF8StringEncoding];
    code = wrapPlugin(code, 9000, @"Enmity.js");

    NSLog(@"Injecting enmity's bundle");
    %orig([code dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);
  } @catch(NSException *e) {
    NSLog(@"Failed to load enmity bundle, enmity will not work. %@", e);
    return;
  }

  // Load plugins
  NSLog(@"Injecting Plugins");
  NSArray* plugins = getPlugins();

  int moduleID = 9001;

  for (NSString *plugin in plugins) {
    NSString *path = getPluginPath(plugin);
    NSString *name = getPluginName([NSURL URLWithString:plugin]);

    @try {
      char *enabled = isEnabled(path) ? "enabled" : "disabled";
      NSString *code = [NSString stringWithFormat:@"window.plugins.%s.push('%@')", enabled, name];

      %orig([code dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);
    } @catch(NSException *e) {
      NSLog(@"Failed to push plugin %@. %@", name, e);
      continue;
    }

    NSError* error = nil;
    NSData* data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if (error) {
      NSLog(@"Couldn't load %@", plugin);
      continue;
    }

    NSString *bundle = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    @try {
      NSLog(@"Injecting %@", plugin);
      %orig([wrapPlugin(bundle, moduleID, plugin) dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);
      moduleID += 1;
    } @catch(NSException *e) {
      NSLog(@"Failed to inject %@. %@", plugin, e);
    }
  }
}

%end

%ctor {
  createFolder(PLUGINS_PATH);
  createFolder(THEMES_PATH);
}