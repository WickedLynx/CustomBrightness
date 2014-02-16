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
NSString *const CUBAdvancedSettingLinearAdjustmentKey = @"linearAdjustment";
NSString *const CUBAdvancedSettingsPollingIntervalKey = @"pollingInterval";

@interface CUBAdvancedSettingsViewController () {
    NSMutableDictionary *_settings;
    UILabel *_thresholdLabel;
    UILabel *_pollingIntervalLabel;
}

- (void)thresholdSliderValueChanged:(UISlider *)slider;
- (void)toggleDisableWhenOverriden:(UISwitch *)aSwitch;
- (void)touchDone;
- (void)updateThresholdLabel:(int)lux;
- (void)toggleLinearAdjustment:(UISwitch *)aSwitch;
- (void)pollingIntervalSliderValueChanged:(UISlider *)slider;

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
    [thresholdSlider setMaximumValue:20.0f];
    [thresholdSlider addTarget:self action:@selector(thresholdSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:thresholdSlider];
    
    UILabel *linearAdjustmentLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, thresholdSlider.frame.origin.y + thresholdSlider.bounds.size.height + 30, 200, 30)];
    [linearAdjustmentLabel setText:@"Linear Adjustment"];
    [linearAdjustmentLabel setAdjustsFontSizeToFitWidth:YES];
    [self.view addSubview:linearAdjustmentLabel];
    
    UISwitch *linearAdjustmentSwitch = [[UISwitch alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 70), linearAdjustmentLabel.frame.origin.y, 50, 50)];
    [linearAdjustmentSwitch setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin)];
    [linearAdjustmentSwitch addTarget:self action:@selector(toggleLinearAdjustment:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:linearAdjustmentSwitch];
    
    UILabel *pollingIntervalLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, linearAdjustmentSwitch.frame.origin.y + linearAdjustmentSwitch.bounds.size.height + 30, 280, 30)];
    [pollingIntervalLabel setText:@"Polling interval: 3 seconds"];
    [pollingIntervalLabel setAdjustsFontSizeToFitWidth:YES];
    [self.view addSubview:pollingIntervalLabel];
    _pollingIntervalLabel = pollingIntervalLabel;
    
    UISlider *pollingIntervalSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, pollingIntervalLabel.frame.origin.y + pollingIntervalLabel.bounds.size.height + 5, self.view.bounds.size.width - 40, 50)];
    [pollingIntervalSlider setContinuous:YES];
    [pollingIntervalSlider setMinimumValue:2.0f];
    [pollingIntervalSlider setMaximumValue:10.0f];
    [pollingIntervalSlider addTarget:self action:@selector(pollingIntervalSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:pollingIntervalSlider];
    [pollingIntervalSlider setValue:3.0f];
    
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
        
        NSNumber *linearAdjustmentNumber = _settings[CUBAdvancedSettingLinearAdjustmentKey];
        if (![linearAdjustmentNumber isKindOfClass:[NSNull class]] && linearAdjustmentNumber != nil) {
            [linearAdjustmentSwitch setOn:[linearAdjustmentNumber boolValue]];
        } else {
            [linearAdjustmentSwitch setOn:NO];
        }
        
        NSNumber *pollingIntervalNumber = _settings[CUBAdvancedSettingsPollingIntervalKey];
        if (![pollingIntervalNumber isKindOfClass:[NSNull class]] && pollingIntervalNumber != nil) {
            [_pollingIntervalLabel setText:[NSString stringWithFormat:@"Polling interval: %d seconds", [pollingIntervalNumber intValue]]];
            [pollingIntervalSlider setValue:[pollingIntervalNumber floatValue]];
        }
        
    } else {
        
        _settings = [NSMutableDictionary new];
        [manualOverrideSwitch setOn:NO];
        [thresholdSlider setValue:0.0f];
        [self updateThresholdLabel:0];
        [linearAdjustmentSwitch setOn:NO];
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

- (void)toggleLinearAdjustment:(UISwitch *)aSwitch {
    _settings[CUBAdvancedSettingLinearAdjustmentKey] = @([aSwitch isOn]);
}

- (void)pollingIntervalSliderValueChanged:(UISlider *)slider {
    int pollingInterval = [slider value];
    _settings[CUBAdvancedSettingsPollingIntervalKey] = @(pollingInterval);
    [_pollingIntervalLabel setText:[NSString stringWithFormat:@"Polling interval: %d seconds", pollingInterval]];
}


@end
