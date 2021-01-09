#!/bin/bash

LIB_NAME_LIBEVENT="libevent-2.1.12-stable"
PKG_NAME_LIBEVENT="${LIB_NAME_LIBEVENT}.tar.gz"
LIB_NAME_OPENSSL="openssl-1.1.1h"

if [ "." == $(dirname $BASH_SOURCE) ]; then
  DIR=$(pwd)
elif [ "/" == ${BASH_SOURCE:0:1} ]; then
  DIR=$(dirname $BASH_SOURCE)
else
  DIR=$(pwd)/$(dirname $BASH_SOURCE)
fi

PKG_DIR=${DIR}/packages
BUILD_DIR=${DIR}/build
OUT_DIR=${DIR}/out

mkdir -p ${BUILD_DIR}
mkdir -p ${OUT_DIR}/${LIB_NAME_LIBEVENT}

tar -xvf ${PKG_DIR}/${PKG_NAME_LIBEVENT} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_LIBEVENT}"

mingw_patch=`echo "if(\\${MINGW})\n    set(CMAKE_SHARED_LIBRARY_PREFIX \"\")\n    set(CMAKE_STATIC_LIBRARY_PREFIX \"\")\n    set(CMAKE_SHARED_MODULE_PREFIX \"\")\nendif()"`
sed -i "/^project(libevent/a\\$mingw_patch" CMakeLists.txt

sed -i 's/INSTALL_RPATH "\${CMAKE_INSTALL_PREFIX}\/lib")/INSTALL_RPATH "\$ORIGIN:\$ORIGIN\/lib:\$ORIGIN\/..\/lib")/g' cmake/AddEventLibrary.cmake

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p .build && \
cd .build && \
cmake ../ \
-DCMAKE_TOOLCHAIN_FILE=${DIR}/toolchain-mingw64.cmake \
-DCMAKE_BACKWARDS_COMPATIBILITY=2.6 \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_TESTING=FALSE \
-DEVENT__DISABLE_BENCHMARK=TRUE \
-DEVENT__DISABLE_DEBUG_MODE=TRUE \
-DEVENT__DISABLE_REGRESS=TRUE \
-DEVENT__DISABLE_SAMPLES=TRUE \
-DEVENT__DISABLE_TESTS=TRUE \
-DEVENT__ENABLE_GCC_HARDENING=TRUE \
-DEVENT__LIBRARY_TYPE=shared \
-DOPENSSL_ROOT_DIR=${OUT_DIR}/${LIB_NAME_OPENSSL} \
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_INSTALL_PREFIX=${OUT_DIR}/${LIB_NAME_LIBEVENT} && \
find . -name "link.txt" | xargs sed -i 's/\-Wl,\-rpath,[^[:space:]]*[[:space:]]/\-Wl,\-rpath,"\\$ORIGIN:\\$ORIGIN\/lib:\\$ORIGIN\/..\/lib" /g' && \
make -j${JOBS} && \
make install -j${JOBS}

popd
