TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME ?= rootless
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = xz

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Messages26 M26Keeper
Messages26_FILES = Tweak.x
Messages26_FRAMEWORKS = UIKit QuartzCore PhotosUI Photos QuickLook LocalAuthentication NaturalLanguage UserNotifications AudioToolbox AVFoundation CoreMedia
Messages26_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error

# Keep Unsent Messages: saves a message in imagent right before an unsend wipes it
M26Keeper_FILES = Keeper.x Insights.m
M26Keeper_LIBRARIES = sqlite3
M26Keeper_FRAMEWORKS = Foundation
M26Keeper_CFLAGS = -fobjc-arc -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk
