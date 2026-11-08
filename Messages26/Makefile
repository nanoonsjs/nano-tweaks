TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME ?= rootless
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = xz

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Messages26
Messages26_FILES = Tweak.x
Messages26_FRAMEWORKS = UIKit QuartzCore PhotosUI Photos LocalAuthentication NaturalLanguage UserNotifications AudioToolbox
Messages26_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk
