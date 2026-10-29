TARGET := iphone:clang:latest:15.0
# Music is an Apple app (arm64e), so this must be arm64e to load there.
ARCHS = arm64e
THEOS_PACKAGE_SCHEME = rootless
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = xz

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MusicPill
MusicPill_FILES = Tweak.x
MusicPill_FRAMEWORKS = UIKit MediaPlayer
MusicPill_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
