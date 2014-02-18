//
//  RootViewController.m
//  TestBrightness
//
//  Created by Harshad Dange on 04/01/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "CUBHomeViewController.h"
#import "CUBBrightnessSetting.h"
#import <IOKit/hid/IOHIDEventSystemClient.h>
#import <IOKit/hid/IOHIDEventSystem.h>

#import <notify.h>
#import <dlfcn.h>

#import "CUBSavedSettingsViewController.h"
#import "CUBHelpViewController.h"
#import "CUBBorderedButton.h"
#import "CUBAdvancedSettingsViewController.h"

IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
CFArrayRef IOHIDEventSystemClientCopyServices(IOHIDEventSystemClientRef, int);
typedef struct __IOHIDServiceClient * IOHIDServiceClientRef;
int IOHIDServiceClientSetProperty(IOHIDServiceClientRef, CFStringRef, CFNumberRef);

static int (*SBSSpringBoardServerPort)() = 0;
static void (*SBSetCurrentBacklightLevel)(int _port, float level) = 0;


@interface CUBHomeViewController () {
    NSMutableArray *_brightnessSettings;
    UILabel *_luxLabel;
    UISlider *_brightnessSlider;
    UISwitch *_enabledSwitch;
    NSString *_settingsFilePath;
    BOOL _enabled;
    NSDictionary *_advancedSettings;
}

- (void)sliderValueChanged:(UISlider *)slider;
- (void)touchSave:(UIBarButtonItem *)barButton;
- (void)touchApply:(UIButton *)aButton;
- (void)toggleEnabled:(UISwitch *)aSwitch;
- (void)touchViewCurrentSettings:(UIButton *)aButton;
- (void)touchRestart:(UIButton *)aButton;
- (void)touchHelp:(UIBarButtonItem *)barButton;
- (void)touchSettings:(UIBarButtonItem *)barButton;

@end

@implementation CUBHomeViewController

- (NSString *)settingsFilePath {
    
    if (_settingsFilePath != nil) {
        return _settingsFilePath;
    }
    _settingsFilePath = @"/var/mobile/Library/Preferences/com.laughing-buddha-software.CustomBrightnessSettings.plist";

    return _settingsFilePath;
}

- (void)saveCurrentSettings {
    NSMutableArray *serializedRanges = [[NSMutableArray alloc] initWithCapacity:[_brightnessSettings count]];
    for (CUBBrightnessSetting *aLuxRange in _brightnessSettings) {
        [serializedRanges addObject:[aLuxRange toDictionary]];
    }
    
    if (serializedRanges == nil) {
        serializedRanges = [NSMutableArray new];
    }
    
    if (_advancedSettings == nil) {
        _advancedSettings = [NSDictionary new];
    }
    
    NSDictionary *settingsDictionary = @{@"enabled" : @(_enabled), @"brightnessPreferences" : serializedRanges, @"advanced" : _advancedSettings};
    
    [settingsDictionary writeToFile:[self settingsFilePath] atomically:YES];
    
    notify_post("com.laughing-buddha-software.customBrightness.settingsChanged");
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    void *uikit = dlopen("/System/Library/Framework/UIKit.framework/UIKit", RTLD_LAZY);
	if (!uikit)
	{
		NSLog(@"AutoBrightness: Failed to open UIKit framework!");

	}
    
	SBSSpringBoardServerPort = (int (*)())dlsym(uikit, "SBSSpringBoardServerPort");
	if (!SBSSpringBoardServerPort)
	{
		NSLog(@"AutoBrightness: Failed to get SBSSpringBoardServerPort!");

	}
    
	SBSetCurrentBacklightLevel = (void (*)(int,float))dlsym(uikit, "SBSetCurrentBacklightLevel");
	if (!SBSSpringBoardServerPort)
	{
		NSLog(@"AutoBrightness: Failed to get SBSetCurrentBacklightLevel!");

	}

    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[self settingsFilePath]];
    NSArray *array = dictionary[@"brightnessPreferences"];
    _brightnessSettings = [NSMutableArray new];
    if (![array isKindOfClass:[NSNull class]]) {
        for (NSDictionary *aSettingDictionary in array) {
            CUBBrightnessSetting *brightnessSetting = [[CUBBrightnessSetting alloc] initWithDictionary:aSettingDictionary];
            [_brightnessSettings addObject:brightnessSetting];
        }
    }
    
    NSNumber *enabledNumber = dictionary[@"enabled"];
    if (![enabledNumber isKindOfClass:[NSNull class]]) {
        _enabled = [enabledNumber boolValue];
    } else {
        _enabled = NO;
    }
    
    NSDictionary *advancedSettings = dictionary[@"advanced"];
    if (![advancedSettings isKindOfClass:[NSNull class]] && advancedSettings != nil) {
        _advancedSettings = advancedSettings;
    } else {
        _advancedSettings = [NSDictionary new];
    }
    
    UIBarButtonItem *viewSettingsButton = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(touchSettings:)];
    [self.navigationItem setRightBarButtonItem:viewSettingsButton];
    
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"?" style:UIBarButtonItemStylePlain target:self action:@selector(touchHelp:)];
    [self.navigationItem setLeftBarButtonItem:helpButton];
    
    [self setTitle:@"CustomBrightness"];
    
    UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 70, 300, 80)];
    [descriptionLabel setNumberOfLines:0];
    [descriptionLabel setTextAlignment:NSTextAlignmentCenter];
    [descriptionLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [self.view addSubview:descriptionLabel];
    [descriptionLabel setText:@"Use the slider to adjust the brightness for the current ambient light\nPress Save to save the setting\nPress Apply to apply your settings"];
    
    UILabel *lux = [[UILabel alloc] initWithFrame:CGRectMake(20, 160, 200, 40)];
    [lux setText:@"Ambient Light (lux): "];
    [self.view addSubview:lux];
    
    UILabel *luxLabel = [[UILabel alloc] initWithFrame:CGRectMake(180, 160, 200, 40)];
    [luxLabel setText:@""];
    [self.view addSubview:luxLabel];
    _luxLabel = luxLabel;
    
    UISlider *brightnessSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 200, 280, 50)];
    [brightnessSlider setContinuous:YES];
    [self.view addSubview:brightnessSlider];
    [brightnessSlider setMinimumValue:0.0f];
    [brightnessSlider setMaximumValue:1.0f];
    [brightnessSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    _brightnessSlider = brightnessSlider;
    
    void (^ addButton)(CGRect, NSString *, UIColor *, SEL) = ^(CGRect frame, NSString *title, UIColor *highlightColor, SEL action) {
        CUBBorderedButton *aButton = [[CUBBorderedButton alloc] initWithFrame:frame highlightColor:highlightColor];
        [aButton setTitle:title forState:UIControlStateNormal];
        [aButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:aButton];
    };
    
    addButton(CGRectMake(100, 260, 120, 40), @"Save", [UIColor colorWithRed:0.14f green:0.65f blue:0.97f alpha:1.00f], @selector(touchSave:));
    addButton(CGRectMake(100, 320, 120, 40), @"Edit", [UIColor colorWithRed:0.14f green:0.65f blue:0.97f alpha:1.00f], @selector(touchViewCurrentSettings:));
    addButton(CGRectMake(100, 380, 120, 40), @"Apply", [UIColor colorWithRed:0.47f green:0.81f blue:0.21f alpha:1.00f], @selector(touchApply:));

    
    [self registerForALSEvents];
    
    UILabel *enabledLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height - 60, 200, 30)];
    [enabledLabel setBackgroundColor:[UIColor clearColor]];
    [enabledLabel setText:@"Enabled"];
    [enabledLabel setAutoresizingMask:(UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin)];
    [self.view addSubview:enabledLabel];
    
    UISwitch *enabledSwitch = [[UISwitch alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 70), enabledLabel.frame.origin.y, 50, 50)];
    [self.view addSubview:enabledSwitch];
    [enabledSwitch setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin)];
    _enabledSwitch = enabledSwitch;
    [_enabledSwitch addTarget:self action:@selector(toggleEnabled:) forControlEvents:UIControlEventValueChanged];
    [_enabledSwitch setOn:_enabled];
    
    
    int settingsToken;
    notify_register_dispatch("com.laughing-buddha-software.customBrightnessd.settingsChanged",
                             &settingsToken,
                             dispatch_get_main_queue(), ^(int t) {
                                 
                                 NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[self settingsFilePath]];
                                 NSNumber *enabledNumber = dictionary[@"enabled"];
                                 if (![enabledNumber isKindOfClass:[NSNull class]] && enabledNumber != nil) {
                                     _enabled = [enabledNumber boolValue];
                                 } else {
                                     _enabled = NO;
                                 }
                                 
                                 [_enabledSwitch setOn:_enabled animated:YES];
                             });
}

void handle_event(void* target, void* refcon, IOHIDEventQueueRef queue, IOHIDEventRef event) {
    if (IOHIDEventGetType(event)==kIOHIDEventTypeAmbientLightSensor){ // Ambient Light Sensor Event

        int luxValue=IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldAmbientLightSensorLevel); // lux Event Field
        
        if (refcon != NULL) {
            CUBHomeViewController *rootController = (__bridge CUBHomeViewController *)refcon;
            [rootController updateLuxLabel:luxValue];
            refcon = NULL;
        }
    }
}

- (void)updateLuxLabel:(int)luxValue {
    [_luxLabel setText:[NSString stringWithFormat:@"%d", luxValue]];
}

- (void)registerForALSEvents {
    int pv1 = 0xff00;
    int pv2 = 4;
    CFNumberRef mVals[2];
    CFStringRef mKeys[2];
    
    mVals[0] = CFNumberCreate(CFAllocatorGetDefault(), kCFNumberSInt32Type, &pv1);
    mVals[1] = CFNumberCreate(CFAllocatorGetDefault(), kCFNumberSInt32Type, &pv2);
    mKeys[0] = CFStringCreateWithCString(0, "PrimaryUsagePage", 0);
    mKeys[1] = CFStringCreateWithCString(0, "PrimaryUsage", 0);
    
    CFDictionaryRef matchInfo = CFDictionaryCreate(CFAllocatorGetDefault(),(const void**)mKeys,(const void**)mVals, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    IOHIDEventSystemClientRef s_hidSysC = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    IOHIDEventSystemClientSetMatching(s_hidSysC,matchInfo);
    
    CFArrayRef matchingsrvs = IOHIDEventSystemClientCopyServices(s_hidSysC,0);
    
    if (CFArrayGetCount(matchingsrvs) == 0)
    {
        NSLog(@"AutoBrightness: ALS Not found!");
    }
    
    
    IOHIDServiceClientRef alssc = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(matchingsrvs, 0);
    
    int ri = 1 * 1000000;
    CFNumberRef interval = CFNumberCreate(CFAllocatorGetDefault(), kCFNumberIntType, &ri);
    IOHIDServiceClientSetProperty(alssc,CFSTR("ReportInterval"),interval);

    IOHIDEventSystemClientScheduleWithRunLoop(s_hidSysC, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOHIDEventSystemClientRegisterEventCallback(s_hidSysC, handle_event, NULL, (void *)CFBridgingRetain(self));
}

- (void)sliderValueChanged:(UISlider *)slider {
//    GSEventSetBacklightLevel(slider.value);
    int port = SBSSpringBoardServerPort();
    SBSetCurrentBacklightLevel(port, [slider value]);
}

- (void)touchSave:(UIBarButtonItem *)barButton {
    CUBBrightnessSetting *luxRange = [[CUBBrightnessSetting alloc] initWithLux:[_luxLabel.text intValue] screenBrightness:[_brightnessSlider value]];
    [_brightnessSettings addObject:luxRange];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"lux" ascending:YES];
    [_brightnessSettings sortUsingDescriptors:@[sortDescriptor]];
    
    [self saveCurrentSettings];
}

- (void)touchViewCurrentSettings:(UIButton *)aButton {
    CUBSavedSettingsViewController *aDetailViewController = [[CUBSavedSettingsViewController alloc] initWithSavedPreferences:_brightnessSettings];
    [self.navigationController pushViewController:aDetailViewController animated:YES];
}

- (void)touchApply:(UIButton *)aButton {
    _enabled = YES;
    [self saveCurrentSettings];
    [_enabledSwitch setOn:YES animated:YES];
}

- (void)toggleEnabled:(UISwitch *)aSwitch {
    _enabled = [aSwitch isOn];
    [self saveCurrentSettings];
}

- (void)touchRestart:(UIButton *)aButton {
    [_brightnessSettings removeAllObjects];
    [[NSFileManager defaultManager] removeItemAtPath:[self settingsFilePath] error:nil];
}

- (void)touchHelp:(UIBarButtonItem *)barButton {
    CUBHelpViewController *helpVC = [[CUBHelpViewController alloc] init];
    [self.navigationController pushViewController:helpVC animated:YES];
}

- (void)touchSettings:(UIBarButtonItem *)barButton {
    CUBAdvancedSettingsViewController *advancedSettingsViewController = [[CUBAdvancedSettingsViewController alloc] initWithDelegate:self];
    [self.navigationController pushViewController:advancedSettingsViewController animated:YES];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Advanced settings

- (NSDictionary *)savedSettings {
    return _advancedSettings;
}

- (void)advancedSettingsViewController:(CUBAdvancedSettingsViewController *)viewController didUpdateSettings:(NSDictionary *)settings {
    _advancedSettings = settings;
    [self saveCurrentSettings];
}

@end
