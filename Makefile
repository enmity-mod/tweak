ARCHS := arm64 arm64e
TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

DEBUG_IP = 192.168.1.150
TWEAK_NAME = Enmity
Enmity_FILES = src/Enmity.x src/Utils.x src/Commands.x src/Plugins.x src/Theme.x
Enmity_CFLAGS = -DDEBUG_IP=\"$(DEBUG_IP)\" -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
