ARCHS := arm64 arm64e
TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

DEBUG_IP = 192.168.0.35
TWEAK_NAME = Enmity
DEVTOOLS = 0
Enmity_FILES = $(shell find src -name "*.x" && find src -name "*.xi")
Enmity_CFLAGS = -DDEBUG_IP=@\"$(DEBUG_IP)\" -DDEVTOOLS=$(DEVTOOLS) -fobjc-arc
Enmity_FRAMEWORKS = UIKit Foundation CoreGraphics CoreImage

BUNDLE_NAME = EnmityFiles
EnmityFiles_INSTALL_PATH = "$(THEOS_PACKAGE_INSTALL_PREFIX)/Library/Application\ Support/Enmity"

ifeq ($(SIDELOAD),1)
Enmity_FILES += SideloadFix.xm
endif

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
