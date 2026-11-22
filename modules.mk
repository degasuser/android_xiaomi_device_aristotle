#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Kernel modules of the stock HyperOS 3 (OS3.0.5.0.WMFEUXM) vendor_boot
# ramdisk, matching prebuilts/kernel/kernel (6.12.38-android16-5).
#
# Only first stage (vendor_boot) modules live in the device tree. The
# vendor_dlkm, odm_dlkm and system_dlkm modules are shipped through the stock
# partition images, see BoardConfig.mk and extract-images.py.
#

KERNEL_MODULES_PATH := $(DEVICE_PATH)/prebuilts/modules/vendor_ramdisk

BOARD_VENDOR_RAMDISK_KERNEL_MODULES := \
    $(wildcard $(KERNEL_MODULES_PATH)/*.ko)

BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := \
    $(strip $(shell cat $(KERNEL_MODULES_PATH)/modules.load))

BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := \
    $(strip $(shell cat $(KERNEL_MODULES_PATH)/modules.load.recovery))

# Keep the stock modules byte-identical (signed GKI vendor modules).
BOARD_DO_NOT_STRIP_VENDOR_RAMDISK_MODULES := true
