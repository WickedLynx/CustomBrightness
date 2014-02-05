include theos/makefiles/common.mk

export TARGET=iphone:latest:5.0
export ARCHS = armv7

SHARED_CFLAGS = -fobjc-arc

APPLICATION_NAME = CustomBrightness

CustomBrightness_FILES = main.m CUBAppDelegate.m CUBBrightnessSetting.m CUBHomeViewController.m CUBSavedSettingsViewController.m CUBSavedSettingsTableViewCell.m CUBHelpViewController.m CUBBorderedButton.m CUBNavigationController.m

CustomBrightness_FRAMEWORKS = UIKit CoreGraphics IOKit QuartzCore
CustomBrightness_CFLAGS = -I/opt/PrivateHeaders

include $(THEOS_MAKE_PATH)/application.mk
