#define THEMES_PATH [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Documents/Themes"]

BOOL installTheme(NSURL *url);
BOOL uninstallTheme(NSString *name);
NSArray* getThemes();
NSString* getTheme();
int getMode();
NSDictionary* getThemeMap();
NSString* getThemeJSON(NSString *name);
void setTheme(NSString *name, NSString *theme);
BOOL deleteTheme();
NSDictionary *getBackgroundMap();
int getBackgroundBlur();
NSString *getBackgroundURL();
float getBackgroundAlpha();
