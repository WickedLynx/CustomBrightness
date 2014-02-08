//
//  CUBAdvancedSettingsViewController.m
//  CustomBrightness
//
//  Created by Harshad Dange on 06/02/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import "CUBAdvancedSettingsViewController.h"

NSString *const CUBAdvancedSettingThresholdKey = @"luxThreshold";
NSString *const CUBAdvancedSettingDisableWhenOverridenKey = @"disableWhenOverriden";

@interface CUBAdvancedSettingsViewController () {
    NSMutableDictionary *_settings;
    UILabel *_thresholdLabel;
}

- (void)thresholdSliderValueChanged:(UISlider *)slider;
- (void)toggleDisableWhenOverriden:(UISwitch *)aSwitch;
- (void)touchDone;
- (void)updateThresholdLabel:(int)lux;

@end

@implementation CUBAdvancedSettingsViewController

- (instancetype)initWithDelegate:(id<CUBAdvancedSettingsViewControllerDelegate>)delegate {
    
    self = [super init];
    if (self != nil) {
        
        [self setDelegate:delegate];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self setTitle:@"Advanced"];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UILabel *manualOverrideLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 200, 30)];
    [manualOverrideLabel setText:@"Disable if manually changed"];
    [manualOverrideLabel setAdjustsFontSizeToFitWidth:YES];
    [self.view addSubview:manualOverrideLabel];
    
    UISwitch *manualOverrideSwitch = [[UISwitch alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 70), manualOverrideLabel.frame.origin.y, 50, 50)];
    [manualOverrideSwitch setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin)];
    [manualOverrideSwitch addTarget:self action:@selector(toggleDisableWhenOverriden:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:manualOverrideSwitch];
    
    
    UILabel *thresholdLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, manualOverrideSwitch.frame.origin.y + manualOverrideSwitch.bounds.size.height + 30, self.view.bounds.size.width - 40, 40)];
    [thresholdLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [thresholdLabel setNumberOfLines:2];
    [self.view addSubview:thresholdLabel];
    _thresholdLabel = thresholdLabel;
    
    UISlider *thresholdSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, thresholdLabel.frame.origin.y + thresholdLabel.bounds.size.height + 5, self.view.bounds.size.width - 40, 50)];
    [thresholdSlider setContinuous:YES];
    [thresholdSlider setMinimumValue:0.0f];
    [thresholdSlider setMaximumValue:10.0f];
    [thresholdSlider addTarget:self action:@selector(thresholdSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:thresholdSlider];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(touchDone)];
    [self.navigationItem setRightBarButtonItem:doneButton];
    
    NSDictionary *savedSettings = [self.delegate savedSettings];
    if (savedSettings != nil && ![savedSettings isKindOfClass:[NSNull class]]) {
        
        _settings = [savedSettings mutableCopy];
        
        NSNumber *manualOverride = _settings[CUBAdvancedSettingDisableWhenOverridenKey];
        if (manualOverride != nil && ![manualOverride isKindOfClass:[NSNull class]]) {
            [manualOverrideSwitch setOn:[manualOverride boolValue]];
        } else {
            [manualOverrideSwitch setOn:NO];
        }
        
        NSNumber *threshold = _settings[CUBAdvancedSettingThresholdKey];
        if (threshold != nil && ![threshold isKindOfClass:[NSNull class]]) {
            [thresholdSlider setValue:[threshold floatValue]];
            [self updateThresholdLabel:[threshold intValue]];
        } else {
            [thresholdSlider setValue:0.0f];
            [self updateThresholdLabel:0];
        }
        
    } else {
        
        _settings = [NSMutableDictionary new];
        [manualOverrideSwitch setOn:NO];
        [thresholdSlider setValue:0.0f];
        [self updateThresholdLabel:0];
    }
}

- (void)thresholdSliderValueChanged:(UISlider *)slider {
    int threshold = [slider value];
    _settings[CUBAdvancedSettingThresholdKey] = @(threshold);
    [self updateThresholdLabel:threshold];
}

- (void)toggleDisableWhenOverriden:(UISwitch *)aSwitch {
    _settings[CUBAdvancedSettingDisableWhenOverridenKey] = @([aSwitch isOn]);
}

- (void)touchDone {
    
    [self.delegate advancedSettingsViewController:self didUpdateSettings:_settings];
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

- (void)updateThresholdLabel:(int)lux {
    [_thresholdLabel setText:[NSString stringWithFormat:@"Minimum change in ambient light after which brightness is adjusted: %d lux", lux]];
}


@end
