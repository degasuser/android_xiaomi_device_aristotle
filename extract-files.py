#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
# Extracts the system-side proprietary files of the Xiaomi 13T (aristotle)
# from a HyperOS OS3.0.5.0.WMFEUXM dump / OTA zip.
#
# The vendor-side partitions (vendor, odm, vendor_dlkm, odm_dlkm,
# system_dlkm) and the platform firmware are not extracted here, they are
# shipped as stock images, see extract-images.py.
#

import os
import re

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)
from extract_utils.tools import (
    apktool_path,
    java_path,
)
from extract_utils.utils import run_cmd

namespace_imports = [
    'device/xiaomi/aristotle',
    'hardware/mediatek',
    'hardware/xiaomi',
]

lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
}

# Android 14+ requires dynamically registered receivers that do not only
# listen to protected broadcasts to pass RECEIVER_EXPORTED or
# RECEIVER_NOT_EXPORTED. HyperOS relaxes that check, AOSP does not. Instead of
# a context sensitive smali patch (which breaks with every ImsService update),
# route every 2/4 argument Context.registerReceiver() call through a small
# helper class that adds RECEIVER_EXPORTED (0x2).
_RECEIVER_COMPAT_CLASS = 'Lorg/lineageos/aristotle/ReceiverCompat;'
_RECEIVER_COMPAT_SMALI = '''.class public final Lorg/lineageos/aristotle/ReceiverCompat;
.super Ljava/lang/Object;


.method public static registerReceiver(Landroid/content/Context;Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;)Landroid/content/Intent;
    .registers 4

    const/4 v0, 0x2

    invoke-virtual {p0, p1, p2, v0}, Landroid/content/Context;->registerReceiver(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;I)Landroid/content/Intent;

    move-result-object v0

    return-object v0
.end method

.method public static registerReceiver(Landroid/content/Context;Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;Ljava/lang/String;Landroid/os/Handler;)Landroid/content/Intent;
    .registers 12

    move-object v0, p0
    move-object v1, p1
    move-object v2, p2
    move-object v3, p3
    move-object v4, p4
    const/4 v5, 0x2

    invoke-virtual/range {v0 .. v5}, Landroid/content/Context;->registerReceiver(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;Ljava/lang/String;Landroid/os/Handler;I)Landroid/content/Intent;

    move-result-object v0

    return-object v0
.end method
'''

_REGISTER_RECEIVER_RE = re.compile(
    r'invoke-virtual(/range)? \{([^}]*)\}, '
    r'L(?:android/content/Context|android/content/ContextWrapper|android/app/Service|'
    r'android/app/Application|android/app/Activity);->registerReceiver\('
    r'(Landroid/content/BroadcastReceiver;Landroid/content/IntentFilter;'
    r'(?:Ljava/lang/String;Landroid/os/Handler;)?)\)Landroid/content/Intent;'
)


def _apktool_unpack_smali(ctx, file, file_path, *args, tmp_dir=None, **kwargs):
    assert tmp_dir is not None
    run_cmd(
        [java_path, '-jar', apktool_path, 'd', file_path, '-o', tmp_dir, '-f', '--no-res']
    )


def _export_dynamic_receivers(ctx, file, file_path, *args, tmp_dir=None, **kwargs):
    assert tmp_dir is not None

    def replace(m: re.Match) -> str:
        rng, regs, params = m.group(1) or '', m.group(2), m.group(3)
        return (
            f'invoke-static{rng} {{{regs}}}, {_RECEIVER_COMPAT_CLASS}->registerReceiver('
            f'Landroid/content/Context;{params})Landroid/content/Intent;'
        )

    patched = 0
    for root, _, files in os.walk(tmp_dir):
        for name in files:
            if not name.endswith('.smali'):
                continue
            smali = os.path.join(root, name)
            with open(smali, encoding='utf-8') as f:
                data = f.read()
            new_data, count = _REGISTER_RECEIVER_RE.subn(replace, data)
            if count:
                with open(smali, 'w', encoding='utf-8') as f:
                    f.write(new_data)
                patched += count

    helper_dir = os.path.join(tmp_dir, 'smali', 'org', 'lineageos', 'aristotle')
    os.makedirs(helper_dir, exist_ok=True)
    with open(os.path.join(helper_dir, 'ReceiverCompat.smali'), 'w', encoding='utf-8') as f:
        f.write(_RECEIVER_COMPAT_SMALI)

    print(f'{file.dst}: exported {patched} dynamic receivers')


blob_fixups: blob_fixups_user_type = {
    'system_ext/priv-app/ImsService/ImsService.apk': blob_fixup()
        .call(_apktool_unpack_smali)
        .call(_export_dynamic_receivers)
        .apktool_pack()
        .stripzip(),
    'system_ext/lib64/libimsma.so': blob_fixup()
        .replace_needed('libsink.so', 'libsink-mtk.so'),
    'system_ext/etc/init/init.vtservice.rc': blob_fixup()
        .regex_replace(r'\bstart\b', 'enable'),
}  # fmt: skip

module = ExtractUtilsModule(
    'aristotle',
    'xiaomi',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
