#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Enmity.h"

NSDictionary *colors = nil;
NSDictionary *background = nil;

// Convert an UIColor element to a hex string
NSString* hexStringFromColor(UIColor * color) {
	const CGFloat *components = CGColorGetComponents(color.CGColor);

	CGFloat r = components[0];
	CGFloat g = components[1];
	CGFloat b = components[2];
	CGFloat a = components[3];

	return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX",
		lroundf(r * 255),
		lroundf(g * 255),
		lroundf(b * 255),
		lroundf(a * 255)
	];
}

// Convert a hex color string to an UIColor element
UIColor* colorFromHexString(NSString *hexString) {
	unsigned rgbValue = 0;
	NSScanner *scanner = [NSScanner scannerWithString:hexString];
	[scanner setScanLocation: 1];
	[scanner scanHexInt: &rgbValue];

	return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

// Convert a RGBA color string to an UIColor element
UIColor* colorFromRGBAString(NSString *rgbaString) {
	NSRegularExpression *rgbaRegex = [NSRegularExpression regularExpressionWithPattern:@"\\((.*)\\)" options:NSRegularExpressionCaseInsensitive error:nil];
	NSArray *matches = [rgbaRegex matchesInString:rgbaString options:0 range:NSMakeRange(0, [rgbaString length])];
	NSString *value = [[NSString alloc] init];

	for (NSTextCheckingResult *match in matches) {
		NSRange matchRange = [match rangeAtIndex:1];
		value = [rgbaString substringWithRange:matchRange];
	}

	NSArray *values = [value componentsSeparatedByString:@","];
	NSMutableArray *rgbaValues = [[NSMutableArray alloc] init];
	for (NSString* v in values) {
		NSString *trimmed = [v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		[rgbaValues addObject:[NSNumber numberWithFloat:[trimmed floatValue]]];
	}

	return [UIColor colorWithRed:[[rgbaValues objectAtIndex:0] floatValue]/255.0f green:[[rgbaValues objectAtIndex:1] floatValue]/255.0f blue:[[rgbaValues objectAtIndex:2] floatValue]/255.0f alpha:[[rgbaValues objectAtIndex:3] floatValue]];
}

// Get the name of a theme via it's url
NSString* getThemeName(NSURL *url) {
	NSString *stripped = [[url lastPathComponent] stringByReplacingOccurrencesOfString:@".disable" withString:@""];
	return [stripped stringByReplacingOccurrencesOfString:@".json" withString:@""];
}

// Install a theme
BOOL installTheme(NSURL *url) {
	NSString *dest = [NSString stringWithFormat:@"%@/%@", THEMES_PATH, [url lastPathComponent]];

	BOOL success = downloadFile(url.absoluteString, dest);
	return success;
}

// Check if a plugin exists
BOOL checkTheme(NSString *name) {
	NSString *path = [NSString stringWithFormat:@"%@/%@.json", THEMES_PATH, name];
	NSFileManager *fileManager = [NSFileManager defaultManager];

	if ([fileManager fileExistsAtPath:path]) {
		return true;
	}

	return false;
}

// Uninstall a theme
BOOL uninstallTheme(NSString *name) {
	NSString *themePath = [NSString stringWithFormat:@"%@/%@.json", THEMES_PATH, name];
	NSFileManager *fileManager = [NSFileManager defaultManager];

	if (![fileManager fileExistsAtPath:themePath]) {
		return false;
	}

	NSError *err;
	[fileManager
		removeItemAtPath:themePath
		error:&err];

	if (err) {
		return false;
	}

	return true;
}

// Get the installed themes
NSArray* getThemes() {
	NSArray *files = readFolder(THEMES_PATH);
	NSMutableArray *themes = [[NSMutableArray alloc] init];
	for (NSString *theme in files) {
		if (![theme containsString:@".json"]) {
			continue;
		}

		[themes addObject:[theme stringByReplacingOccurrencesOfString:@".json" withString:@""]];
	}

	return [themes copy];
}

// Get the theme name
NSString* getTheme() {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *theme = [userDefaults stringForKey:@"theme"];

	return theme;
}

// Get the theme mode
int getMode() {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	int mode = [userDefaults integerForKey:@"theme_mode"];

	return mode;
}

// Get the theme map
NSDictionary* getThemeMap() {
	NSString *name = getTheme();
	if (name == nil) {
		return nil;
	}

	NSString *themeJson = getThemeJSON(name);
	if (themeJson == nil) {
		return nil;
	}

	NSError *error;
	NSMutableDictionary *theme = [NSJSONSerialization JSONObjectWithData:[themeJson dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
	if (error) {
		return nil;
	}

	int mode = getMode();
	NSDictionary *themeColorMap = theme[@"theme_color_map"];
	NSMutableDictionary *themeMap = [[NSMutableDictionary alloc] init];
	for (NSString* colourName in themeColorMap) {
		NSString *colour = themeColorMap[colourName][mode];
		[themeMap setObject:colour	forKey:colourName];
	}

	return [themeMap copy];
}

// Get the theme file daata
NSString* getThemeJSON(NSString *name) {
	NSString *themeFile = [NSString stringWithFormat:@"%@/%@.json", THEMES_PATH, name];
	if (!checkFileExists(themeFile)) {
		setTheme(nil, nil);
		return nil;
	}

	NSData *data = [NSData dataWithContentsOfFile:themeFile];
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

// Set the theme name
void setTheme(NSString *name, NSString *mode) {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

	if (name == nil && mode == nil) {
		[userDefaults removeObjectForKey:@"theme"];
		[userDefaults removeObjectForKey:@"theme_mode"];
		colors = [[NSMutableDictionary alloc] init];
		background = [[NSMutableDictionary alloc] init];
		return;
	}

	[userDefaults setObject:name forKey:@"theme"];
	[userDefaults setInteger:[mode intValue] forKey:@"theme_mode"];
	colors = nil;
	background = nil;
}

NSDictionary *getBackgroundMap() {
	NSString *name = getTheme();
	if (name == nil) {
		return nil;
	}

	NSString *themeJson = getThemeJSON(name);
	if (themeJson == nil) {
		return nil;
	}

	NSError *error;
	NSMutableDictionary *theme = [NSJSONSerialization JSONObjectWithData:[themeJson dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
	if (error) {
		return nil;
	}

	return [theme[@"background"] copy];
}

// Get the bg blur
int getBackgroundBlur() {
	if (background == nil) {
		background = getBackgroundMap();
	}

	if (![background objectForKey:@"blur"]) {
		return 0;
	}

	return [[background objectForKey:@"blur"] intValue];
}

// Get the bg image
NSString *getBackgroundURL() {
	if (background == nil) {
		background = getBackgroundMap();
	}

	if (![background objectForKey:@"url"]) {
		return @"";
	}

	return [background objectForKey:@"url"];
}

// Get the bg alpha
float getBackgroundAlpha() {
	if (background == nil) {
		background = getBackgroundMap();
	}

	if (![background objectForKey:@"alpha"]) {
		return 1.0;
	}

	return [[background objectForKey:@"alpha"] floatValue];
}

// Get a color
UIColor* getColor(NSString *name) {
	if (colors == nil) {
		colors = getThemeMap();
	}

	if (![colors objectForKey:name]) {
		return NULL;
	}

	NSString *value = colors[name];
	UIColor *color;

	if ([value containsString:@"rgba"]) {
		color = colorFromRGBAString(value);
	} else {
		color = colorFromHexString(value);
	}

	return color;
}


@interface UIKeyboard : UIView
@end

@interface UIKeyboardDockView : UIView
@end

@interface TUIPredictionView : UIView
@end

@interface TUIEmojiSearchInputView : UIView
@end

%group KEYBOARD
id originalKeyboardColor;
%hook UIKeyboard
- (void)didMoveToWindow {
	%orig;

	id color = getColor(@"KEYBOARD");
	if (originalKeyboardColor != nil && originalKeyboardColor != color) {
    originalKeyboardColor = [self backgroundColor];
  }
  if (color != nil) {
		[self setBackgroundColor:color];
	} else {
    [self setBackgroundColor:originalKeyboardColor];
  }
}
%end

%hook UIKeyboardDockView
- (void)didMoveToWindow {
	%orig;

	id color = getColor(@"KEYBOARD");
	if (originalKeyboardColor != nil && originalKeyboardColor != color) {
    originalKeyboardColor = [self backgroundColor];
  }
  if (color != nil) {
		[self setBackgroundColor:color];
	} else {
    [self setBackgroundColor:originalKeyboardColor];
  }
}
%end

%hook UIKBRenderConfig
- (void)setLightKeyboard:(BOOL)arg1 {
	%orig(NO);
}
%end

%hook TUIPredictionView
- (void)didMoveToWindow {
	%orig;


	id color = getColor(@"KEYBOARD");
	if (originalKeyboardColor != nil && originalKeyboardColor != color) {
    originalKeyboardColor = [self backgroundColor];
  }
  if (color != nil) {
		[self setBackgroundColor:color];

		for (UIView *subview in self.subviews) {
				[subview setBackgroundColor:color];
		}
	} else {
    [self setBackgroundColor:originalKeyboardColor];
    for (UIView *subview in self.subviews) {
        [subview setBackgroundColor:originalKeyboardColor];
    }
  }
}
%end

%hook TUIEmojiSearchInputView
- (void)didMoveToWindow {
	%orig;

	id color = getColor(@"KEYBOARD");
	if (originalKeyboardColor != nil && originalKeyboardColor != color) {
    originalKeyboardColor = [self backgroundColor];
  }
  if (color != nil) {
		[self setBackgroundColor:color];
	} else {
    [self setBackgroundColor:originalKeyboardColor];
  }
}
%end
%end


@interface DCDUploadProgressView : UIView
@end

%hook DCDUploadProgressView
- (void)didMoveToWindow {
	%orig;

	id color = getColor(@"BACKGROUND_SECONDARY_ALT");
	if (color != nil) {
		UIView *subview = self.subviews[0];
		[subview setBackgroundColor:color];
	}
}
%end

%hook DCDBaseMessageTableViewCell
- (void)setBackgroundColor:(UIColor*)arg1 {
	NSString *url = getBackgroundURL();

  if (url) {
      %orig([UIColor clearColor]);
      return;
  }

  %orig(arg1);
}
%end

%hook DCDSeparatorTableViewCell
- (void)setBackgroundColor:(UIColor*)arg1 {
  NSString *url = getBackgroundURL();

  if (url) {
      %orig([UIColor clearColor]);
      return;
  }

  %orig(arg1);
}
%end

%hook DCDBlockedMessageTableViewCell
- (void)setBackgroundColor:(UIColor*)arg1 {
  NSString *url = getBackgroundURL();

  if (url) {
      %orig([UIColor clearColor]);
      return;
  }

  %orig(arg1);
}
%end

%hook DCDSystemMessageTableViewCell
- (void)setBackgroundColor:(UIColor*)arg1 {
  NSString *url = getBackgroundURL();

  if (url) {
      %orig([UIColor clearColor]);
      return;
  }

  %orig(arg1);
}
%end

%hook DCDLoadingTableViewCell
- (void)setBackgroundColor:(UIColor*)arg1 {
  NSString *url = getBackgroundURL();

  if (url) {
      %orig([UIColor clearColor]);
      return;
  }

  %orig(arg1);
}
%end

@interface DCDChat : UIView
@end

%hook DCDChat
- (void)configureSubviewsWithContentAdjustment:(double)arg1 {
	%orig;

  id chatColor = getColor(@"BACKGROUND_PRIMARY");
  if (chatColor) {
    [self setBackgroundColor:chatColor];
  }

	UIView *subview = [self.subviews firstObject];
	if ([subview isKindOfClass:[UIImageView class]]) {
		return;
	}

	if (background == nil) {
		background = getBackgroundMap();
	}

  if (background == nil) {
    return;
  }

	NSString *url = getBackgroundURL();

	if (url) {
		int blur = getBackgroundBlur();
		[subview setBackgroundColor:[UIColor clearColor]];
		UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];

		CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
		CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
		[filter setValue:ciImage forKey:kCIInputImageKey];
		[filter setValue:[NSNumber numberWithFloat: blur] forKey:@"inputRadius"];
		CIImage *result = [filter valueForKey:kCIOutputImageKey];
		CIImage *croppedImage = [result imageByCroppingToRect:ciImage.extent];

		UIImageView *imageView = [[UIImageView alloc] initWithImage:[[UIImage alloc] initWithCIImage:croppedImage]];
		imageView.frame = subview.frame;
		imageView.alpha = getBackgroundAlpha();
		[self insertSubview:imageView atIndex:0];
	}
}
%end

%ctor {
	%init

	NSBundle* bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/TextInputUI.framework"];
	if (!bundle.loaded) [bundle load];
	%init(KEYBOARD);
}

// Rain hellfire on discord.
%hook DCDThemeColor
+ (id)HEADER_PRIMARY {
	id original = %orig;
	id color = getColor(@"HEADER_PRIMARY");

	if (color) {
		return color;
	}

	return original;
}

+ (id)HEADER_SECONDARY {
	id original = %orig;
	id color = getColor(@"HEADER_SECONDARY");

	if (color) {
		return color;
	}

	return original;
}

+ (id)TEXT_NORMAL {
	id original = %orig;
	id color = getColor(@"TEXT_NORMAL");

	if (color) {
		return color;
	}

	return original;
}

+ (id)TEXT_MUTED {
	id original = %orig;
	id color = getColor(@"TEXT_MUTED");

	if (color) {
		return color;
	}

	return original;
}

+ (id)TEXT_LINK {
	id original = %orig;
	id color = getColor(@"TEXT_LINK");

	if (color) {
		return color;
	}

	return original;
}

+ (id)TEXT_LINK_LOW_SATURATION {
	id original = %orig;
	id color = getColor(@"TEXT_LINK_LOW_SATURATION");

	if (color) {
		return color;
	}

	return original;
}

+ (id)TEXT_POSITIVE {
	id original = %orig;
	id color = getColor(@"TEXT_POSITIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)TEXT_WARNING {
	id original = %orig;
	id color = getColor(@"TEXT_WARNING");

	if (color) {
		return color;
	}

	return original;
}

+ (id)TEXT_DANGER {
	id original = %orig;
	id color = getColor(@"TEXT_DANGER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)TEXT_BRAND {
	id original = %orig;
	id color = getColor(@"TEXT_BRAND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INTERACTIVE_NORMAL {
	id original = %orig;
	id color = getColor(@"INTERACTIVE_NORMAL");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INTERACTIVE_HOVER {
	id original = %orig;
	id color = getColor(@"INTERACTIVE_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INTERACTIVE_ACTIVE {
	id original = %orig;
	id color = getColor(@"INTERACTIVE_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INTERACTIVE_MUTED {
	id original = %orig;
	id color = getColor(@"INTERACTIVE_MUTED");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_PRIMARY {
	id original = %orig;
	id color = getColor(@"BACKGROUND_PRIMARY");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_SECONDARY {
	id original = %orig;
	id color = getColor(@"BACKGROUND_SECONDARY");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_SECONDARY_ALT {
	id original = %orig;
	id color = getColor(@"BACKGROUND_SECONDARY_ALT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_TERTIARY {
	id original = %orig;
	id color = getColor(@"BACKGROUND_TERTIARY");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_ACCENT {
	id original = %orig;
	id color = getColor(@"BACKGROUND_ACCENT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_FLOATING {
	id original = %orig;
	id color = getColor(@"BACKGROUND_FLOATING");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_NESTED_FLOATING {
	id original = %orig;
	id color = getColor(@"BACKGROUND_NESTED_FLOATING");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_MOBILE_PRIMARY {
	id original = %orig;
	id color = getColor(@"BACKGROUND_MOBILE_PRIMARY");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_MOBILE_SECONDARY {
	id original = %orig;
	id color = getColor(@"BACKGROUND_MOBILE_SECONDARY");

	if (color) {
		return color;
	}

	return original;
}

+ (id)CHAT_BACKGROUND {
	id original = %orig;
	id color = getColor(@"CHAT_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)CHAT_BORDER {
	id original = %orig;
	id color = getColor(@"CHAT_BORDER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)CHAT_INPUT_CONTAINER_BACKGROUND {
	id original = %orig;
	id color = getColor(@"CHAT_INPUT_CONTAINER_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_MODIFIER_HOVER {
	id original = %orig;
	id color = getColor(@"BACKGROUND_MODIFIER_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_MODIFIER_ACTIVE {
	id original = %orig;
	id color = getColor(@"BACKGROUND_MODIFIER_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_MODIFIER_SELECTED {
	id original = %orig;
	id color = getColor(@"BACKGROUND_MODIFIER_SELECTED");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_MODIFIER_ACCENT {
	id original = %orig;
	id color = getColor(@"BACKGROUND_MODIFIER_ACCENT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INFO_POSITIVE_BACKGROUND {
	id original = %orig;
	id color = getColor(@"INFO_POSITIVE_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INFO_POSITIVE_FOREGROUND {
	id original = %orig;
	id color = getColor(@"INFO_POSITIVE_FOREGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INFO_POSITIVE_TEXT {
	id original = %orig;
	id color = getColor(@"INFO_POSITIVE_TEXT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INFO_WARNING_BACKGROUND {
	id original = %orig;
	id color = getColor(@"INFO_WARNING_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INFO_WARNING_FOREGROUND {
	id original = %orig;
	id color = getColor(@"INFO_WARNING_FOREGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INFO_WARNING_TEXT {
	id original = %orig;
	id color = getColor(@"INFO_WARNING_TEXT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INFO_DANGER_BACKGROUND {
	id original = %orig;
	id color = getColor(@"INFO_DANGER_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INFO_DANGER_FOREGROUND {
	id original = %orig;
	id color = getColor(@"INFO_DANGER_FOREGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INFO_DANGER_TEXT {
	id original = %orig;
	id color = getColor(@"INFO_DANGER_TEXT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INFO_HELP_BACKGROUND {
	id original = %orig;
	id color = getColor(@"INFO_HELP_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INFO_HELP_FOREGROUND {
	id original = %orig;
	id color = getColor(@"INFO_HELP_FOREGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INFO_HELP_TEXT {
	id original = %orig;
	id color = getColor(@"INFO_HELP_TEXT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)STATUS_POSITIVE_BACKGROUND {
	id original = %orig;
	id color = getColor(@"STATUS_POSITIVE_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)STATUS_POSITIVE_TEXT {
	id original = %orig;
	id color = getColor(@"STATUS_POSITIVE_TEXT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)STATUS_WARNING_BACKGROUND {
	id original = %orig;
	id color = getColor(@"STATUS_WARNING_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)STATUS_WARNING_TEXT {
	id original = %orig;
	id color = getColor(@"STATUS_WARNING_TEXT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)STATUS_DANGER_BACKGROUND {
	id original = %orig;
	id color = getColor(@"STATUS_DANGER_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)STATUS_DANGER_TEXT {
	id original = %orig;
	id color = getColor(@"STATUS_DANGER_TEXT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)STATUS_DANGER {
	id original = %orig;
	id color = getColor(@"STATUS_DANGER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)STATUS_POSITIVE {
	id original = %orig;
	id color = getColor(@"STATUS_POSITIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)STATUS_WARNING {
	id original = %orig;
	id color = getColor(@"STATUS_WARNING");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_DANGER_BACKGROUND {
	id original = %orig;
	id color = getColor(@"BUTTON_DANGER_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_DANGER_BACKGROUND_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_DANGER_BACKGROUND_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_DANGER_BACKGROUND_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_DANGER_BACKGROUND_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_DANGER_BACKGROUND_DISABLED {
	id original = %orig;
	id color = getColor(@"BUTTON_DANGER_BACKGROUND_DISABLED");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_POSITIVE_BACKGROUND {
	id original = %orig;
	id color = getColor(@"BUTTON_POSITIVE_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_POSITIVE_BACKGROUND_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_POSITIVE_BACKGROUND_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_POSITIVE_BACKGROUND_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_POSITIVE_BACKGROUND_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_POSITIVE_BACKGROUND_DISABLED {
	id original = %orig;
	id color = getColor(@"BUTTON_POSITIVE_BACKGROUND_DISABLED");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_SECONDARY_BACKGROUND {
	id original = %orig;
	id color = getColor(@"BUTTON_SECONDARY_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_SECONDARY_BACKGROUND_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_SECONDARY_BACKGROUND_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_SECONDARY_BACKGROUND_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_SECONDARY_BACKGROUND_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_SECONDARY_BACKGROUND_DISABLED {
	id original = %orig;
	id color = getColor(@"BUTTON_SECONDARY_BACKGROUND_DISABLED");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_DANGER_TEXT {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_DANGER_TEXT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_DANGER_BORDER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_DANGER_BORDER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_DANGER_BACKGROUND {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_DANGER_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_DANGER_BACKGROUND_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_DANGER_BACKGROUND_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_DANGER_TEXT_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_DANGER_TEXT_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_DANGER_BORDER_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_DANGER_BORDER_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_DANGER_BACKGROUND_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_DANGER_BACKGROUND_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_DANGER_TEXT_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_DANGER_TEXT_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_DANGER_BORDER_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_DANGER_BORDER_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_POSITIVE_TEXT {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_POSITIVE_TEXT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_POSITIVE_BORDER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_POSITIVE_BORDER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_POSITIVE_BACKGROUND {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_POSITIVE_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_POSITIVE_BACKGROUND_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_POSITIVE_BACKGROUND_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_POSITIVE_TEXT_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_POSITIVE_TEXT_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_POSITIVE_BORDER_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_POSITIVE_BORDER_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_POSITIVE_BACKGROUND_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_POSITIVE_BACKGROUND_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_POSITIVE_TEXT_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_POSITIVE_TEXT_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_POSITIVE_BORDER_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_POSITIVE_BORDER_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_BRAND_TEXT {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_BRAND_TEXT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_BRAND_BORDER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_BRAND_BORDER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_BRAND_BACKGROUND {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_BRAND_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_BRAND_BACKGROUND_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_BRAND_BACKGROUND_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_BRAND_TEXT_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_BRAND_TEXT_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_BRAND_BORDER_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_BRAND_BORDER_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_BRAND_BACKGROUND_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_BRAND_BACKGROUND_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_BRAND_TEXT_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_BRAND_TEXT_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_BRAND_BORDER_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_BRAND_BORDER_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_PRIMARY_TEXT {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_PRIMARY_TEXT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_PRIMARY_BORDER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_PRIMARY_BORDER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_PRIMARY_BACKGROUND {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_PRIMARY_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_PRIMARY_BACKGROUND_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_PRIMARY_BACKGROUND_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_PRIMARY_TEXT_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_PRIMARY_TEXT_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_PRIMARY_BORDER_HOVER {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_PRIMARY_BORDER_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_PRIMARY_BACKGROUND_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_PRIMARY_BACKGROUND_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_PRIMARY_TEXT_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_PRIMARY_TEXT_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BUTTON_OUTLINE_PRIMARY_BORDER_ACTIVE {
	id original = %orig;
	id color = getColor(@"BUTTON_OUTLINE_PRIMARY_BORDER_ACTIVE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)MODAL_BACKGROUND {
	id original = %orig;
	id color = getColor(@"MODAL_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)MODAL_FOOTER_BACKGROUND {
	id original = %orig;
	id color = getColor(@"MODAL_FOOTER_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)SCROLLBAR_THIN_THUMB {
	id original = %orig;
	id color = getColor(@"SCROLLBAR_THIN_THUMB");

	if (color) {
		return color;
	}

	return original;
}

+ (id)SCROLLBAR_THIN_TRACK {
	id original = %orig;
	id color = getColor(@"SCROLLBAR_THIN_TRACK");

	if (color) {
		return color;
	}

	return original;
}

+ (id)SCROLLBAR_AUTO_THUMB {
	id original = %orig;
	id color = getColor(@"SCROLLBAR_AUTO_THUMB");

	if (color) {
		return color;
	}

	return original;
}

+ (id)SCROLLBAR_AUTO_TRACK {
	id original = %orig;
	id color = getColor(@"SCROLLBAR_AUTO_TRACK");

	if (color) {
		return color;
	}

	return original;
}

+ (id)SCROLLBAR_AUTO_SCROLLBAR_COLOR_THUMB {
	id original = %orig;
	id color = getColor(@"SCROLLBAR_AUTO_SCROLLBAR_COLOR_THUMB");

	if (color) {
		return color;
	}

	return original;
}

+ (id)SCROLLBAR_AUTO_SCROLLBAR_COLOR_TRACK {
	id original = %orig;
	id color = getColor(@"SCROLLBAR_AUTO_SCROLLBAR_COLOR_TRACK");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INPUT_BACKGROUND {
	id original = %orig;
	id color = getColor(@"INPUT_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)INPUT_PLACEHOLDER_TEXT {
	id original = %orig;
	id color = getColor(@"INPUT_PLACEHOLDER_TEXT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)ELEVATION_STROKE {
	id original = %orig;
	id color = getColor(@"ELEVATION_STROKE");

	if (color) {
		return color;
	}

	return original;
}

+ (id)ELEVATION_LOW {
	id original = %orig;
	id color = getColor(@"ELEVATION_LOW");

	if (color) {
		return color;
	}

	return original;
}

+ (id)ELEVATION_MEDIUM {
	id original = %orig;
	id color = getColor(@"ELEVATION_MEDIUM");

	if (color) {
		return color;
	}

	return original;
}

+ (id)ELEVATION_HIGH {
	id original = %orig;
	id color = getColor(@"ELEVATION_HIGH");

	if (color) {
		return color;
	}

	return original;
}

+ (id)LOGO_PRIMARY {
	id original = %orig;
	id color = getColor(@"LOGO_PRIMARY");

	if (color) {
		return color;
	}

	return original;
}

+ (id)FOCUS_PRIMARY {
	id original = %orig;
	id color = getColor(@"FOCUS_PRIMARY");

	if (color) {
		return color;
	}

	return original;
}

+ (id)CONTROL_BRAND_FOREGROUND {
	id original = %orig;
	id color = getColor(@"CONTROL_BRAND_FOREGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)CONTROL_BRAND_FOREGROUND_NEW {
	id original = %orig;
	id color = getColor(@"CONTROL_BRAND_FOREGROUND_NEW");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_MENTIONED {
	id original = %orig;
	id color = getColor(@"BACKGROUND_MENTIONED");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_MENTIONED_HOVER {
	id original = %orig;
	id color = getColor(@"BACKGROUND_MENTIONED_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_MESSAGE_HOVER {
	id original = %orig;
	id color = getColor(@"BACKGROUND_MESSAGE_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_MESSAGE_AUTOMOD {
	id original = %orig;
	id color = getColor(@"BACKGROUND_MESSAGE_AUTOMOD");

	if (color) {
		return color;
	}

	return original;
}

+ (id)BACKGROUND_MESSAGE_AUTOMOD_HOVER {
	id original = %orig;
	id color = getColor(@"BACKGROUND_MESSAGE_AUTOMOD_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)CHANNELS_DEFAULT {
	id original = %orig;
	id color = getColor(@"CHANNELS_DEFAULT");

	if (color) {
		return color;
	}

	return original;
}

+ (id)CHANNEL_ICON {
	id original = %orig;
	id color = getColor(@"CHANNEL_ICON");

	if (color) {
		return color;
	}

	return original;
}

+ (id)CHANNEL_TEXT_AREA_PLACEHOLDER {
	id original = %orig;
	id color = getColor(@"CHANNEL_TEXT_AREA_PLACEHOLDER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)GUILD_HEADER_TEXT_SHADOW {
	id original = %orig;
	id color = getColor(@"GUILD_HEADER_TEXT_SHADOW");

	if (color) {
		return color;
	}

	return original;
}

+ (id)CHANNELTEXTAREA_BACKGROUND {
	id original = %orig;
	id color = getColor(@"CHANNELTEXTAREA_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)ACTIVITY_CARD_BACKGROUND {
	id original = %orig;
	id color = getColor(@"ACTIVITY_CARD_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)TEXTBOX_MARKDOWN_SYNTAX {
	id original = %orig;
	id color = getColor(@"TEXTBOX_MARKDOWN_SYNTAX");

	if (color) {
		return color;
	}

	return original;
}

+ (id)SPOILER_REVEALED_BACKGROUND {
	id original = %orig;
	id color = getColor(@"SPOILER_REVEALED_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)SPOILER_HIDDEN_BACKGROUND {
	id original = %orig;
	id color = getColor(@"SPOILER_HIDDEN_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)ANDROID_NAVIGATION_BAR_BACKGROUND {
	id original = %orig;
	id color = getColor(@"ANDROID_NAVIGATION_BAR_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)DEPRECATED_CARD_BG {
	id original = %orig;
	id color = getColor(@"DEPRECATED_CARD_BG");

	if (color) {
		return color;
	}

	return original;
}

+ (id)DEPRECATED_CARD_EDITABLE_BG {
	id original = %orig;
	id color = getColor(@"DEPRECATED_CARD_EDITABLE_BG");

	if (color) {
		return color;
	}

	return original;
}

+ (id)DEPRECATED_STORE_BG {
	id original = %orig;
	id color = getColor(@"DEPRECATED_STORE_BG");

	if (color) {
		return color;
	}

	return original;
}

+ (id)DEPRECATED_QUICKSWITCHER_INPUT_BACKGROUND {
	id original = %orig;
	id color = getColor(@"DEPRECATED_QUICKSWITCHER_INPUT_BACKGROUND");

	if (color) {
		return color;
	}

	return original;
}

+ (id)DEPRECATED_QUICKSWITCHER_INPUT_PLACEHOLDER {
	id original = %orig;
	id color = getColor(@"DEPRECATED_QUICKSWITCHER_INPUT_PLACEHOLDER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)DEPRECATED_TEXT_INPUT_BG {
	id original = %orig;
	id color = getColor(@"DEPRECATED_TEXT_INPUT_BG");

	if (color) {
		return color;
	}

	return original;
}

+ (id)DEPRECATED_TEXT_INPUT_BORDER {
	id original = %orig;
	id color = getColor(@"DEPRECATED_TEXT_INPUT_BORDER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)DEPRECATED_TEXT_INPUT_BORDER_HOVER {
	id original = %orig;
	id color = getColor(@"DEPRECATED_TEXT_INPUT_BORDER_HOVER");

	if (color) {
		return color;
	}

	return original;
}

+ (id)DEPRECATED_TEXT_INPUT_BORDER_DISABLED {
	id original = %orig;
	id color = getColor(@"DEPRECATED_TEXT_INPUT_BORDER_DISABLED");

	if (color) {
		return color;
	}

	return original;
}

+ (id)DEPRECATED_TEXT_INPUT_PREFIX {
	id original = %orig;
	id color = getColor(@"DEPRECATED_TEXT_INPUT_PREFIX");

	if (color) {
		return color;
	}

	return original;
}
%end