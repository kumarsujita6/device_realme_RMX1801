#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e

DEVICE=RMX1801
VENDOR=realme

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

DU_ROOT="${MY_DIR}/../../.."

HELPER="${DU_ROOT}/vendor/du/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true
SECTION=
KANG=

while [ "$1" != "" ]; do
    case "$1" in
        -n | --no-cleanup )     CLEAN_VENDOR=false
                                ;;
        -k | --kang)            KANG="--kang"
                                ;;
        -s | --section )        shift
                                SECTION="$1"
                                CLEAN_VENDOR=false
                                ;;
        * )                     SRC="$1"
                                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC=adb
fi

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${DU_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" ${KANG} --section "${SECTION}"

# Fix proprietary blobs
patchelf --remove-needed android.hidl.base@1.0.so \
        "${DU_ROOT}/vendor/${VENDOR}/${DEVICE}/proprietary/lib/libwfdnative.so"
patchelf --remove-needed android.hidl.base@1.0.so \
        "${DU_ROOT}/vendor/${VENDOR}/${DEVICE}/proprietary/lib64/libwfdnative.so"

patchelf --add-needed libcamera_sdm660_shim.so \
        "${DU_ROOT}/vendor/${VENDOR}/${DEVICE}/proprietary/vendor/lib/hw/camera.sdm660.so"

patchelf --replace-needed "libcutils.so" "libprocessgroup.so" \
        "${DU_ROOT}/vendor/${VENDOR}/${DEVICE}/proprietary/vendor/lib/hw/audio.primary.sdm660.so"

patchelf --replace-needed "libcutils.so" "libprocessgroup.so" \
        "${DU_ROOT}/vendor/${VENDOR}/${DEVICE}/proprietary/vendor/lib64/hw/audio.primary.sdm660.so"

sed -i 's/<library name="android.hidl.manager-V1.0-java"/<library name="android.hidl.manager@1.0-java"/g' \
        "${DU_ROOT}/vendor/${VENDOR}/${DEVICE}/proprietary/etc/permissions/qti_libpermissions.xml"

"${MY_DIR}/setup-makefiles.sh"
