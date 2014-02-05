include theos/makefiles/common.mk
export TARGET=iphone:latest:5.0
export ARCHS = armv7

SHARED_CFLAGS = -fobjc-arc

TOOL_NAME = customBrightnessd
customBrightnessd_FILES = main.m
customBrightnessd_FRAMEWORKS = IOKit UIKit
customBrightnessd_CFLAGS = -I/opt/PrivateHeaders
LOCAL_INSTALL_PATH = "/usr/bin"

include $(THEOS_MAKE_PATH)/tool.mk
include $(FW_MAKEDIR)/aggregate.mk



