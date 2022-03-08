#define THEMES_PATH [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Documents/Themes"]

NSArray* getThemes();
NSString* getTheme();
int getMode();
NSDictionary* getThemeMap();
NSString* getThemeJSON(NSString *name);
void setTheme(NSString *name, NSString *theme);
BOOL deleteTheme();