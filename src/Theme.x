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

%hook UIColor

+ (void)load {
    SEL sel;
    IMP imp = (IMP)&HookColor;

	#define HOOK_COLOR(clr) \
		sel = NSSelectorFromString(@#clr); \
		if (![self respondsToSelector:sel]) { \
			class_addMethod(self, sel, imp, "@@:"); \
		}

	HOOK_COLOR(BRAND_NEW_260)
	HOOK_COLOR(BRAND_NEW_300)
	HOOK_COLOR(BRAND_NEW_330)
	HOOK_COLOR(BRAND_NEW_345)
	HOOK_COLOR(BRAND_NEW_360)
	HOOK_COLOR(BRAND_NEW_400)
	HOOK_COLOR(BRAND_NEW_430)
	HOOK_COLOR(BRAND_NEW_460)
	HOOK_COLOR(BRAND_NEW_500)
	HOOK_COLOR(BRAND_NEW_530)
	HOOK_COLOR(BRAND_NEW_560)
	HOOK_COLOR(BRAND_NEW_600)
	HOOK_COLOR(BRAND_NEW_630)
	HOOK_COLOR(BRAND_NEW_660)
	HOOK_COLOR(BRAND_NEW_700)
	HOOK_COLOR(BRAND_260)
	HOOK_COLOR(BRAND_300)
	HOOK_COLOR(BRAND_330)
	HOOK_COLOR(BRAND_345)
	HOOK_COLOR(BRAND_360)
	HOOK_COLOR(BRAND_400)
	HOOK_COLOR(BRAND_430)
	HOOK_COLOR(BRAND_460)
	HOOK_COLOR(BRAND_500)
	HOOK_COLOR(BRAND_530)
	HOOK_COLOR(BRAND_560)
	HOOK_COLOR(BRAND_600)
	HOOK_COLOR(BRAND_630)
	HOOK_COLOR(BRAND_660)
	HOOK_COLOR(BRAND_700)

	HOOK_COLOR(BRAND_NEW)
	HOOK_COLOR(BRAND)

	HOOK_COLOR(STATUS_YELLOW)

	#undef HOOK_COLOR
}

%end

%hook DCDThemeColor

+ (void)load {
    SEL sel;
    IMP imp = (IMP)&HookColor;

	#define HOOK_COLOR(clr) \
		sel = NSSelectorFromString(@#clr); \
		if (![self respondsToSelector:sel]) { \
			class_addMethod(self, sel, imp, "@@:"); \
		}

	HOOK_COLOR(HEADER_PRIMARY)
	HOOK_COLOR(HEADER_SECONDARY)
	HOOK_COLOR(TEXT_NORMAL)
	HOOK_COLOR(TEXT_MUTED)
	HOOK_COLOR(TEXT_LINK)
	HOOK_COLOR(TEXT_LINK_LOW_SATURATION)
	HOOK_COLOR(TEXT_POSITIVE)
	HOOK_COLOR(TEXT_WARNING)
	HOOK_COLOR(TEXT_DANGER)
	HOOK_COLOR(TEXT_BRAND)
	HOOK_COLOR(INTERACTIVE_NORMAL)
	HOOK_COLOR(INTERACTIVE_HOVER)
	HOOK_COLOR(INTERACTIVE_ACTIVE)
	HOOK_COLOR(INTERACTIVE_MUTED)
	HOOK_COLOR(BACKGROUND_PRIMARY)
	HOOK_COLOR(BACKGROUND_SECONDARY)
	HOOK_COLOR(BACKGROUND_SECONDARY_ALT)
	HOOK_COLOR(BACKGROUND_TERTIARY)
	HOOK_COLOR(BACKGROUND_ACCENT)
	HOOK_COLOR(BACKGROUND_FLOATING)
	HOOK_COLOR(BACKGROUND_NESTED_FLOATING)
	HOOK_COLOR(BACKGROUND_MOBILE_PRIMARY)
	HOOK_COLOR(BACKGROUND_MOBILE_SECONDARY)
	HOOK_COLOR(CHAT_BACKGROUND)
	HOOK_COLOR(CHAT_BORDER)
	HOOK_COLOR(CHAT_INPUT_CONTAINER_BACKGROUND)
	HOOK_COLOR(BACKGROUND_MODIFIER_HOVER)
	HOOK_COLOR(BACKGROUND_MODIFIER_ACTIVE)
	HOOK_COLOR(BACKGROUND_MODIFIER_SELECTED)
	HOOK_COLOR(BACKGROUND_MODIFIER_ACCENT)
	HOOK_COLOR(INFO_POSITIVE_BACKGROUND)
	HOOK_COLOR(INFO_POSITIVE_FOREGROUND)
	HOOK_COLOR(INFO_POSITIVE_TEXT)
	HOOK_COLOR(INFO_WARNING_BACKGROUND)
	HOOK_COLOR(INFO_WARNING_FOREGROUND)
	HOOK_COLOR(INFO_WARNING_TEXT)
	HOOK_COLOR(INFO_DANGER_BACKGROUND)
	HOOK_COLOR(INFO_DANGER_FOREGROUND)
	HOOK_COLOR(INFO_DANGER_TEXT)
	HOOK_COLOR(INFO_HELP_BACKGROUND)
	HOOK_COLOR(INFO_HELP_FOREGROUND)
	HOOK_COLOR(INFO_HELP_TEXT)
	HOOK_COLOR(STATUS_POSITIVE_BACKGROUND)
	HOOK_COLOR(STATUS_POSITIVE_TEXT)
	HOOK_COLOR(STATUS_WARNING_BACKGROUND)
	HOOK_COLOR(STATUS_WARNING_TEXT)
	HOOK_COLOR(STATUS_DANGER_BACKGROUND)
	HOOK_COLOR(STATUS_DANGER_TEXT)
	HOOK_COLOR(STATUS_DANGER)
	HOOK_COLOR(STATUS_POSITIVE)
	HOOK_COLOR(STATUS_WARNING)
	HOOK_COLOR(BUTTON_DANGER_BACKGROUND)
	HOOK_COLOR(BUTTON_DANGER_BACKGROUND_HOVER)
	HOOK_COLOR(BUTTON_DANGER_BACKGROUND_ACTIVE)
	HOOK_COLOR(BUTTON_DANGER_BACKGROUND_DISABLED)
	HOOK_COLOR(BUTTON_POSITIVE_BACKGROUND)
	HOOK_COLOR(BUTTON_POSITIVE_BACKGROUND_HOVER)
	HOOK_COLOR(BUTTON_POSITIVE_BACKGROUND_ACTIVE)
	HOOK_COLOR(BUTTON_POSITIVE_BACKGROUND_DISABLED)
	HOOK_COLOR(BUTTON_SECONDARY_BACKGROUND)
	HOOK_COLOR(BUTTON_SECONDARY_BACKGROUND_HOVER)
	HOOK_COLOR(BUTTON_SECONDARY_BACKGROUND_ACTIVE)
	HOOK_COLOR(BUTTON_SECONDARY_BACKGROUND_DISABLED)
	HOOK_COLOR(BUTTON_OUTLINE_DANGER_TEXT)
	HOOK_COLOR(BUTTON_OUTLINE_DANGER_BORDER)
	HOOK_COLOR(BUTTON_OUTLINE_DANGER_BACKGROUND)
	HOOK_COLOR(BUTTON_OUTLINE_DANGER_BACKGROUND_HOVER)
	HOOK_COLOR(BUTTON_OUTLINE_DANGER_TEXT_HOVER)
	HOOK_COLOR(BUTTON_OUTLINE_DANGER_BORDER_HOVER)
	HOOK_COLOR(BUTTON_OUTLINE_DANGER_BACKGROUND_ACTIVE)
	HOOK_COLOR(BUTTON_OUTLINE_DANGER_TEXT_ACTIVE)
	HOOK_COLOR(BUTTON_OUTLINE_DANGER_BORDER_ACTIVE)
	HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_TEXT)
	HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_BORDER)
	HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_BACKGROUND)
	HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_BACKGROUND_HOVER)
	HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_TEXT_HOVER)
	HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_BORDER_HOVER)
	HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_BACKGROUND_ACTIVE)
	HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_TEXT_ACTIVE)
	HOOK_COLOR(BUTTON_OUTLINE_POSITIVE_BORDER_ACTIVE)
	HOOK_COLOR(BUTTON_OUTLINE_BRAND_TEXT)
	HOOK_COLOR(BUTTON_OUTLINE_BRAND_BORDER)
	HOOK_COLOR(BUTTON_OUTLINE_BRAND_BACKGROUND)
	HOOK_COLOR(BUTTON_OUTLINE_BRAND_BACKGROUND_HOVER)
	HOOK_COLOR(BUTTON_OUTLINE_BRAND_TEXT_HOVER)
	HOOK_COLOR(BUTTON_OUTLINE_BRAND_BORDER_HOVER)
	HOOK_COLOR(BUTTON_OUTLINE_BRAND_BACKGROUND_ACTIVE)
	HOOK_COLOR(BUTTON_OUTLINE_BRAND_TEXT_ACTIVE)
	HOOK_COLOR(BUTTON_OUTLINE_BRAND_BORDER_ACTIVE)
	HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_TEXT)
	HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_BORDER)
	HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_BACKGROUND)
	HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_BACKGROUND_HOVER)
	HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_TEXT_HOVER)
	HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_BORDER_HOVER)
	HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_BACKGROUND_ACTIVE)
	HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_TEXT_ACTIVE)
	HOOK_COLOR(BUTTON_OUTLINE_PRIMARY_BORDER_ACTIVE)
	HOOK_COLOR(MODAL_BACKGROUND)
	HOOK_COLOR(MODAL_FOOTER_BACKGROUND)
	HOOK_COLOR(SCROLLBAR_THIN_THUMB)
	HOOK_COLOR(SCROLLBAR_THIN_TRACK)
	HOOK_COLOR(SCROLLBAR_AUTO_THUMB)
	HOOK_COLOR(SCROLLBAR_AUTO_TRACK)
	HOOK_COLOR(SCROLLBAR_AUTO_SCROLLBAR_COLOR_THUMB)
	HOOK_COLOR(SCROLLBAR_AUTO_SCROLLBAR_COLOR_TRACK)
	HOOK_COLOR(INPUT_BACKGROUND)
	HOOK_COLOR(INPUT_PLACEHOLDER_TEXT)
	HOOK_COLOR(ELEVATION_STROKE)
	HOOK_COLOR(ELEVATION_LOW)
	HOOK_COLOR(ELEVATION_MEDIUM)
	HOOK_COLOR(ELEVATION_HIGH)
	HOOK_COLOR(LOGO_PRIMARY)
	HOOK_COLOR(FOCUS_PRIMARY)
	HOOK_COLOR(CONTROL_BRAND_FOREGROUND)
	HOOK_COLOR(CONTROL_BRAND_FOREGROUND_NEW)
	HOOK_COLOR(BACKGROUND_MENTIONED)
	HOOK_COLOR(BACKGROUND_MENTIONED_HOVER)
	HOOK_COLOR(BACKGROUND_MESSAGE_HOVER)
	HOOK_COLOR(BACKGROUND_MESSAGE_AUTOMOD)
	HOOK_COLOR(BACKGROUND_MESSAGE_AUTOMOD_HOVER)
	HOOK_COLOR(CHANNELS_DEFAULT)
	HOOK_COLOR(CHANNEL_ICON)
	HOOK_COLOR(CHANNEL_TEXT_AREA_PLACEHOLDER)
	HOOK_COLOR(GUILD_HEADER_TEXT_SHADOW)
	HOOK_COLOR(CHANNELTEXTAREA_BACKGROUND)
	HOOK_COLOR(ACTIVITY_CARD_BACKGROUND)
	HOOK_COLOR(TEXTBOX_MARKDOWN_SYNTAX)
	HOOK_COLOR(SPOILER_REVEALED_BACKGROUND)
	HOOK_COLOR(SPOILER_HIDDEN_BACKGROUND)
	HOOK_COLOR(ANDROID_NAVIGATION_BAR_BACKGROUND)
	HOOK_COLOR(DEPRECATED_CARD_BG)
	HOOK_COLOR(DEPRECATED_CARD_EDITABLE_BG)
	HOOK_COLOR(DEPRECATED_STORE_BG)
	HOOK_COLOR(DEPRECATED_QUICKSWITCHER_INPUT_BACKGROUND)
	HOOK_COLOR(DEPRECATED_QUICKSWITCHER_INPUT_PLACEHOLDER)
	HOOK_COLOR(DEPRECATED_TEXT_INPUT_BG)
	HOOK_COLOR(DEPRECATED_TEXT_INPUT_BORDER)
	HOOK_COLOR(DEPRECATED_TEXT_INPUT_BORDER_HOVER)
	HOOK_COLOR(DEPRECATED_TEXT_INPUT_BORDER_DISABLED)
	HOOK_COLOR(DEPRECATED_TEXT_INPUT_PREFIX)

	#undef HOOK_COLOR
}

%end