ARCHS := arm64 arm64e
TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Enmity
$(TWEAK_NAME)_FILES = src/Enmity.x src/Utils.x src/Commands.x src/Plugins.x src/Theme.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
