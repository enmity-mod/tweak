ARCHS := arm64 arm64e
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
	TARGET := iphone:clang:latest:15.0
else
	TARGET := iphone:clang:latest:7.0
endif

include $(THEOS)/makefiles/common.mk

DEBUG_IP = 192.168.0.35
TWEAK_NAME = Enmity
DEVTOOLS = 0
Enmity_FILES = $(shell find src -name "*.x")
Enmity_CFLAGS = -DDEBUG_IP=@\"$(DEBUG_IP)\" -DDEVTOOLS=$(DEVTOOLS) -fobjc-arc
Enmity_FRAMEWORKS = UIKit Foundation CoreGraphics CoreImage

BUNDLE_NAME = EnmityFiles
EnmityFiles_INSTALL_PATH = "$(THEOS_PACKAGE_INSTALL_PREFIX)/Library/Application\ Support/Enmity"

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
