#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Xiaomi 13T (aristotle) - MediaTek Dimensity 8200-Ultra (MT6895)
# Base firmware: HyperOS OS3.0.5.0.WMFEUXM (Android 16, kernel 6.12 GKI)
#

DEVICE_PATH := device/xiaomi/aristotle
IMAGES_PATH := vendor/xiaomi/aristotle-images

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a76

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := aristotle
TARGET_NO_BOOTLOADER := true

# Platform
TARGET_BOARD_PLATFORM := mt6895

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    odm \
    odm_dlkm \
    product \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vbmeta_vendor \
    vendor \
    vendor_boot \
    vendor_dlkm

# Boot image (header v4, kernel only + generic ramdisk; vendor ramdisk in vendor_boot)
BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_BASE := 0x3fff8000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_RAMDISK_OFFSET := 0x26f08000
BOARD_KERNEL_TAGS_OFFSET := 0x07c88000
BOARD_DTB_OFFSET := 0x07c88000

# Our bootloader is fussy about these offsets even with a generic kernel image.
BOARD_MKBOOTIMG_ARGS := --base $(BOARD_KERNEL_BASE)
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)

BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2 bootconfig
BOARD_BOOTCONFIG := \
    kernel.rcu_nocbs=all \
    kernel.rcutree.enable_rcu_lazy=1 \
    kernel.rcupdate.rcu_cpu_stall_cputime=1

BOARD_RAMDISK_USE_LZ4 := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true

# Kernel - prebuilt stock HyperOS 3 GKI (6.12.38-android16-5)
# Xiaomi has not published the 6.12 kernel sources for aristotle; the stock
# kernel must be used together with the stock vendor_dlkm/system_dlkm modules.
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilts/kernel/kernel
TARGET_FORCE_PREBUILT_KERNEL := true
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilts/kernel/dtbs
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_PREBUILT_DTBOIMAGE := $(DEVICE_PATH)/prebuilts/kernel/dtbo.img

# Kernel modules (vendor_boot only; vendor_dlkm/system_dlkm ship as stock images)
include $(DEVICE_PATH)/modules.mk

# Partitions
BOARD_FLASH_BLOCK_SIZE := 262144 # 4096 * 64 (pagesize)
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_DTBOIMG_PARTITION_SIZE := 33554432
BOARD_USES_METADATA_PARTITION := true

# Partitions - Dynamic (values taken from the OS3.0.5.0 payload metadata)
BOARD_SUPER_PARTITION_SIZE := 9663676416
BOARD_SUPER_PARTITION_GROUPS := main
BOARD_MAIN_SIZE := 9661579264 # BOARD_SUPER_PARTITION_SIZE - 2MB, same as stock
BOARD_MAIN_PARTITION_LIST := \
    odm \
    odm_dlkm \
    product \
    system \
    system_dlkm \
    system_ext \
    vendor \
    vendor_dlkm

BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := $(PRODUCT_SYSTEM_PARTITIONS_FILE_SYSTEM_TYPE)
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := $(PRODUCT_SYSTEM_PARTITIONS_FILE_SYSTEM_TYPE)
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE := $(PRODUCT_SYSTEM_PARTITIONS_FILE_SYSTEM_TYPE)
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_ODM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_SYSTEM_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDOR_DLKMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_USES_ODM_DLKMIMAGE := true
BOARD_USES_SYSTEM_DLKMIMAGE := true
BOARD_USES_VENDOR_DLKMIMAGE := true

TARGET_COPY_OUT_ODM := odm
TARGET_COPY_OUT_ODM_DLKM := odm_dlkm
TARGET_COPY_OUT_PRODUCT := product
TARGET_COPY_OUT_SYSTEM_DLKM := system_dlkm
TARGET_COPY_OUT_SYSTEM_EXT := system_ext
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_VENDOR_DLKM := vendor_dlkm

ifeq ($(PRODUCT_SYSTEM_PARTITIONS_FILE_SYSTEM_TYPE),ext4)
-include vendor/lineage/config/BoardConfigReservedSize.mk
endif

# Stock HyperOS 3 vendor-side partitions.
# The vendor, odm, vendor_dlkm, odm_dlkm and system_dlkm images are taken
# unmodified from OS3.0.5.0.WMFEUXM (see extract-images.py). This keeps the
# vendor HALs, vendor SELinux policy, vendor init and the kernel modules of the
# 6.12 GKI kernel exactly as Xiaomi shipped them.
ifeq ($(wildcard $(IMAGES_PATH)/images/vendor.img),)
$(error Stock HyperOS images not found in $(IMAGES_PATH). Run: device/xiaomi/aristotle/extract-images.py <OS3.0.5.0.WMFEUXM OTA zip>)
endif
BOARD_PREBUILT_VENDORIMAGE := $(IMAGES_PATH)/images/vendor.img
BOARD_PREBUILT_ODMIMAGE := $(IMAGES_PATH)/images/odm.img
BOARD_PREBUILT_VENDOR_DLKMIMAGE := $(IMAGES_PATH)/images/vendor_dlkm.img
BOARD_PREBUILT_ODM_DLKMIMAGE := $(IMAGES_PATH)/images/odm_dlkm.img
BOARD_PREBUILT_SYSTEM_DLKMIMAGE := $(IMAGES_PATH)/images/system_dlkm.img

# Platform firmware (lk, tee, preloader, modem, ...) shipped inside the ROM
-include $(IMAGES_PATH)/BoardConfigImages.mk

# Properties
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_SYSTEM_EXT_PROP += $(DEVICE_PATH)/system_ext.prop
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/product.prop

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/init/fstab.mt6895
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_DENSITY := xxhdpi
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 117

# Security patch levels (must match the stock vendor/boot)
BOOT_SECURITY_PATCH := 2026-10-01
VENDOR_SECURITY_PATCH := $(BOOT_SECURITY_PATCH)

# SELinux
# The vendor/odm policy is the stock one (prebuilt images, policy version
# 202504). Only the MediaTek system_ext policy (IMS, vtservice, ...) is built
# here; the stock vendor policy only references platform types and the
# versioned types from its own plat_pub_versioned.cil, so it compiles against it.
include device/mediatek/sepolicy_vndr/SEPolicy.mk

# VINTF
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    hardware/mediatek/vintf/mediatek_framework_compatibility_matrix.xml \
    hardware/mediatek/vintf/mediatek_framework_compatibility_matrix_aidl.xml \
    hardware/xiaomi/vintf/xiaomi_framework_compatibility_matrix.xml

# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_ALGORITHM := SHA256_RSA2048
BOARD_AVB_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

BOARD_AVB_BOOT_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_BOOT_ALGORITHM := SHA256_RSA2048
BOARD_AVB_BOOT_ROLLBACK_INDEX := 0
BOARD_AVB_BOOT_ROLLBACK_INDEX_LOCATION := 3

BOARD_AVB_VBMETA_SYSTEM := product system system_ext
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := 0
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

BOARD_AVB_VBMETA_VENDOR := vendor
BOARD_AVB_VBMETA_VENDOR_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_VENDOR_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX := 0
BOARD_AVB_VBMETA_VENDOR_ROLLBACK_INDEX_LOCATION := 4

BOARD_AVB_SYSTEM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_SYSTEM_EXT_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_PRODUCT_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_VENDOR_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_ODM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_VENDOR_DLKM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_ODM_DLKM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256
BOARD_AVB_SYSTEM_DLKM_ADD_HASHTREE_FOOTER_ARGS += --hash_algorithm sha256

# Inherit the proprietary files
include vendor/xiaomi/aristotle/BoardConfigVendor.mk
