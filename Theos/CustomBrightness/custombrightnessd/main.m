#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDEventSystemClient.h>
#import <IOKit/hid/IOHIDEventSystem.h>
#import <notify.h>
#import <syslog.h>
#import <dlfcn.h>
#import <UIKit/UIKit.h>

static NSMutableArray *BrightnessSettings = nil;
static float CurrentBrightness = -1.0f;
BOOL Enabled = NO;
BOOL SafeToRun = YES;
float const CUBAnimationSteps = 30;
float const AnimationSleepDuration = 0.025f;

int displayStatusToken;

void GSEventSetBacklightLevel(float);
void setBacklightLevel(float targetBacklightLevel, float currentBacklightLevel, BOOL animated);

IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
CFArrayRef IOHIDEventSystemClientCopyServices(IOHIDEventSystemClientRef, int);
typedef struct __IOHIDServiceClient * IOHIDServiceClientRef;
int IOHIDServiceClientSetProperty(IOHIDServiceClientRef, CFStringRef, CFNumberRef);

static int (*SBSSpringBoardServerPort)() = 0;
static void (*SBSetCurrentBacklightLevel)(int _port, float level) = 0;

void handle_event(void* target, void* refcon, IOHIDEventQueueRef queue, IOHIDEventRef event) {
    if (!(Enabled && SafeToRun)) {
        return;
    }
    if (IOHIDEventGetType(event)==kIOHIDEventTypeAmbientLightSensor){ // Ambient Light Sensor Event
        
        int luxValue=IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldAmbientLightSensorLevel); // lux Event Field
        
        NSNumber *previousBacklightLevel = [[NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"] objectForKey:@"SBBacklightLevel2"];
        float previousLevel = CurrentBrightness;
        if (![previousBacklightLevel isKindOfClass:[NSNull class]]) {
            previousLevel = [previousBacklightLevel floatValue];

        }

        BOOL foundSetting = NO;

        for (NSDictionary *aSetting in BrightnessSettings) {
            if ([aSetting[@"lux"] intValue] >= luxValue) {
                float brightness = [aSetting[@"screenBrightness"] floatValue];
                    setBacklightLevel(brightness, previousLevel, YES);

                foundSetting = YES;
                break;
            }
        }
        
        if (!foundSetting) {

            setBacklightLevel(0.99f, previousLevel, YES);
        }

    }
}

void setBacklightLevel(float targetBacklightLevel, float currentBacklightLevel, BOOL animated) {
    if (currentBacklightLevel == targetBacklightLevel) {
        return;
    }
    
    int port = SBSSpringBoardServerPort();

    if (animated) {

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

        readSettings();

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
        
        int ri = 3000000;
        CFNumberRef interval = CFNumberCreate(CFAllocatorGetDefault(), kCFNumberIntType, &ri);
        IOHIDServiceClientSetProperty(alssc,CFSTR("ReportInterval"),interval);
        
        int settingsToken;
        notify_register_dispatch("com.laughing-buddha-software.settingsChanged",
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

                                                  if (result != NOTIFY_STATUS_OK) {
                                                      NSLog(@"customBrightnessd: Notify status not OK");
                                                  }
                                              });

        
        IOHIDEventSystemClientScheduleWithRunLoop(s_hidSysC, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        IOHIDEventSystemClientRegisterEventCallback(s_hidSysC, handle_event, NULL, NULL);
        
        CFRunLoopRun();

    }
    
}
