#import "Enmity.h"

// Create a response to a command
NSDictionary* createResponse(NSString *uuid, NSString *data) {
  NSDictionary *response = @{
    @"id": uuid,
    @"data": data
  };

  return response;
}

// Send a response back
void sendResponse(NSDictionary *response) {
  NSError *err;
  NSData *data = [NSJSONSerialization
                    dataWithJSONObject:response
                    options:0
                    error:&err];

  if (err) {
    return;
  }

  NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  NSString *responseString = [NSString stringWithFormat: @"%@%@", ENMITY_PROTOCOL, [json stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
  NSURL *url = [NSURL URLWithString:responseString];

  NSLog(@"json: %@", json);

  [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

// Validate that a command is using the Enmity scheme
BOOL validateCommand(NSString *command) {
  BOOL valid = [command containsString:@"enmity"];

  if (!valid) {
    NSLog(@"Invalid protocol");
  }

  return valid;
}

// Clean the received command
NSString* cleanCommand(NSString *command) {
  NSString *json = [[command stringByReplacingOccurrencesOfString:ENMITY_PROTOCOL withString:@""] stringByRemovingPercentEncoding];

  NSLog(@"json payload cleaned: %@", json);

  return json;
}

// Parse the command
NSDictionary* parseCommand(NSString *json) {
  NSURLComponents* components = [[NSURLComponents alloc] initWithString:json];
  NSArray *queryItems = components.queryItems;

  NSMutableDictionary *command = [[NSMutableDictionary alloc] init];

  for (NSURLQueryItem *item in queryItems) {
    if ([item.name isEqualToString:@"id"]) {
      command[@"id"] = item.value;
    }

    if ([item.name isEqualToString:@"command"]) {
      command[@"command"] = item.value;
    }

    if ([item.name isEqualToString:@"params"]) {
      command[@"params"] = [item.value componentsSeparatedByString:@","];
    }
  }

  return [command copy];
}

void handleThemeInstall(NSString *uuid, NSURL *url, BOOL exists, NSString *themeName) {
  BOOL success = installTheme(url);
  if (success) {
    if ([uuid isEqualToString:@"-1"]) return;

    sendResponse(createResponse(uuid, exists ? @"overridden_theme" : @"installed_theme"));
    return;
  }

  if ([uuid isEqualToString:@"-1"]) {
    alert([NSString stringWithFormat:@"An error happened while installing %@.", themeName]);
    return;
  }

  sendResponse(createResponse(uuid, @"fucky_wucky"));
}

// Handle the command
void handleCommand(NSDictionary *command) {
  NSString *name = [command objectForKey:@"command"];
  if (name == nil) {
    return;
  }

  NSString *uuid = [command objectForKey:@"id"];
  NSArray *params = [command objectForKey:@"params"];

  // Install a plugin
  if ([name isEqualToString:@"install-plugin"]) {
    NSURL *url = [NSURL URLWithString:params[0]];
    if (!url || ![[url pathExtension] isEqualToString:@"js"]) {
      return;
    }

    NSString *pluginName = getPluginName(url);
    BOOL exists = checkPlugin(pluginName);
    BOOL success = installPlugin(url);
    if (success) {
      if ([uuid isEqualToString:@"-1"]) {
        alert([NSString stringWithFormat:@"%@ has been installed.", pluginName]);
        return;
      }

      sendResponse(createResponse(uuid, exists ? @"overridden_plugin" : @"installed_plugin"));
      return;
    }

    if ([uuid isEqualToString:@"-1"]) {
      alert([NSString stringWithFormat:@"An error happened while installing %@.", pluginName]);
      return;
    }

    sendResponse(createResponse(uuid, @"fucky_wucky"));

    return;
  }

  if ([name isEqualToString:@"uninstall-plugin"]) {
    NSString *pluginName = params[0];

    BOOL exists = checkPlugin(pluginName);
    if (!exists) {
      sendResponse(createResponse(uuid, [NSString stringWithFormat:@"**%@** isn't currently installed.", pluginName]));
      return;
    }

    BOOL success = deletePlugin(pluginName);
    if (success) {
      sendResponse(createResponse(uuid, [NSString stringWithFormat:@"**%@** has been removed.", pluginName]));
      return;
    }

    sendResponse(createResponse(uuid, [NSString stringWithFormat:@"An error happened while removing *%@*.", pluginName]));
  }

  if ([name isEqualToString:@"install-theme"]) {
    NSURL *url = [NSURL URLWithString:params[0]];
    if (!url || ![[url pathExtension] isEqualToString:@"json"]) {
      return;
    }

    NSString *themeName = getThemeName(url);
    BOOL exists = checkTheme(themeName);
    handleThemeInstall(uuid, url, exists, themeName);
  }

  if ([name isEqualToString:@"uninstall-theme"]) {
    NSString *themeName = params[0];

    BOOL exists = checkTheme(themeName);
    if (!exists) {
      sendResponse(createResponse(uuid, [NSString stringWithFormat:@"**%@** isn't currently installed.", themeName]));
      return;
    }

    BOOL success = uninstallTheme(params[0]);
    if (success) {
      sendResponse(createResponse(uuid, @"Theme has been uninstalled."));
      return;
    }

    sendResponse(createResponse(uuid, @"An error happened while uninstalling the theme."));
  }

  if ([name isEqualToString:@"apply-theme"]) {
    setTheme(params[0], params[1]);
    sendResponse(createResponse(uuid, @"Theme has been applied."));
  }

  if ([name isEqualToString:@"remove-theme"]) {
    setTheme(nil, nil);
    sendResponse(createResponse(uuid, @"Theme has been removed."));
  }

  if ([name isEqualToString:@"enable-plugin"]) {
    BOOL success = enablePlugin(params[0]);
    sendResponse(createResponse(uuid, success ? @"yes" : @"no"));
  }

  if ([name isEqualToString:@"disable-plugin"]) {
    BOOL success = disablePlugin(params[0]);
    sendResponse(createResponse(uuid, success ? @"yes" : @"no"));
  }
}

%hook AppDelegate

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  NSString *input = url.absoluteString;
	if (!validateCommand(input)) {
    %orig;
    return true;
	}

	NSString *json = cleanCommand(input);
  NSDictionary *command = parseCommand(json);
  handleCommand(command);

  return true;
}

%end