#define THEMES_PATH [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Documents/Themes"]

BOOL installTheme(NSURL *url);
BOOL uninstallTheme(NSString *name);
NSString* getThemeName(NSURL *url);
NSArray* getThemes();
NSString* getTheme();
int getMode();
BOOL checkTheme(NSString *name);
NSDictionary* getThemeMap();
NSString* getThemeJSON(NSString *name);
void setTheme(NSString *name, NSString *theme);
BOOL deleteTheme();