#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDEventSystemClient.h>
#import <IOKit/hid/IOHIDEventSystem.h>
#import <notify.h>
#import <syslog.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

NSString *const CUBAdvancedSettingThresholdKey = @"luxThreshold";
NSString *const CUBAdvancedSettingDisableWhenOverridenKey = @"disableWhenOverriden";
NSString *const CUBAdvancedSettingLinearAdjustmentKey = @"linearAdjustment";
NSString *const CUBAdvancedSettingsPollingIntervalKey = @"pollingInterval";

int const CUBDefaultPollingInterval = 3000000;

static NSMutableArray *BrightnessSettings = nil;
static float CurrentBrightness = -1.0f;

IOHIDEventSystemClientRef eventSystemClient;

BOOL Enabled = NO;
BOOL SafeToRun = YES;
BOOL DisableOnManualOverride = NO;
BOOL ShouldAdjustLinearly = NO;

BOOL callBackRegistered = NO;

float const CUBAnimationSteps = 30;
float const AnimationSleepDuration = 0.025f;

int Threshold = 0;
int PreviousLuxLevel = -1;
int displayStatusToken;
int pollingInterval = CUBDefaultPollingInterval;

void GSEventSetBacklightLevel(float);
void setBacklightLevel(float targetBacklightLevel, float currentBacklightLevel, BOOL animated);
void writeSettings();

IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
CFArrayRef IOHIDEventSystemClientCopyServices(IOHIDEventSystemClientRef, int);
typedef struct __IOHIDServiceClient * IOHIDServiceClientRef;
int IOHIDServiceClientSetProperty(IOHIDServiceClientRef, CFStringRef, CFNumberRef);

IOHIDServiceClientRef alsServiceClent;


static int (*SBSSpringBoardServerPort)() = 0;
static void (*SBSetCurrentBacklightLevel)(int _port, float level) = 0;

void handle_event(void* target, void* refcon, IOHIDEventQueueRef queue, IOHIDEventRef event) {
    if (!(Enabled && SafeToRun)) {
        return;
    }
    if (IOHIDEventGetType(event)==kIOHIDEventTypeAmbientLightSensor){ // Ambient Light Sensor Event
        
        int luxValue=IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldAmbientLightSensorLevel); // lux Event Field
        
        int luxDelta = (luxValue - PreviousLuxLevel);
        if (Threshold > 0) {
            if ((luxDelta * luxDelta) < (Threshold * Threshold)) {
                return;
            }
        }
        
        PreviousLuxLevel = luxValue;
        
        NSNumber *previousBacklightLevel = [[NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"] objectForKey:@"SBBacklightLevel2"];
        float previousLevel = CurrentBrightness;
        if (![previousBacklightLevel isKindOfClass:[NSNull class]]) {
            previousLevel = [previousBacklightLevel floatValue];
            
            if (DisableOnManualOverride) {
                if (CurrentBrightness >= 0.0f && previousLevel != 0) {
                    if (previousLevel != CurrentBrightness) {
                        Enabled = NO;
                        writeSettings();
                        return;
                    }
                }
            }
            
        }

        BOOL foundSetting = NO;
        int previousLuxSetting = 0;
        float minimumBrightness = 0;
        
        for (int count = 0; count != [BrightnessSettings count]; ++count) {
            
            NSDictionary *aSetting = BrightnessSettings[count];
            int currentLuxSetting = [aSetting[@"lux"] intValue];
            float maximumBrightness = [aSetting[@"screenBrightness"] floatValue];

            if (currentLuxSetting >= luxValue) {
                
                float luxSettingDelta = currentLuxSetting - previousLuxSetting;
                
                if (ShouldAdjustLinearly && (luxSettingDelta != 0)) {
                    
                    float targetBrightnessDelta = (maximumBrightness - minimumBrightness) / luxSettingDelta;

                    float brightness = minimumBrightness + (targetBrightnessDelta * (luxValue - previousLuxSetting));

                    setBacklightLevel(brightness, previousLevel, YES);
                    
                } else {
                    float brightness = maximumBrightness;
                    setBacklightLevel(brightness, previousLevel, YES);
                }

                foundSetting = YES;
                break;
            }
            
            previousLuxSetting = currentLuxSetting;
            minimumBrightness = maximumBrightness;
        }
        
        if (!foundSetting) {

            setBacklightLevel(0.99f, previousLevel, YES);
        }

    }
}

void registerALSCallback() {
    
    if (!callBackRegistered) {
        
        int currentPollingInterval = pollingInterval;
        CFNumberRef interval = CFNumberCreate(CFAllocatorGetDefault(), kCFNumberIntType, &currentPollingInterval);
        IOHIDServiceClientSetProperty(alsServiceClent,CFSTR("ReportInterval"),interval);
        
        IOHIDEventSystemClientScheduleWithRunLoop(eventSystemClient, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        IOHIDEventSystemClientRegisterEventCallback(eventSystemClient, handle_event, NULL, NULL);
        
        callBackRegistered = YES;
    }
}

void unregisterALSCallback() {
    if (callBackRegistered) {
        IOHIDEventSystemClientUnscheduleWithRunLoop(eventSystemClient, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        IOHIDEventSystemClientUnregisterEventCallback(eventSystemClient);
        
        callBackRegistered = NO;
    }
}

void setBacklightLevel(float targetBacklightLevel, float currentBacklightLevel, BOOL animated) {
    if (currentBacklightLevel == targetBacklightLevel) {

        return;
    }
    
    int port = SBSSpringBoardServerPort();
    float brightnessDelta = targetBacklightLevel - currentBacklightLevel;
    if (brightnessDelta < 0) {
        brightnessDelta = brightnessDelta * -1;
    }

    if (animated && brightnessDelta > 0.01) {

        float brightnessDelta = (targetBacklightLevel - currentBacklightLevel) / CUBAnimationSteps;
        float brightness = currentBacklightLevel;

        for (int currentStep = 0; currentStep != CUBAnimationSteps; ++currentStep) {
            brightness = brightness + brightnessDelta;
            SBSetCurrentBacklightLevel(port, brightness);
            [NSThread sleepForTimeInterval:AnimationSleepDuration];
        }
    }

    SBSetCurrentBacklightLevel(port, targetBacklightLevel);
    CurrentBrightness = targetBacklightLevel;
}

void readSettings() {
    PreviousLuxLevel = -100;
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.laughing-buddha-software.CustomBrightnessSettings.plist"];
    CurrentBrightness = -1.0f;
    NSArray *array = dictionary[@"brightnessPreferences"];
    if (![array isKindOfClass:[NSNull class]]) {
        BrightnessSettings = [array mutableCopy];
        [BrightnessSettings sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"lux" ascending:YES]]];
    } else {
        BrightnessSettings = nil;
    }

    NSNumber *enabledNumber = dictionary[@"enabled"];
    if (![enabledNumber isKindOfClass:[NSNull class]]) {
        Enabled = [enabledNumber boolValue];
    } else {
        Enabled = NO;
    }
    
    NSNumber *pollingIntervalNumber = dictionary[CUBAdvancedSettingsPollingIntervalKey];
    if (![pollingIntervalNumber isKindOfClass:[NSNull class]] && pollingIntervalNumber != nil) {
        pollingInterval = [pollingIntervalNumber intValue] * 1000000;
    } else {
        pollingInterval = CUBDefaultPollingInterval;
    }
    
    unregisterALSCallback();
    if (Enabled) {
        registerALSCallback();
    }
    
    NSDictionary *advancedSettings = dictionary[@"advanced"];
    if (![advancedSettings isKindOfClass:[NSNull class]] && advancedSettings != nil) {
        
        NSNumber *thresholdNumber = advancedSettings[CUBAdvancedSettingThresholdKey];
        if (![thresholdNumber isKindOfClass:[NSNull class]] && thresholdNumber != nil) {
            Threshold = [thresholdNumber intValue];
        } else {
            Threshold = 0;
        }
        
        NSNumber *disableWhenOverriddenNumber = advancedSettings[CUBAdvancedSettingDisableWhenOverridenKey];
        if (![disableWhenOverriddenNumber isKindOfClass:[NSNull class]] && disableWhenOverriddenNumber != nil) {
            DisableOnManualOverride = [disableWhenOverriddenNumber boolValue];
        } else {
            DisableOnManualOverride = NO;
        }
        
        NSNumber *linearAdjustmentNumber = advancedSettings[CUBAdvancedSettingLinearAdjustmentKey];
        if (![linearAdjustmentNumber isKindOfClass:[NSNull class]] && linearAdjustmentNumber != nil) {
            ShouldAdjustLinearly = [linearAdjustmentNumber boolValue];
        } else {
            ShouldAdjustLinearly = NO;
        }
    } else {
        Threshold = 0;
        DisableOnManualOverride = NO;
        ShouldAdjustLinearly = NO;
    }
    
}

void writeSettings() {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.laughing-buddha-software.CustomBrightnessSettings.plist"];
    dictionary[@"enabled"] = @(Enabled);
    [dictionary writeToFile:@"/var/mobile/Library/Preferences/com.laughing-buddha-software.CustomBrightnessSettings.plist" atomically:YES];
    
    notify_post("com.laughing-buddha-software.customBrightnessd.settingsChanged");
}

int main (int argc, const char * argv[]) {

    @autoreleasepool {
        
        void *uikit = dlopen("/System/Library/Framework/UIKit.framework/UIKit", RTLD_LAZY);
        if (!uikit) {
            NSLog(@"CustomBrightness: Failed to open UIKit framework!");
            return 1;
            
        }
        
        SBSSpringBoardServerPort = (int (*)())dlsym(uikit, "SBSSpringBoardServerPort");
        if (!SBSSpringBoardServerPort) {
            NSLog(@"CustomBrightness: Failed to get SBSSpringBoardServerPort!");
            return 1;
        }
        
        SBSetCurrentBacklightLevel = (void (*)(int,float))dlsym(uikit, "SBSetCurrentBacklightLevel");
        if (!SBSSpringBoardServerPort) {
            NSLog(@"CustomBrightness: Failed to get SBSetCurrentBacklightLevel!");
            return 1;
        }

        int pv1 = 0xff00;
        int pv2 = 4;
        CFNumberRef mVals[2];
        CFStringRef mKeys[2];

        mVals[0] = CFNumberCreate(CFAllocatorGetDefault(), kCFNumberSInt32Type, &pv1);
        mVals[1] = CFNumberCreate(CFAllocatorGetDefault(), kCFNumberSInt32Type, &pv2);
        mKeys[0] = CFStringCreateWithCString(0, "PrimaryUsagePage", 0);
        mKeys[1] = CFStringCreateWithCString(0, "PrimaryUsage", 0);

        CFDictionaryRef matchInfo = CFDictionaryCreate(CFAllocatorGetDefault(),(const void**)mKeys,(const void**)mVals, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
        eventSystemClient = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
        IOHIDEventSystemClientSetMatching(eventSystemClient,matchInfo);
        
        CFArrayRef matchingsrvs = IOHIDEventSystemClientCopyServices(eventSystemClient,0);
        
        if (CFArrayGetCount(matchingsrvs) == 0)
        {
            NSLog(@"AutoBrightness: ALS Not found!");
        }
        
        IOHIDServiceClientRef alssc = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(matchingsrvs, 0);
        alsServiceClent = alssc;
        
        int ri = CUBDefaultPollingInterval;
        CFNumberRef interval = CFNumberCreate(CFAllocatorGetDefault(), kCFNumberIntType, &ri);
        IOHIDServiceClientSetProperty(alssc,CFSTR("ReportInterval"),interval);
        
        int settingsToken;
        notify_register_dispatch("com.laughing-buddha-software.customBrightness.settingsChanged",
                                              &settingsToken,
                                              dispatch_get_main_queue(), ^(int t) {
                                                  
                                                  readSettings();
                                              });
        
        notify_register_dispatch("com.apple.springboard.hasBlankedScreen",
                                              &displayStatusToken,
                                              dispatch_get_main_queue(), ^(int t) {
                                                  uint64_t state;
                                                  int result = notify_get_state(t, &state);
                                                  SafeToRun = (state == 0);

                                                  if (SafeToRun && Enabled) {
                                                      int port = SBSSpringBoardServerPort();
                                                      SBSetCurrentBacklightLevel(port, CurrentBrightness);
                                                  }
                                                  
                                                  if (!Enabled) {
                                                      unregisterALSCallback();
                                                  } else {
                                                      registerALSCallback();
                                                  }

                                                  if (result != NOTIFY_STATUS_OK) {
                                                      NSLog(@"customBrightnessd: Notify status not OK");
                                                  }
                                              });

        readSettings();
        
        CFRunLoopRun();

    }
    
}
