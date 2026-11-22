#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from device makefile.
$(call inherit-product, device/xiaomi/aristotle/device.mk)

# Inherit LineageOS product
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_aristotle
PRODUCT_DEVICE := aristotle
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := 2306EPN60G

PRODUCT_CHARACTERISTICS := nosdcard

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildDesc="aristotle_eea-user 16 BP2A.250605.031.A3 OS3.0.5.0.WMFEUXM release-keys" \
    BuildFingerprint=Xiaomi/aristotle_eea/aristotle:16/BP2A.250605.031.A3/OS3.0.5.0.WMFEUXM:user/release-keys \
    DeviceName=aristotle \
    DeviceProduct=aristotle_eea \
    SystemDevice=aristotle \
    SystemName=aristotle_eea
