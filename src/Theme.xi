#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "substrate.h"
#import "Enmity.h"
#import "Theme.h"

NSDictionary *semanticColors = nil;
NSDictionary *rawColors = nil;
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

// Check if a theme exists
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
NSDictionary* getThemeMap(NSString *kind) {
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

	// conditions:
	//    kind: semantic/raw
	//	  spec: legacy/updated
	if ([kind isEqual:@"semantic"]) {
		NSDictionary *colorMap = theme[@"semanticColors"] ? theme[@"semanticColors"] : theme[@"theme_color_map"];
		NSMutableDictionary *themeMap = [[NSMutableDictionary alloc] init];
		for (NSString* colorName in colorMap) {
			[themeMap setObject:colorMap[colorName][mode]	forKey: colorName];
		}

		return [themeMap copy];
	}
	
	if ([kind isEqual:@"raw"]) {
		NSDictionary *colorMap = theme[@"rawColors"] ? theme[@"rawColors"] : theme[@"colours"];
		NSMutableDictionary *themeMap = [[NSMutableDictionary alloc] init];
		for (NSString* colorName in colorMap) {
			NSString *color = colorMap[colorName];
			NSString *replacesPrimaryDark = [color stringByReplacingOccurrencesOfString:@"PRIMARY_DARK" withString:@"PRIMARY"];
			NSString *replacesPrimaryLight = [replacesPrimaryDark stringByReplacingOccurrencesOfString:@"PRIMARY_LIGHT" withString:@"PRIMARY"];
			NSString *replacesBrandNew = [replacesPrimaryLight stringByReplacingOccurrencesOfString:@"BRAND_NEW" withString:@"BRAND"];
			NSString *replacesStatus = [replacesBrandNew stringByReplacingOccurrencesOfString:@"STATUS_" withString:@""];
			[themeMap setObject:replacesStatus	forKey: colorName];
		}

		return [themeMap copy];
	}

	return [theme[@"semanticColors"] copy];
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
		semanticColors = [[NSMutableDictionary alloc] init];
		rawColors = [[NSMutableDictionary alloc] init];
		background = [[NSMutableDictionary alloc] init];
		return;
	}

	[userDefaults setObject:name forKey:@"theme"];
	[userDefaults setInteger:[mode intValue] forKey:@"theme_mode"];
	semanticColors = nil;
	rawColors = nil;
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
UIColor* getColor(NSString *name, NSString *kind) {
	if ([kind isEqual:@"semantic"]) {
		if (!semanticColors) {
			semanticColors = getThemeMap(kind);
		}

		if (![semanticColors objectForKey:name]) {
			return NULL;
		}

		NSString *value = semanticColors[name];
		UIColor *color;

		if ([value containsString:@"rgba"]) {
			color = colorFromRGBAString(value);
		} else {
			color = colorFromHexString(value);
		}

		return color;
	}

	if ([kind isEqual:@"raw"]) {
		if (!rawColors) {
			rawColors = getThemeMap(kind);
		}

		if (![rawColors objectForKey:name]) {
			return NULL;
		}

		NSString *value = rawColors[name];
		UIColor *color;

		if ([value containsString:@"rgba"]) {
			color = colorFromRGBAString(value);
		} else {
			color = colorFromHexString(value);
		}

		return color;
	}

	return NULL;
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

		id color = getColor(@"KEYBOARD", @"semantic");
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

		id color = getColor(@"KEYBOARD", @"semantic");
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


		id color = getColor(@"KEYBOARD", @"semantic");
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

		id color = getColor(@"KEYBOARD", @"semantic");
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

	id color = getColor(@"BACKGROUND_SECONDARY_ALT", @"semantic");
	if (color != nil) {
		UIView *subview = self.subviews[0];
		[subview setBackgroundColor:color];
	}
}
%end

HOOK_TABLE_CELL(DCDBaseMessageTableViewCell)
HOOK_TABLE_CELL(DCDSeparatorTableViewCell)
HOOK_TABLE_CELL(DCDBlockedMessageTableViewCell)
HOOK_TABLE_CELL(DCDSystemMessageTableViewCell)
HOOK_TABLE_CELL(DCDLoadingTableViewCell)

@interface DCDChat : UIView
@end

%hook DCDChat
- (void)configureSubviewsWithContentAdjustment:(double)arg1 {
	%orig;

	id chatColor = getColor(@"BACKGROUND_PRIMARY", @"semantic");
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

/**
 * ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
 *
 * UIColor Hooking
 *
 * ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
 */
%hook UIColor

HOOK_COLOR(YELLOW_100, raw)
HOOK_COLOR(YELLOW_130, raw)
HOOK_COLOR(YELLOW_160, raw)
HOOK_COLOR(YELLOW_200, raw)
HOOK_COLOR(YELLOW_230, raw)
HOOK_COLOR(YELLOW_260, raw)
HOOK_COLOR(YELLOW_300, raw)
HOOK_COLOR(YELLOW_345, raw)
HOOK_COLOR(YELLOW_330, raw)
HOOK_COLOR(YELLOW_360, raw)
HOOK_COLOR(YELLOW_400, raw)
HOOK_COLOR(YELLOW_430, raw)
HOOK_COLOR(YELLOW_460, raw)
HOOK_COLOR(YELLOW_500, raw)
HOOK_COLOR(YELLOW_530, raw)
HOOK_COLOR(YELLOW_560, raw)
HOOK_COLOR(YELLOW_600, raw)
HOOK_COLOR(YELLOW_630, raw)
HOOK_COLOR(YELLOW_660, raw)
HOOK_COLOR(YELLOW_700, raw)
HOOK_COLOR(YELLOW_730, raw)
HOOK_COLOR(YELLOW_800, raw)
HOOK_COLOR(YELLOW_830, raw)
HOOK_COLOR(YELLOW_860, raw)
HOOK_COLOR(YELLOW_900, raw)
HOOK_COLOR(RED_100, raw)
HOOK_COLOR(RED_130, raw)
HOOK_COLOR(RED_160, raw)
HOOK_COLOR(RED_200, raw)
HOOK_COLOR(RED_230, raw)
HOOK_COLOR(RED_260, raw)
HOOK_COLOR(RED_300, raw)
HOOK_COLOR(RED_345, raw)
HOOK_COLOR(RED_330, raw)
HOOK_COLOR(RED_360, raw)
HOOK_COLOR(RED_400, raw)
HOOK_COLOR(RED_430, raw)
HOOK_COLOR(RED_460, raw)
HOOK_COLOR(RED_500, raw)
HOOK_COLOR(RED_530, raw)
HOOK_COLOR(RED_560, raw)
HOOK_COLOR(RED_600, raw)
HOOK_COLOR(RED_630, raw)
HOOK_COLOR(RED_660, raw)
HOOK_COLOR(RED_700, raw)
HOOK_COLOR(RED_730, raw)
HOOK_COLOR(RED_800, raw)
HOOK_COLOR(RED_830, raw)
HOOK_COLOR(RED_860, raw)
HOOK_COLOR(RED_900, raw)
HOOK_COLOR(ORANGE_100, raw)
HOOK_COLOR(ORANGE_130, raw)
HOOK_COLOR(ORANGE_160, raw)
HOOK_COLOR(ORANGE_200, raw)
HOOK_COLOR(ORANGE_230, raw)
HOOK_COLOR(ORANGE_260, raw)
HOOK_COLOR(ORANGE_300, raw)
HOOK_COLOR(ORANGE_345, raw)
HOOK_COLOR(ORANGE_330, raw)
HOOK_COLOR(ORANGE_360, raw)
HOOK_COLOR(ORANGE_400, raw)
HOOK_COLOR(ORANGE_430, raw)
HOOK_COLOR(ORANGE_460, raw)
HOOK_COLOR(ORANGE_500, raw)
HOOK_COLOR(ORANGE_530, raw)
HOOK_COLOR(ORANGE_560, raw)
HOOK_COLOR(ORANGE_600, raw)
HOOK_COLOR(ORANGE_630, raw)
HOOK_COLOR(ORANGE_660, raw)
HOOK_COLOR(ORANGE_700, raw)
HOOK_COLOR(ORANGE_730, raw)
HOOK_COLOR(ORANGE_800, raw)
HOOK_COLOR(ORANGE_830, raw)
HOOK_COLOR(ORANGE_860, raw)
HOOK_COLOR(ORANGE_900, raw)
HOOK_COLOR(GREEN_100, raw)
HOOK_COLOR(GREEN_130, raw)
HOOK_COLOR(GREEN_160, raw)
HOOK_COLOR(GREEN_200, raw)
HOOK_COLOR(GREEN_230, raw)
HOOK_COLOR(GREEN_260, raw)
HOOK_COLOR(GREEN_300, raw)
HOOK_COLOR(GREEN_345, raw)
HOOK_COLOR(GREEN_330, raw)
HOOK_COLOR(GREEN_360, raw)
HOOK_COLOR(GREEN_400, raw)
HOOK_COLOR(GREEN_430, raw)
HOOK_COLOR(GREEN_460, raw)
HOOK_COLOR(GREEN_500, raw)
HOOK_COLOR(GREEN_530, raw)
HOOK_COLOR(GREEN_560, raw)
HOOK_COLOR(GREEN_600, raw)
HOOK_COLOR(GREEN_630, raw)
HOOK_COLOR(GREEN_660, raw)
HOOK_COLOR(GREEN_700, raw)
HOOK_COLOR(GREEN_730, raw)
HOOK_COLOR(GREEN_800, raw)
HOOK_COLOR(GREEN_830, raw)
HOOK_COLOR(GREEN_860, raw)
HOOK_COLOR(GREEN_900, raw)
HOOK_COLOR(BLUE_100, raw)
HOOK_COLOR(BLUE_130, raw)
HOOK_COLOR(BLUE_160, raw)
HOOK_COLOR(BLUE_200, raw)
HOOK_COLOR(BLUE_230, raw)
HOOK_COLOR(BLUE_730, raw)
HOOK_COLOR(BLUE_260, raw)
HOOK_COLOR(BLUE_300, raw)
HOOK_COLOR(BLUE_345, raw)
HOOK_COLOR(BLUE_330, raw)
HOOK_COLOR(BLUE_360, raw)
HOOK_COLOR(BLUE_400, raw)
HOOK_COLOR(BLUE_430, raw)
HOOK_COLOR(BLUE_460, raw)
HOOK_COLOR(BLUE_500, raw)
HOOK_COLOR(BLUE_530, raw)
HOOK_COLOR(BLUE_560, raw)
HOOK_COLOR(BLUE_600, raw)
HOOK_COLOR(BLUE_630, raw)
HOOK_COLOR(BLUE_660, raw)
HOOK_COLOR(BLUE_700, raw)
HOOK_COLOR(BLUE_800, raw)
HOOK_COLOR(BLUE_830, raw)
HOOK_COLOR(BLUE_860, raw)
HOOK_COLOR(BLUE_900, raw)
HOOK_COLOR(BRAND_100, raw)
HOOK_COLOR(BRAND_130, raw)
HOOK_COLOR(BRAND_160, raw)
HOOK_COLOR(BRAND_200, raw)
HOOK_COLOR(BRAND_230, raw)
HOOK_COLOR(BRAND_260, raw)
HOOK_COLOR(BRAND_300, raw)
HOOK_COLOR(BRAND_330, raw)
HOOK_COLOR(BRAND_345, raw)
HOOK_COLOR(BRAND_360, raw)
HOOK_COLOR(BRAND_400, raw)
HOOK_COLOR(BRAND_430, raw)
HOOK_COLOR(BRAND_460, raw)
HOOK_COLOR(BRAND_500, raw)
HOOK_COLOR(BRAND_530, raw)
HOOK_COLOR(BRAND_560, raw)
HOOK_COLOR(BRAND_600, raw)
HOOK_COLOR(BRAND_630, raw)
HOOK_COLOR(BRAND_660, raw)
HOOK_COLOR(BRAND_700, raw)
HOOK_COLOR(BRAND_730, raw)
HOOK_COLOR(BRAND_800, raw)
HOOK_COLOR(BRAND_830, raw)
HOOK_COLOR(BRAND_860, raw)
HOOK_COLOR(BRAND_900, raw)
HOOK_COLOR(BRAND, raw)

%end

/**
 * ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
 *
 * DCDThemeColor Hooking
 *
 * ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
 */
%hook DCDThemeColor

HOOK_COLOR(HEADER_PRIMARY, semantic)
HOOK_COLOR(HEADER_SECONDARY, semantic)
HOOK_COLOR(TEXT_NORMAL, semantic)
HOOK_COLOR(TEXT_MUTED, semantic)
HOOK_COLOR(TEXT_LINK, semantic)
HOOK_COLOR(TEXT_LINK_LOW_SATURATION, semantic)
HOOK_COLOR(TEXT_POSITIVE, semantic)
HOOK_COLOR(TEXT_WARNING, semantic)
HOOK_COLOR(TEXT_DANGER, semantic)
HOOK_COLOR(TEXT_BRAND, semantic)
HOOK_COLOR(INTERACTIVE_NORMAL, semantic)
HOOK_COLOR(INTERACTIVE_HOVER, semantic)
HOOK_COLOR(INTERACTIVE_ACTIVE, semantic)
HOOK_COLOR(INTERACTIVE_MUTED, semantic)
HOOK_COLOR(BACKGROUND_PRIMARY, semantic)
HOOK_COLOR(BACKGROUND_SECONDARY, semantic)
HOOK_COLOR(BACKGROUND_SECONDARY_ALT, semantic)
HOOK_COLOR(BACKGROUND_TERTIARY, semantic)
HOOK_COLOR(BACKGROUND_ACCENT, semantic)
HOOK_COLOR(BACKGROUND_FLOATING, semantic)
HOOK_COLOR(BACKGROUND_NESTED_FLOATING, semantic)
HOOK_COLOR(BACKGROUND_MOBILE_PRIMARY, semantic)
HOOK_COLOR(BACKGROUND_MOBILE_SECONDARY, semantic)
HOOK_COLOR(CHAT_BACKGROUND, semantic)
HOOK_COLOR(CHAT_BORDER, semantic)
HOOK_COLOR(CHAT_INPUT_CONTAINER_BACKGROUND, semantic)
HOOK_COLOR(BACKGROUND_MODIFIER_HOVER, semantic)
HOOK_COLOR(BACKGROUND_MODIFIER_ACTIVE, semantic)
HOOK_COLOR(BACKGROUND_MODIFIER_SELECTED, semantic)
HOOK_COLOR(BACKGROUND_MODIFIER_ACCENT, semantic)
HOOK_COLOR(INFO_POSITIVE_BACKGROUND, semantic)
HOOK_COLOR(INFO_POSITIVE_FOREGROUND, semantic)
HOOK_COLOR(INFO_POSITIVE_TEXT, semantic)
HOOK_COLOR(INFO_WARNING_BACKGROUND, semantic)
HOOK_COLOR(INFO_WARNING_FOREGROUND, semantic)
HOOK_COLOR(INFO_WARNING_TEXT, semantic)
HOOK_COLOR(INFO_DANGER_BACKGROUND, semantic)
HOOK_COLOR(INFO_DANGER_FOREGROUND, semantic)
HOOK_COLOR(INFO_DANGER_TEXT, semantic)
HOOK_COLOR(INFO_HELP_BACKGROUND, semantic)
HOOK_COLOR(INFO_HELP_FOREGROUND, semantic)
HOOK_COLOR(INFO_HELP_TEXT, semantic)
HOOK_COLOR(STATUS_POSITIVE_BACKGROUND, semantic)
HOOK_COLOR(STATUS_POSITIVE_TEXT, semantic)
HOOK_COLOR(STATUS_WARNING_BACKGROUND, semantic)
HOOK_COLOR(STATUS_WARNING_TEXT, semantic)
HOOK_COLOR(STATUS_DANGER_BACKGROUND, semantic)
HOOK_COLOR(STATUS_DANGER_TEXT, semantic)
HOOK_COLOR(STATUS_DANGER, semantic)
HOOK_COLOR(STATUS_POSITIVE, semantic)
HOOK_COLOR(STATUS_WARNING, semantic)
HOOK_COLOR(BUTTON_DANGER_BACKGROUND, semantic)
HOOK_COLOR(BUTTON_DANGER_BACKGROUND_HOVER, semantic)
HOOK_COLOR(BUTTON_DANGER_BACKGROUND_ACTIVE, semantic)
HOOK_COLOR(BUTTON_DANGER_BACKGROUND_DISABLED, semantic)
HOOK_COLOR(BUTTON_POSITIVE_BACKGROUND, semantic)
HOOK_COLOR(BUTTON_POSITIVE_BACKGROUND_HOVER, semantic)
HOOK_COLOR(BUTTON_POSITIVE_BACKGROUND_ACTIVE, semantic)
HOOK_COLOR(BUTTON_POSITIVE_BACKGROUND_DISABLED, semantic)
HOOK_COLOR(BUTTON_SECONDARY_BACKGROUND, semantic)
HOOK_COLOR(BUTTON_SECONDARY_BACKGROUND_HOVER, semantic)
HOOK_COLOR(BUTTON_SECONDARY_BACKGROUND_ACTIVE, semantic)
HOOK_COLOR(BUTTON_SECONDARY_BACKGROUND_DISABLED, semantic)
HOOK_COLOR(BUTTON_OUTLINE_DANGER_TEXT, semantic)
HOOK_COLOR(BUTTON_OUTLINE_DANGER_BORDER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_DANGER_BACKGROUND, semantic)
HOOK_COLOR(BUTTON_OUTLINE_DANGER_BACKGROUND_HOVER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_DANGER_TEXT_HOVER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_DANGER_BORDER_HOVER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_DANGER_BACKGROUND_ACTIVE, semantic)
HOOK_COLOR(BUTTON_OUTLINE_DANGER_TEXT_ACTIVE, semantic)
HOOK_COLOR(BUTTON_OUTLINE_DANGER_BORDER_ACTIVE, semantic)
HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_TEXT, semantic)
HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_BORDER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_BACKGROUND, semantic)
HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_BACKGROUND_HOVER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_TEXT_HOVER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_BORDER_HOVER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_BACKGROUND_ACTIVE, semantic)
HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_TEXT_ACTIVE, semantic)
HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_BORDER_ACTIVE, semantic)
HOOK_COLOR(BUTTON_OUTLINE_BRAND_TEXT, semantic)
HOOK_COLOR(BUTTON_OUTLINE_BRAND_BORDER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_BRAND_BACKGROUND, semantic)
HOOK_COLOR(BUTTON_OUTLINE_BRAND_BACKGROUND_HOVER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_BRAND_TEXT_HOVER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_BRAND_BORDER_HOVER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_BRAND_BACKGROUND_ACTIVE, semantic)
HOOK_COLOR(BUTTON_OUTLINE_BRAND_TEXT_ACTIVE, semantic)
HOOK_COLOR(BUTTON_OUTLINE_BRAND_BORDER_ACTIVE, semantic)
HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_TEXT, semantic)
HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_BORDER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_BACKGROUND, semantic)
HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_BACKGROUND_HOVER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_TEXT_HOVER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_BORDER_HOVER, semantic)
HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_BACKGROUND_ACTIVE, semantic)
HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_TEXT_ACTIVE, semantic)
HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_BORDER_ACTIVE, semantic)
HOOK_COLOR(MODAL_BACKGROUND, semantic)
HOOK_COLOR(MODAL_FOOTER_BACKGROUND, semantic)
HOOK_COLOR(SCROLLBAR_THIN_THUMB, semantic)
HOOK_COLOR(SCROLLBAR_THIN_TRACK, semantic)
HOOK_COLOR(SCROLLBAR_AUTO_THUMB, semantic)
HOOK_COLOR(SCROLLBAR_AUTO_TRACK, semantic)
HOOK_COLOR(SCROLLBAR_AUTO_SCROLLBAR_COLOR_THUMB, semantic)
HOOK_COLOR(SCROLLBAR_AUTO_SCROLLBAR_COLOR_TRACK, semantic)
HOOK_COLOR(INPUT_BACKGROUND, semantic)
HOOK_COLOR(INPUT_PLACEHOLDER_TEXT, semantic)
HOOK_COLOR(ELEVATION_STROKE, semantic)
HOOK_COLOR(ELEVATION_LOW, semantic)
HOOK_COLOR(ELEVATION_MEDIUM, semantic)
HOOK_COLOR(ELEVATION_HIGH, semantic)
HOOK_COLOR(LOGO_PRIMARY, semantic)
HOOK_COLOR(FOCUS_PRIMARY, semantic)
HOOK_COLOR(CONTROL_BRAND_FOREGROUND, semantic)
HOOK_COLOR(CONTROL_BRAND_FOREGROUND_NEW, semantic)
HOOK_COLOR(BACKGROUND_MENTIONED, semantic)
HOOK_COLOR(BACKGROUND_MENTIONED_HOVER, semantic)
HOOK_COLOR(BACKGROUND_MESSAGE_HOVER, semantic)
HOOK_COLOR(BACKGROUND_MESSAGE_AUTOMOD, semantic)
HOOK_COLOR(BACKGROUND_MESSAGE_AUTOMOD_HOVER, semantic)
HOOK_COLOR(CHANNELS_DEFAULT, semantic)
HOOK_COLOR(CHANNEL_ICON, semantic)
HOOK_COLOR(CHANNEL_TEXT_AREA_PLACEHOLDER, semantic)
HOOK_COLOR(GUILD_HEADER_TEXT_SHADOW, semantic)
HOOK_COLOR(CHANNELTEXTAREA_BACKGROUND, semantic)
HOOK_COLOR(ACTIVITY_CARD_BACKGROUND, semantic)
HOOK_COLOR(TEXTBOX_MARKDOWN_SYNTAX, semantic)
HOOK_COLOR(SPOILER_REVEALED_BACKGROUND, semantic)
HOOK_COLOR(SPOILER_HIDDEN_BACKGROUND, semantic)
HOOK_COLOR(ANDROID_NAVIGATION_BAR_BACKGROUND, semantic)
HOOK_COLOR(DEPRECATED_CARD_BG, semantic)
HOOK_COLOR(DEPRECATED_CARD_EDITABLE_BG, semantic)
HOOK_COLOR(DEPRECATED_STORE_BG, semantic)
HOOK_COLOR(DEPRECATED_QUICKSWITCHER_INPUT_BACKGROUND, semantic)
HOOK_COLOR(DEPRECATED_QUICKSWITCHER_INPUT_PLACEHOLDER, semantic)
HOOK_COLOR(DEPRECATED_TEXT_INPUT_BG, semantic)
HOOK_COLOR(DEPRECATED_TEXT_INPUT_BORDER, semantic)
HOOK_COLOR(DEPRECATED_TEXT_INPUT_BORDER_HOVER, semantic)
HOOK_COLOR(DEPRECATED_TEXT_INPUT_BORDER_DISABLED, semantic)
HOOK_COLOR(DEPRECATED_TEXT_INPUT_PREFIX, semantic)

%end