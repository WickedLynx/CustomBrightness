//
//  CUBAdvancedSettingsViewController.h
//  CustomBrightness
//
//  Created by Harshad on 06/02/2014.
//  Copyright (c) 2014 Laughing Buddha Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CUBAdvancedSettingsViewController;

@protocol CUBAdvancedSettingsViewControllerDelegate <NSObject>

@required

- (NSDictionary *)savedSettings;
- (void)advancedSettingsViewController:(CUBAdvancedSettingsViewController *)viewController didUpdateSettings:(NSDictionary *)settings;

@end

@interface CUBAdvancedSettingsViewController : UIViewController

- (instancetype)initWithDelegate:(id <CUBAdvancedSettingsViewControllerDelegate>)delegate;

@property (weak, nonatomic) id <CUBAdvancedSettingsViewControllerDelegate> delegate;

@end
