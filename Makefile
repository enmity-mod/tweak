ARCHS := arm64 arm64e
TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

DEBUG_IP = 192.168.1.150
TWEAK_NAME = Enmity
Enmity_FILES = $(shell find src -name "*.x")
Enmity_CFLAGS = -DDEBUG_IP=@\"$(DEBUG_IP)\" -fobjc-arc

BUNDLE_NAME = EnmityFiles
$(BUNDLE_NAME)_INSTALL_PATH = /Library/Application Support/Enmity/

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
