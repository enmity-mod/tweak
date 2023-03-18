#define THEMES_PATH [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Documents/Themes"]

#define HOOK_COLOR(clr, kind) +(id)clr { \
	id original = %orig; \
	id color = getColor(@#clr, @#kind); \
	if (color) { \
		return color; \
	} \
	return original; \
}

#define HOOK_TABLE_CELL(name) %hook name \
    - (void)setBackgroundColor:(UIColor*)arg1 { \
        NSString *url = getBackgroundURL(); \
        \
        if (url) { \
            %orig([UIColor clearColor]); \
            return; \
        } \
        \
        %orig(arg1); \
    } \
%end

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
NSDictionary *getBackgroundMap();
int getBackgroundBlur();
NSString *getBackgroundURL();
float getBackgroundAlpha();
