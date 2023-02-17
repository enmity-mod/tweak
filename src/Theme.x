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

// This was hell to figure out.
static id HookColor(Class cls, SEL selector, id origColor) {
    NSString *clr = NSStringFromSelector(selector);
    id color = getColor(clr);
    if (color) {
        return color;
    }
    return origColor;
}

/**
 * ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
 *
 * DCDThemeColor Hooking
 *
 * ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
 */
%hook UIColor

+ (id)BRAND_NEW_260 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_300 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_330 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_345 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_360 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_400 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_430 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_460 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_500 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_530 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_560 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_600 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_630 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_660 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_NEW_700 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_260 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_300 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_330 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_345 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_360 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_400 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_430 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_460 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_500 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_530 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_560 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_600 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_630 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_660 { return HookColor(self, _cmd, %orig); }
+ (id)BRAND_700 { return HookColor(self, _cmd, %orig); }

+ (id)BRAND_NEW { return HookColor(self, _cmd, %orig); }
+ (id)BRAND { return HookColor(self, _cmd, %orig); }

+ (id)STATUS_YELLOW { return HookColor(self, _cmd, %orig); }

%end

/**
 * ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
 *
 * DCDThemeColor Hooking
 *
 * ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
 */
%hook DCDThemeColor

+ (id)HEADER_PRIMARY { return HookColor(self, _cmd, %orig); }
+ (id)HEADER_SECONDARY { return HookColor(self, _cmd, %orig); }
+ (id)TEXT_NORMAL { return HookColor(self, _cmd, %orig); }
+ (id)TEXT_MUTED { return HookColor(self, _cmd, %orig); }
+ (id)TEXT_LINK { return HookColor(self, _cmd, %orig); }
+ (id)TEXT_LINK_LOW_SATURATION { return HookColor(self, _cmd, %orig); }
+ (id)TEXT_POSITIVE { return HookColor(self, _cmd, %orig); }
+ (id)TEXT_WARNING { return HookColor(self, _cmd, %orig); }
+ (id)TEXT_DANGER { return HookColor(self, _cmd, %orig); }
+ (id)TEXT_BRAND { return HookColor(self, _cmd, %orig); }
+ (id)INTERACTIVE_NORMAL { return HookColor(self, _cmd, %orig); }
+ (id)INTERACTIVE_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)INTERACTIVE_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)INTERACTIVE_MUTED { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_PRIMARY { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_SECONDARY { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_SECONDARY_ALT { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_TERTIARY { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_ACCENT { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_FLOATING { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_NESTED_FLOATING { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_MOBILE_PRIMARY { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_MOBILE_SECONDARY { return HookColor(self, _cmd, %orig); }
+ (id)CHAT_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)CHAT_BORDER { return HookColor(self, _cmd, %orig); }
+ (id)CHAT_INPUT_CONTAINER_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_MODIFIER_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_MODIFIER_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_MODIFIER_SELECTED { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_MODIFIER_ACCENT { return HookColor(self, _cmd, %orig); }
+ (id)INFO_POSITIVE_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)INFO_POSITIVE_FOREGROUND { return HookColor(self, _cmd, %orig); }
+ (id)INFO_POSITIVE_TEXT { return HookColor(self, _cmd, %orig); }
+ (id)INFO_WARNING_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)INFO_WARNING_FOREGROUND { return HookColor(self, _cmd, %orig); }
+ (id)INFO_WARNING_TEXT { return HookColor(self, _cmd, %orig); }
+ (id)INFO_DANGER_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)INFO_DANGER_FOREGROUND { return HookColor(self, _cmd, %orig); }
+ (id)INFO_DANGER_TEXT { return HookColor(self, _cmd, %orig); }
+ (id)INFO_HELP_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)INFO_HELP_FOREGROUND { return HookColor(self, _cmd, %orig); }
+ (id)INFO_HELP_TEXT { return HookColor(self, _cmd, %orig); }
+ (id)STATUS_POSITIVE_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)STATUS_POSITIVE_TEXT { return HookColor(self, _cmd, %orig); }
+ (id)STATUS_WARNING_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)STATUS_WARNING_TEXT { return HookColor(self, _cmd, %orig); }
+ (id)STATUS_DANGER_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)STATUS_DANGER_TEXT { return HookColor(self, _cmd, %orig); }
+ (id)STATUS_DANGER { return HookColor(self, _cmd, %orig); }
+ (id)STATUS_POSITIVE { return HookColor(self, _cmd, %orig); }
+ (id)STATUS_WARNING { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_DANGER_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_DANGER_BACKGROUND_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_DANGER_BACKGROUND_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_DANGER_BACKGROUND_DISABLED { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_POSITIVE_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_POSITIVE_BACKGROUND_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_POSITIVE_BACKGROUND_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_POSITIVE_BACKGROUND_DISABLED { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_SECONDARY_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_SECONDARY_BACKGROUND_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_SECONDARY_BACKGROUND_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_SECONDARY_BACKGROUND_DISABLED { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_DANGER_TEXT { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_DANGER_BORDER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_DANGER_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_DANGER_BACKGROUND_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_DANGER_TEXT_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_DANGER_BORDER_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_DANGER_BACKGROUND_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_DANGER_TEXT_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_DANGER_BORDER_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_POSITIVE_TEXT { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_POSITIVE_BORDER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_POSITIVE_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_POSITIVE_BACKGROUND_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_POSITIVE_TEXT_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_POSITIVE_BORDER_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_POSITIVE_BACKGROUND_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_POSITIVE_TEXT_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_POSITIVE_BORDER_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_BRAND_TEXT { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_BRAND_BORDER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_BRAND_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_BRAND_BACKGROUND_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_BRAND_TEXT_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_BRAND_BORDER_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_BRAND_BACKGROUND_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_BRAND_TEXT_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_BRAND_BORDER_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_PRIMARY_TEXT { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_PRIMARY_BORDER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_PRIMARY_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_PRIMARY_BACKGROUND_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_PRIMARY_TEXT_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_PRIMARY_BORDER_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_PRIMARY_BACKGROUND_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_PRIMARY_TEXT_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)BUTTON_OUTLINE_PRIMARY_BORDER_ACTIVE { return HookColor(self, _cmd, %orig); }
+ (id)MODAL_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)MODAL_FOOTER_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)SCROLLBAR_THIN_THUMB { return HookColor(self, _cmd, %orig); }
+ (id)SCROLLBAR_THIN_TRACK { return HookColor(self, _cmd, %orig); }
+ (id)SCROLLBAR_AUTO_THUMB { return HookColor(self, _cmd, %orig); }
+ (id)SCROLLBAR_AUTO_TRACK { return HookColor(self, _cmd, %orig); }
+ (id)SCROLLBAR_AUTO_SCROLLBAR_COLOR_THUMB { return HookColor(self, _cmd, %orig); }
+ (id)SCROLLBAR_AUTO_SCROLLBAR_COLOR_TRACK { return HookColor(self, _cmd, %orig); }
+ (id)INPUT_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)INPUT_PLACEHOLDER_TEXT { return HookColor(self, _cmd, %orig); }
+ (id)ELEVATION_STROKE { return HookColor(self, _cmd, %orig); }
+ (id)ELEVATION_LOW { return HookColor(self, _cmd, %orig); }
+ (id)ELEVATION_MEDIUM { return HookColor(self, _cmd, %orig); }
+ (id)ELEVATION_HIGH { return HookColor(self, _cmd, %orig); }
+ (id)LOGO_PRIMARY { return HookColor(self, _cmd, %orig); }
+ (id)FOCUS_PRIMARY { return HookColor(self, _cmd, %orig); }
+ (id)CONTROL_BRAND_FOREGROUND { return HookColor(self, _cmd, %orig); }
+ (id)CONTROL_BRAND_FOREGROUND_NEW { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_MENTIONED { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_MENTIONED_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_MESSAGE_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_MESSAGE_AUTOMOD { return HookColor(self, _cmd, %orig); }
+ (id)BACKGROUND_MESSAGE_AUTOMOD_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)CHANNELS_DEFAULT { return HookColor(self, _cmd, %orig); }
+ (id)CHANNEL_ICON { return HookColor(self, _cmd, %orig); }
+ (id)CHANNEL_TEXT_AREA_PLACEHOLDER { return HookColor(self, _cmd, %orig); }
+ (id)GUILD_HEADER_TEXT_SHADOW { return HookColor(self, _cmd, %orig); }
+ (id)CHANNELTEXTAREA_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)ACTIVITY_CARD_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)TEXTBOX_MARKDOWN_SYNTAX { return HookColor(self, _cmd, %orig); }
+ (id)SPOILER_REVEALED_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)SPOILER_HIDDEN_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)ANDROID_NAVIGATION_BAR_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)DEPRECATED_CARD_BG { return HookColor(self, _cmd, %orig); }
+ (id)DEPRECATED_CARD_EDITABLE_BG { return HookColor(self, _cmd, %orig); }
+ (id)DEPRECATED_STORE_BG { return HookColor(self, _cmd, %orig); }
+ (id)DEPRECATED_QUICKSWITCHER_INPUT_BACKGROUND { return HookColor(self, _cmd, %orig); }
+ (id)DEPRECATED_QUICKSWITCHER_INPUT_PLACEHOLDER { return HookColor(self, _cmd, %orig); }
+ (id)DEPRECATED_TEXT_INPUT_BG { return HookColor(self, _cmd, %orig); }
+ (id)DEPRECATED_TEXT_INPUT_BORDER { return HookColor(self, _cmd, %orig); }
+ (id)DEPRECATED_TEXT_INPUT_BORDER_HOVER { return HookColor(self, _cmd, %orig); }
+ (id)DEPRECATED_TEXT_INPUT_BORDER_DISABLED { return HookColor(self, _cmd, %orig); }
+ (id)DEPRECATED_TEXT_INPUT_PREFIX { return HookColor(self, _cmd, %orig); }

%end