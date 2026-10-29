TARGET := iphone:clang:latest:15.0
# SpringBoard is arm64e.
ARCHS = arm64e
THEOS_PACKAGE_SCHEME = rootless
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = xz

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Control26
Control26_FILES = Tweak.x
Control26_FRAMEWORKS = UIKit QuartzCore
Control26_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
