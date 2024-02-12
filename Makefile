ARCHS := arm64 arm64e
TARGET := iphone:clang:latest:11.0

include $(THEOS)/makefiles/common.mk

DEBUG_IP = 192.168.0.35
DEVTOOLS = 0

TWEAK_NAME = Enmity
Enmity_FILES = $(shell find Sources -name "*.x*")
Enmity_CFLAGS = -DDEBUG_IP=@\"$(DEBUG_IP)\" -DDEVTOOLS=$(DEVTOOLS) -fobjc-arc
Enmity_FRAMEWORKS = UIKit Foundation

BUNDLE_NAME = EnmityResources
EnmityResources_INSTALL_PATH = "$(THEOS_PACKAGE_INSTALL_PREFIX)/Library/Application\ Support/Enmity"

ifeq ($(SIDELOAD),1)
Enmity_FILES += Extras/Sideload.xm
endif

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk