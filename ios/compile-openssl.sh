#! /usr/bin/env bash
#
# Copyright (C) 2013-2014 Bilibili
# Copyright (C) 2013-2014 Zhang Rui <bbcallen@gmail.com>
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

#----------
# modify for your build tool

FF_ALL_ARCHS_IOS6_SDK="armv7 armv7s i386"
FF_ALL_ARCHS_IOS7_SDK="armv7 armv7s arm64 i386 x86_64"
FF_ALL_ARCHS_IOS8_SDK="armv7 arm64 i386 x86_64"

FF_ALL_ARCHS_CUSTOM="armv7 arm64 i386 x86_64 arm64-simulator"

FF_ALL_ARCHS=$FF_ALL_ARCHS_CUSTOM

#----------
UNI_BUILD_ROOT=`pwd`
UNI_TMP="$UNI_BUILD_ROOT/tmp"
UNI_TMP_LLVM_VER_FILE="$UNI_TMP/llvm.ver.txt"
FF_TARGET=$1
set -e

#----------
FF_LIBS="libssl libcrypto"

#----------
echo_archs() {
    echo "===================="
    echo "[*] check xcode version"
    echo "===================="
    echo "FF_ALL_ARCHS = $FF_ALL_ARCHS"
}

do_lipo () {
    LIB_FILE=$1
    LIPO_FLAGS=
    LIPO_SIMULATOR_FLAGS=
    LIPO_IPHONE_FLAGS=
    LIPO_IPHONE_OUTPUT_HEADERS="$UNI_BUILD_ROOT/build/universal/iphone"
    LIPO_SIMULAROR_OUTPUT_HEADERS="$UNI_BUILD_ROOT/build/universal/simulator"
    for ARCH in $FF_ALL_ARCHS
    do
        LIPO_FLAGS="$LIPO_FLAGS $UNI_BUILD_ROOT/build/openssl-$ARCH/output/lib/$LIB_FILE"
        ARCH_LIB_FILE="$UNI_BUILD_ROOT/build/openssl-$ARCH/output/lib/$LIB_FILE.a"
        ARCH_LIB_HEADER="$UNI_BUILD_ROOT/build/openssl-$ARCH/output/include/$LIB_FILE"
        if [[ "${ARCH}" == "arm64" || "${ARCH}" == "armv7" ]]; then
            LIPO_IPHONE_FLAGS="$LIPO_IPHONE_FLAGS $ARCH_LIB_FILE"
        fi

        if [[ "${ARCH}" == "arm64-simulator" || "${ARCH}" == "x86_64" || "${ARCH}" == "i386" ]]; then
            LIPO_SIMULATOR_FLAGS="$LIPO_SIMULATOR_FLAGS $ARCH_LIB_FILE"
        fi
        
        echo "$ARCH_LIB_FILE"
        if [[ "${ARCH}" == "arm64-simulator" || "${ARCH}" == "arm64" ]]; then
            LIPO_FLAGS="$LIPO_FLAGS -library $ARCH_LIB_FILE -headers $ARCH_LIB_HEADER"
        fi
    done

    echo "lipo flags: $LIPO_FLAGS"
    echo "lipo simulator flags: $LIPO_SIMULATOR_FLAGS"
    echo "lipo iphone flags: $LIPO_IPHONE_FLAGS"

    LIPO_IPHONE_OUTPUT_LIB="$UNI_BUILD_ROOT/build/universal/iphone/$LIB_FILE.a"
    LIPO_SIMULATOR_OUTPUT_LIB="$UNI_BUILD_ROOT/build/universal/simulator/$LIB_FILE.a"

    xcrun lipo -create $LIPO_IPHONE_FLAGS -output $LIPO_IPHONE_OUTPUT_LIB
    xcrun lipo -create $LIPO_SIMULATOR_FLAGS -output $LIPO_SIMULATOR_OUTPUT_LIB

    xcodebuild -create-xcframework -library $LIPO_IPHONE_OUTPUT_LIB -library $LIPO_SIMULATOR_OUTPUT_LIB -output $UNI_BUILD_ROOT/build/universal/lib/$LIB_FILE.xcframework
}

do_lipo_all () {
    mkdir -p $UNI_BUILD_ROOT/build/universal/lib
    echo "lipo archs: $FF_ALL_ARCHS"
    for FF_LIB in $FF_LIBS
    do
        do_lipo "$FF_LIB";
    done

    cp -R $UNI_BUILD_ROOT/build/openssl-arm64/output/include $UNI_BUILD_ROOT/build/universal/
}

#----------
if [ "$FF_TARGET" = "armv7" -o "$FF_TARGET" = "armv7s" -o "$FF_TARGET" = "arm64" -o "$FF_TARGET" = "arm64-simulator" ]; then
    echo_archs
    sh tools/do-compile-openssl.sh $FF_TARGET
elif [ "$FF_TARGET" = "i386" -o "$FF_TARGET" = "x86_64" ]; then
    echo_archs
    sh tools/do-compile-openssl.sh $FF_TARGET
elif [ "$FF_TARGET" = "lipo" ]; then
    echo_archs
    do_lipo_all
elif [ "$FF_TARGET" = "all" ]; then
    echo_archs
    for ARCH in $FF_ALL_ARCHS
    do
        sh tools/do-compile-openssl.sh $ARCH
    done

    do_lipo_all
elif [ "$FF_TARGET" = "check" ]; then
    echo_archs
elif [ "$FF_TARGET" = "clean" ]; then
    echo_archs
    for ARCH in $FF_ALL_ARCHS
    do
        cd openssl-$ARCH && git clean -xdf && cd -
    done
else
    echo "Usage:"
    echo "  compile-openssl.sh armv7|arm64|i386|x86_64"
    echo "  compile-openssl.sh armv7s (obselete)"
    echo "  compile-openssl.sh lipo"
    echo "  compile-openssl.sh all"
    echo "  compile-openssl.sh clean"
    echo "  compile-openssl.sh check"
    exit 1
fi
