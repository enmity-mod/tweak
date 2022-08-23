ARCHS := arm64 arm64e
TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

DEBUG_IP = 127.0.0.1
TWEAK_NAME = Enmity
Enmity_FILES = $(shell find src -name "*.x")
Enmity_CFLAGS = -DDEBUG_IP=@\"$(DEBUG_IP)\" -DDEVTOOLS=$(DEVTOOLS) -fobjc-arc
Enmity_FRAMEWORKS = UIKit Foundation CoreGraphics CoreImage

BUNDLE_NAME = EnmityFiles
EnmityFiles_INSTALL_PATH = "/Library/Application\ Support/Enmity"

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
