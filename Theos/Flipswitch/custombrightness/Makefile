include theos/makefiles/common.mk

export SDKVERSION=7.0
export TARGET=iphone:clang:7.0:6.0
export ARCHS = armv7 arm64

BUNDLE_NAME = CustomBrightness
CustomBrightness_FILES = Switch.x
CustomBrightness_FRAMEWORKS = UIKit
CustomBrightness_LIBRARIES = flipswitch
CustomBrightness_INSTALL_PATH = /Library/Switches

include $(THEOS_MAKE_PATH)/bundle.mk