#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import <notify.h>

@interface CustomBrightnessSwitch : NSObject <FSSwitchDataSource>
@end

@implementation CustomBrightnessSwitch

- (NSDictionary *)settingsDictionary {
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.laughing-buddha-software.CustomBrightnessSettings.plist"];
    
    return dictionary;
}

- (void)writeSettings:(NSDictionary *)settings {
    [settings writeToFile:@"/var/mobile/Library/Preferences/com.laughing-buddha-software.CustomBrightnessSettings.plist" atomically:YES];
    notify_post("com.laughing-buddha-software.customBrightness.settingsChanged");
    notify_post("com.laughing-buddha-software.customBrightnessd.settingsChanged");
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
    FSSwitchState state = FSSwitchStateOff;
    NSDictionary *settings = [self settingsDictionary];
    NSNumber *enabled = settings[@"enabled"];
    if (![enabled isKindOfClass:[NSNull class]] && enabled != nil) {
        if ([enabled boolValue]) {
            state = FSSwitchStateOn;
        }
    }
	return state;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
    if (newState != FSSwitchStateIndeterminate) {
        NSMutableDictionary *settings = [[self settingsDictionary] mutableCopy];
        switch (newState) {
            case FSSwitchStateOff:
                settings[@"enabled"] = @(NO);
                break;
                
            case FSSwitchStateOn:
                settings[@"enabled"] = @(YES);
                break;
                
            default:
                break;
        }
        
        [self writeSettings:settings];
    }
}

- (NSString *)titleForSwitchIdentifier:(NSString *)switchIdentifier {
    return @"CustomBrightness";
}

@end