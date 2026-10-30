TARGET := iphone:clang:latest:15.0
# arm64e: iPhone XS and newer; arm64: iPhone 8 / X (A11).
ARCHS = arm64 arm64e
# Rootless by default; CI also makes a rootful deb.
THEOS_PACKAGE_SCHEME ?= rootless
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = xz

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = LockStar
LockStar_FILES = Tweak.x
LockStar_FRAMEWORKS = UIKit QuartzCore
LockStar_CFLAGS = -fobjc-arc -Wno-deprecated-declarations

include $(THEOS_MAKE_PATH)/tweak.mk
