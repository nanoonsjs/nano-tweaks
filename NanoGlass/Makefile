TARGET := iphone:clang:latest:15.0
# arm64e: iPhone XS and newer; arm64: iPhone 8 / X (A11).
ARCHS = arm64 arm64e
# Rootless by default; CI also makes a rootful deb.
THEOS_PACKAGE_SCHEME ?= rootless
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = xz

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NanoGlass
NanoGlass_FILES = Tweak.x
NanoGlass_FRAMEWORKS = UIKit QuartzCore
NanoGlass_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk
