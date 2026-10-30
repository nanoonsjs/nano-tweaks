TARGET := iphone:clang:latest:15.0
# arm64e: iPhone XS and newer (A12+); arm64: iPhone 8 / 8 Plus / X (A11), which
# also run iOS 16 (palera1n). Both slices go in one dylib.
ARCHS = arm64 arm64e
# Rootless by default (Dopamine, palera1n rootless); CI also makes a rootful deb.
THEOS_PACKAGE_SCHEME ?= rootless
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = xz

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MusicPill
MusicPill_FILES = Tweak.x
MusicPill_FRAMEWORKS = UIKit MediaPlayer AVFoundation CoreMedia
MusicPill_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
