#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
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

	id chatColor = getColor(@"CHAT_BACKGROUND", @"semantic");

	if (!chatColor) {
		chatColor = getColor(@"BACKGROUND_PRIMARY", @"semantic");
	}

	if (chatColor) {
		[self setBackgroundColor:chatColor];
	}

	if (background == nil) {
		background = getBackgroundMap();
	}

	if (background == nil) {
		NSLog(@"Background is still nil! Background: %@", background);
		return;
	}

	NSString *url = getBackgroundURL();

	int count = [self.subviews count];
	UIView *subview = self.subviews[(count >= 3 && count <= 5) ? 2 : 0];

	if (subview && [subview isKindOfClass:[UIImageView class]]) {
		return NSLog(@"Image is a UIImageView!: %@", (id)[NSNumber numberWithBool:[subview isKindOfClass:[UIImageView class]] ]);
	}

	if (subview && url) {
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

void SwizzleFromDict(NSString *kind, Class class) {   
    NSDictionary *dict = getThemeMap(kind);

    for (NSString *colorName in dict) {
        NSString *originalMethodName = colorName;
        SEL originalSelector = NSSelectorFromString(originalMethodName);
        IMP originalImplementation = method_getImplementation(class_getClassMethod(class, originalSelector));

        // cast the IMP to return an id
        id (*getOriginalColor)(Class, SEL) = (id (*)(Class, SEL))originalImplementation;

        MSHookMessageEx(class, originalSelector, (IMP)imp_implementationWithBlock(^UIColor *(id self) {
            id color = getColor(colorName, kind);

            if (color) {
                return color;
            }

            return getOriginalColor(class, originalSelector);
        }), NULL);
    }
}

%ctor {
	// https://github.com/vendetta-mod/VendettaTweak/blob/rewrite/Sources/VendettaTweak/Themes.x.swift#L61
    SwizzleFromDict(@"semantic", object_getClass(NSClassFromString(@"DCDThemeColor")));
    SwizzleFromDict(@"raw", object_getClass(NSClassFromString(@"UIColor")));
}