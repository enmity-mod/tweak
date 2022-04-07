#import "Enmity.h"
#import "Utils.h"
#import "Plugins.h"

@interface AppDelegate
    @property (nonatomic, strong) UIWindow *window;
@end

%hook AppDelegate

- (id)sourceURLForBridge:(id)arg1 {
	return %orig;
}

- (void)startWithLaunchOptions:(id)options {
	%orig;
}

%end

%hook RCTCxxBridge

- (void)executeApplicationScript:(NSData *)script url:(NSURL *)url async:(BOOL)async {
	// Apply modules patch
	NSString *modulesPatchCode = @"const oldObjectCreate = this.Object.create;"\
																"const _window = this;"\
																"_window.Object.create = (...args) => {"\
																"    const obj = oldObjectCreate.apply(_window.Object, args);"\
																"    if (args[0] === null) {"\
																"        _window.modules = obj;"\
																"        _window.Object.create = oldObjectCreate;"\
																"    }"\
																"    return obj;"\
																"};";

	NSData* modulesPatch = [modulesPatchCode dataUsingEncoding:NSUTF8StringEncoding];
	NSLog(@"Injecting modules patch");
	%orig(modulesPatch, ENMITY_SOURCE, false);

	// Apply theme patch
	NSString *theme = getTheme();
	if (theme != nil) {
		NSString *themeJson = getThemeJSON(theme);

		NSString *themePatchCode =
			[NSString stringWithFormat: @"const oObjectFreeze = this.Object.freeze;" \
                                                                     "Object.freeze = function(obj, ...args) {" \
                                                                     "  if (!obj?.hasOwnProperty) { " \
                                                                     "     return oObjectFreeze.apply(this, [obj, ...args])" \
                                                                     "  } " \
                                                                     "  try { " \
                                                                     "	   const theme = %@;" \
                                                                     "     if (obj.hasOwnProperty?.('BACKGROUND_PRIMARY')) {" \
                                                                     " 		   return oObjectFreeze.apply(this, [{" \
                                                                     "              ...obj," \
                                                                     "			      ...theme.theme_color_map" \
                                                                     "		   }, ...args]);" \
                                                                     "	   }" \
                                                                     "     if (obj.hasOwnProperty?.('PRIMARY_DARK')) {" \
                                                                     " 		   return oObjectFreeze.apply(this, [{" \
                                                                     "			   ...obj," \
                                                                     "			   ...theme.colours" \
                                                                     "		   }, ...args]);" \
                                                                     "	   }" \
                                                                     " 	} catch(e) {" \
                                                                     " 	  console.log(e);" \
                                                                     " 	}" \
                                                                     " 	return oObjectFreeze.apply(this, [obj, ...args]);" \
                                                                     "}" \
                                                                  , themeJson];

		NSData* themePatch = [themePatchCode dataUsingEncoding:NSUTF8StringEncoding];
		NSLog(@"Injecting theme patch");
		%orig(themePatch, ENMITY_SOURCE, false);
	}

	// Load bundle
	NSLog(@"Injecting bundle");
	%orig(script, url, false);

	if (checkForUpdate()) {
		if (compareRemoteHashes()) {
			NSLog(@"Downloading Enmity.js to %@", ENMITY_PATH);
			downloadFile(getDownloadURL(), ENMITY_PATH);

			// Check if Enmity hash is valid
			if (!compareLocalHashes()) {
				%orig([@"alert(`Enmity.js hash isn't matching, not injecting Enmity.`);" dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);
				return;
			}
		} else {
			%orig([@"alert(`Enmity hashes check fail, skipping update and not injecting Enmity.`);" dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);
			return;
		}
	}

	// Check if Enmity was downloaded properly
	if (!checkFileExists(ENMITY_PATH)) {
		NSLog(@"Enmity.js not found");
		%orig([@"alert(`Enmity.js couldn't be found, please try restarting Discord.`);" dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);
		return;
	}

	// Global values
	NSString *debugCode = [NSString stringWithFormat:@"window.enmity_debug = %s;", IS_DEBUG ? "true" : "false"];
	%orig([debugCode dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);
	if (IS_DEBUG) {
		NSString *debugIpCode = [NSString stringWithFormat:@"window.enmity_debug_ip = '%@';", DEBUG_IP];
		%orig([debugIpCode dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);
	}
	%orig([@"window.plugins = {}; window.plugins.enabled = []; window.plugins.disabled = [];" dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);

	// Inject themes
	NSArray *themesList = getThemes();
	if (theme == nil) {
		theme = @"";
	}

	NSMutableArray *themes = [[NSMutableArray alloc] init];
	for (NSString *theme in themesList) {
		NSString *themeJson = getThemeJSON(theme);
		[themes addObject:themeJson];
	}

	NSString *themesCode = [NSString stringWithFormat:@"window.themes = {}; window.themes.list = [%@]; window.themes.theme = \"%@\";", [themes componentsJoinedByString:@","], theme];
	%orig([themesCode dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);

	// Inject Enmity script
	NSError* error = nil;
	NSData* enmity = [NSData dataWithContentsOfFile:ENMITY_PATH options:0 error:&error];
	if (error) {
		NSLog(@"Couldn't load Enmity.js");
		return;
	}

	NSString *enmityCode = [[NSString alloc] initWithData:enmity encoding:NSUTF8StringEncoding];
	enmityCode = wrapPlugin(enmityCode, 9000, @"Enmity.js");

	NSLog(@"Injecting Enmity");
	%orig([enmityCode dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);

	// Load plugins
	NSLog(@"Injecting Plugins");
	NSArray* pluginsList = getPlugins();
	int pluginID = 9001;
	for (NSString *plugin in pluginsList) {
		NSString *pluginPath = getPluginPath(plugin);

		%orig([[NSString stringWithFormat:@"window.plugins.%s.push('%@')", isEnabled(pluginPath) ? "enabled" : "disabled", getPluginName([NSURL URLWithString:plugin])] dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);

		NSError* error = nil;
		NSData* pluginData = [NSData dataWithContentsOfFile:pluginPath options:0 error:&error];
		if (error) {
			NSLog(@"Couldn't load %@", plugin);
			continue;
		}

		NSString *pluginCode = [[NSString alloc] initWithData:pluginData encoding:NSUTF8StringEncoding];

		NSLog(@"Injecting %@", plugin);
		%orig([wrapPlugin(pluginCode, pluginID, plugin) dataUsingEncoding:NSUTF8StringEncoding], ENMITY_SOURCE, false);
		pluginID += 1;
	}
}

%end

%ctor {
	createFolder(PLUGINS_PATH);
	createFolder(THEMES_PATH);

	downloadFile(@"https://files.enmity.app/Amoled.json", [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Documents/Themes/Amoled.json"]);
}