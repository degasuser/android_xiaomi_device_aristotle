# Xiaomi 13T (aristotle): device tree

Device tree for building custom ROMs (LineageOS and ROMs based on it) for the
**Xiaomi 13T** (`aristotle`), based on the firmware
**HyperOS OS3.0.5.0.WMFEUXM** (EEA, Android 16, security patch 2026-10-01).

| | |
|---|---|
| Device | Xiaomi 13T (2306EPN60G / 2306EPN60R) |
| Codename | `aristotle` |
| SoC | MediaTek Dimensity 8200-Ultra (MT6895, `mt6895`) |
| Display | 6.67" AMOLED 1220×2712, 144 Hz, density 480 |
| Kernel | GKI `6.12.38-android16-5` (stock HyperOS 3, prebuilt) |
| Vendor | HyperOS 3, AIDL HALs, VINTF target-level 202504, `ro.board.api_level=31` |
| Partitions | Virtual A/B (VABC), super 9 GiB, `vendor_boot` v4, no `init_boot` |
| Base ROM | **LineageOS 23.2 (Android 16 QPR2)** and ROMs built on it |

---

## Как устроено дерево (и почему)

На HyperOS 3 у aristotle **ядро обновлено до 6.12 GKI**, а вендор полностью
переведён на AIDL-HAL от MediaTek Android 16 BSP. Xiaomi не публиковала исходники
ядра 6.12 для aristotle (в MiCode есть только старая ветка `bsp-aristotle-s-oss`
с ядром 5.10), поэтому ядро и модули можно брать только стоковые, а модули
должны точно совпадать с ядром.

Отсюда схема «стоковый вендор + собранная система»:

| Что | Откуда |
|---|---|
| `vendor`, `odm`, `vendor_dlkm`, `odm_dlkm`, `system_dlkm` | **стоковые образы OS3.0.5.0** без изменений (`BOARD_PREBUILT_*IMAGE`) |
| Ядро (`kernel`), `dtb`, `dtbo`, модули первой стадии | стоковые, лежат в `prebuilts/` этого репозитория |
| Прошивки платформы: preloader, lk, tee, gz, scp, sspm, md1img (модем), … | стоковые, кладутся в ROM как radio-образы, чтобы прошивка всегда совпадала с вендором |
| `system`, `system_ext`, `product` | собираются из исходников ROM |
| `boot` (ядро + generic ramdisk), `vendor_boot` (модули, fstab, рекавери) | собираются |
| `vbmeta`, `vbmeta_system`, `vbmeta_vendor` | собираются (тестовые ключи AVB, верификация выключена) |
| IMS/VoLTE/ViLTE, LPPe, NeuroPilot, Hotword | системные блобы из OS3 (`proprietary-files.txt`) |

Плюсы: HAL-ы, SELinux-политика вендора, init-скрипты, конфиги аудио/камеры/
сенсоров/термалки и модули ядра — ровно в той комбинации, в которой их
выпустила Xiaomi. Это тот же принцип, по которому на стоковом вендоре
запускаются GSI. На стороне системы — только то, что нужно AOSP/LineageOS.

### Почему LineageOS 23.2 (Android 16), а не 24 (Android 17)

Вендор OS3 собран под SELinux/VINTF версии **202504** (Android 16). Чтобы
политика `system_ext` от MediaTek (IMS, vtservice и т.д.) корректно
сопоставлялась с политикой стокового вендора, версия платформенной политики
должна совпадать с версией вендора. На Android 17 (202604) нужны mapping-файлы
`system_ext` для 202504, которых нет. Поэтому базой выбран Android 16 QPR2.

---

## Отличия от старого дерева (zmafnan/android_device_xiaomi_aristotle)

- База — **OS3.0.5.0 / Android 16 / ядро 6.12**, а не OS2.0.214.0 / Android 15 / 5.10.
- Нет 560 МБ бинарников в репозитории (ядро 5.10, модули, Dolby, ASI-apk,
  ключи подписи Leica с паролем в открытом виде и т.п.).
- Нет «самоприменяющихся» патчей к исходникам ROM из `device.mk`
  (`$(shell apply-patches.sh)`) и нет `WITH_ADB_INSECURE` / вшитых `adb_keys`.
- Нет сотен ABI-хаков (`-v31`, shim-библиотек, переименований), нужных для
  запуска вендора OS2 на новой системе: вендор не пересобирается.
- Правильная разметка super из payload OS3 (группа 9 661 579 264 байт,
  `system_dlkm` в super), правильная цепочка AVB, VABC с lz4.
- Прошивки платформы (preloader/lk/tee/модем…) входят в ROM, как в стоке.
- Скрипт `extract-images.py` сам достаёт всё нужное из официального OTA-zip,
  без сторонних бинарников.

---

## Сборка

### 1. Исходники

```bash
repo init -u https://github.com/LineageOS/android.git -b lineage-23.2 --git-lfs
```

`.repo/local_manifests/aristotle.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <remote name="aristotle" fetch="https://github.com/" />

  <project path="device/xiaomi/aristotle"
           name="degasuser/android_xiaomi_device_aristotle"
           remote="aristotle" revision="main" />

  <!-- dependencies (also listed in lineage.dependencies) -->
  <project path="device/mediatek/sepolicy_vndr"
           name="LineageOS/android_device_mediatek_sepolicy_vndr"
           remote="aristotle" revision="lineage-23.2" />
  <project path="hardware/mediatek"
           name="LineageOS/android_hardware_mediatek"
           remote="aristotle" revision="lineage-23.2" />
  <project path="hardware/xiaomi"
           name="LineageOS/android_hardware_xiaomi"
           remote="aristotle" revision="lineage-23.2" />
</manifest>
```

```bash
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

> Укажите в `revision` ту ветку этого репозитория, в которой лежит дерево.

### 2. Стоковые образы и блобы

Скачайте официальный full OTA (Recovery ROM) OS3.0.5.0.WMFEUXM, около 6,7 ГБ:

```
https://cdnorg.d.miui.com/OS3.0.5.0.WMFEUXM/aristotle_eea_global-ota_full-OS3.0.5.0.WMFEUXM-user-16.0-96845cc20f.zip
```

Из корня исходников выполните:

```bash
OTA=~/aristotle_eea_global-ota_full-OS3.0.5.0.WMFEUXM-user-16.0-96845cc20f.zip

# vendor/odm/*_dlkm + прошивки платформы -> vendor/xiaomi/aristotle-images
device/xiaomi/aristotle/extract-images.py "$OTA"

# системные блобы (IMS, LPPe, NeuroPilot, Hotword) -> vendor/xiaomi/aristotle
cd device/xiaomi/aristotle && ./extract-files.py "$OTA" && cd -
```

`extract-images.py` работает на чистом Python 3 (нужен модуль `zstandard`,
только если OTA использует zstd). Ему можно передать и `payload.bin`, и папку с
уже распакованными `*.img` (несжатыми, не sparse).
Если вы не хотите класть прошивки платформы в ROM, добавьте `--no-firmware`.

### 3. Сборка

```bash
source build/envsetup.sh
breakfast aristotle
mka bacon
```

Результат: `out/target/product/aristotle/lineage-23.2-*-aristotle.zip`, а также
`boot.img`, `vendor_boot.img` (в нём рекавери), `dtbo.img`, `vbmeta*.img`.

### Другие ROM (crDroid, Evolution X, Infinity-X, …)

Дерево написано по правилам LineageOS, поэтому для форков достаточно добавить
продуктовый makefile, например `infinity_aristotle.mk`, который отличается от
`lineage_aristotle.mk` только строкой
`$(call inherit-product, vendor/infinity/config/common_full_phone.mk)` и
переменными ROM. Затем добавьте его в `AndroidProducts.mk`. Остальные файлы
трогать не нужно.

---

## Установка

1. Загрузчик должен быть разблокирован. Рекомендуется сначала прошить сток
   **OS3.0.5.0.WMFEUXM** (или новее) через Mi Flash.
   Внимание: в ROM входят preloader и прошивки платформы из OS3.0.5.0, а у
   Xiaomi есть anti-rollback. Не прошивайте сборку, если на телефоне стоит
   **более новая** прошивка с бо́льшим индексом ARB, чем у OS3.0.5.0. В таком
   случае пересоберите ROM с `extract-images.py … --no-firmware` или
   обновите дерево под вашу прошивку.
2. Прошейте загрузочные образы из папки сборки:
   ```bash
   fastboot flash vendor_boot vendor_boot.img
   fastboot flash boot boot.img
   fastboot flash dtbo dtbo.img
   fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
   fastboot reboot recovery
   ```
3. В рекавери выберите **Factory reset → Format data**, затем **Apply update →
   Apply from ADB** и выполните `adb sideload lineage-*.zip`.
4. Если нужны GApps, перезагрузитесь в рекавери и поставьте их, затем
   **Reboot system now**.

---

## Состав дерева

```
BoardConfig.mk          разметка, ядро, AVB, prebuilt-образы вендора, SELinux
device.mk               пакеты системы/рекавери, IMS, оверлеи, VAB
lineage_aristotle.mk    продукт LineageOS
modules.mk              модули ramdisk первой стадии (vendor_boot)
extract-images.py       стоковые образы и прошивки из OTA
extract-files.py        системные блобы (extract-utils)
proprietary-files.txt   список системных блобов OS3
prebuilts/kernel        kernel 6.12 (lz4), dtb, dtbo из OS3.0.5.0
prebuilts/modules       206 модулей vendor_boot + modules.load(.recovery)
init/                   fstab.mt6895 (первая стадия/рекавери), init.recovery
configs/                displayconfig (яркость/нит/HBM), privapp-permissions
overlay/, overlay-lineage/  RRO: вырез, скругления, UDFPS, автояркость, …
```

---

## Статус

Дерево подготовлено и проверено статически: XML и Python валидны, разметка
super, AVB, параметры boot/vendor_boot сверены со стоковым payload и vbmeta
OS3, `extract-files.py` прогнан на дампе OS3 через LineageOS extract-utils
23.2 (генерирует 84 модуля). **Полная сборка и проверка на устройстве ещё не
проводились.** Пункты, которые нужно проверить на телефоне в первую очередь:

| Функция | Ожидание / комментарий |
|---|---|
| Загрузка, дисплей 144 Гц, звук, Wi-Fi, BT, сенсоры, камера (Aperture), GPS, NFC, ИК | работают стоковые HAL вендора; ожидается, что всё работает |
| Отпечаток под экраном | стоковый AIDL HAL v4 из /odm; координаты сенсора заданы в оверлее (610, 2444, r=105); подсветку HBM при сканировании нужно проверить |
| VoLTE / VoWiFi / ViLTE | IMS из HyperOS 3 + фреймворки MTK из `hardware/mediatek`; в ImsService автоматически экспортируются динамические ресиверы. Самый рискованный пункт |
| Double-tap-to-wake, режимы тачскрина | нужен Lineage touch HAL на стороне вендора, а вендор стоковый, поэтому отключено |
| Рекавери: тач | в ramdisk рекавери стоково нет драйвера тача, управление клавишами громкости |
| Dolby Atmos, камера Leica (MIUI Camera) | не входят; вендорная часть Dolby есть, системное приложение можно добавить отдельно |

При проблемах присылайте `adb logcat -b all -d`, `adb shell dmesg` и
`adb shell getprop`.

## Обновление на новую прошивку HyperOS

```bash
device/xiaomi/aristotle/extract-images.py --update-prebuilts <новый full OTA zip>
cd device/xiaomi/aristotle && ./extract-files.py <новый full OTA zip>
```

`--update-prebuilts` сам достаёт из `boot`/`vendor_boot`/`dtbo` ядро, dtb, dtbo и
модули первой стадии и кладёт их в `prebuilts/`, а также печатает cmdline и
bootconfig вендора. После этого вручную обновите `BOOT_SECURITY_PATCH` в
`BoardConfig.mk`, отпечаток в `lineage_aristotle.mk` и при изменении разметки
размер группы super.
