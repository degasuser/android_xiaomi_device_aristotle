#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/aristotle

# Generic ramdisk / storage
# Note: dalvik heap and other vendor properties come from the stock vendor
# image; system-side values are set in system.prop.
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Virtual A/B (device launched with Android 13 and a vendor ramdisk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/vabc_features.mk)
PRODUCT_VIRTUAL_AB_COMPRESSION_METHOD := lz4

# API levels
PRODUCT_SHIPPING_API_LEVEL := 33
BOARD_SHIPPING_API_LEVEL := 31

# File systems
PRODUCT_SYSTEM_PARTITIONS_FILE_SYSTEM_TYPE ?= erofs
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Kernel
# Stock 6.12 GKI: supports userfaultfd + MREMAP_DONTUNMAP.
PRODUCT_ENABLE_UFFD_GC := true
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(DEVICE_PATH) \
    hardware/mediatek \
    hardware/xiaomi \
    vendor/xiaomi/aristotle

# A/B
PRODUCT_PACKAGES += \
    otapreopt_script \
    update_engine \
    update_engine_sideload \
    update_verifier

AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/otapreopt_script \
    FILESYSTEM_TYPE_system=$(PRODUCT_SYSTEM_PARTITIONS_FILE_SYSTEM_TYPE) \
    POSTINSTALL_OPTIONAL_system=true

# MediaTek preloader partition symlinks (preloader_raw_a/b) for update_engine
PRODUCT_PACKAGES += \
    create_pl_dev \
    create_pl_dev.recovery

# Recovery / fastbootd
# The stock vendor provides the boot control, health and other HALs for
# Android itself; recovery runs from vendor_boot and needs its own copies.
PRODUCT_PACKAGES += \
    android.hardware.boot-service.mediatek_recovery \
    android.hardware.fastboot-service.example_recovery \
    android.hardware.health-service.mediatek-recovery

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/init/init.recovery.mt6895.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt6895.rc

# First stage mount
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/init/fstab.mt6895:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.mt6895

# Audio
PRODUCT_PACKAGES += \
    MtkInCallService

# Display
PRODUCT_PACKAGES += \
    NoCutoutOverlay \
    AvoidAppsInCutoutOverlay

PRODUCT_PRODUCT_PROPERTIES += \
    ro.support_hide_display_cutout=true

# Display brightness/nits mapping and HBM (stock HyperOS 3)
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/displayconfig/display_id_4627039422300187648.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/displayconfig/display_id_4627039422300187648.xml

# IMS / Telephony (MediaTek frameworks are built from hardware/mediatek)
ENABLE_VENDOR_RIL_SERVICE := true
$(call inherit-product, hardware/mediatek/frameworks/mediatek-frameworks.mk)

PRODUCT_PACKAGES += \
    ImsServiceEntitlement

PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/permissions/privapp-permissions-com.mediatek.ims.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/privapp-permissions-com.mediatek.ims.xml \
    $(DEVICE_PATH)/configs/permissions/privapp-permissions-com.mediatek.telephony.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/privapp-permissions-com.mediatek.telephony.xml \
    $(DEVICE_PATH)/configs/permissions/privapp-permissions-com.mediatek.location.lppe.main.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/privapp-permissions-com.mediatek.location.lppe.main.xml \
    $(DEVICE_PATH)/configs/permissions/com.mediatek.ims.config.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/sysconfig/com.mediatek.ims.config.xml

# HotwordEnrollment ("Hey Google" on the MediaTek VOW DSP)
PRODUCT_COPY_FILES += \
    $(DEVICE_PATH)/configs/permissions/privapp-permissions-hotword.xml:$(TARGET_COPY_OUT_PRODUCT)/etc/permissions/privapp-permissions-hotword.xml

# NFC (stock NXP AIDL HAL in /vendor)
PRODUCT_PACKAGES += \
    com.android.nfcservices \
    Tag

# Overlays
PRODUCT_ENFORCE_RRO_TARGETS := *

PRODUCT_PACKAGES += \
    AristotleFrameworksOverlay \
    AristotleLauncher3Overlay \
    AristotleSettingsOverlay \
    AristotleSystemUIOverlay

PRODUCT_PACKAGES += \
    AristotleApertureOverlay \
    AristotleLineageSettingsOverlay \
    AristotlePowerOffAlarmOverlay

# Power-off alarm
PRODUCT_PACKAGES += \
    PowerOffAlarm

# Inherit the proprietary files
$(call inherit-product, vendor/xiaomi/aristotle/aristotle-vendor.mk)
