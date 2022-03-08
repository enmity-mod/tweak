#define PLUGINS_PATH [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Documents/Plugins"]

NSString* getPluginPath(NSString *name);
NSString* getPluginName(NSURL *url);

BOOL createPluginsFolder();
NSArray* getPlugins();

BOOL checkPlugin(NSString *name);
BOOL installPlugin(NSURL *url);
BOOL deletePlugin(NSString *name);
BOOL disablePlugin(NSString *name);
BOOL enablePlugin(NSString *name);
BOOL isEnabled(NSString *name);

NSString* wrapPlugin(NSString *code, int pluginID, NSString *name);