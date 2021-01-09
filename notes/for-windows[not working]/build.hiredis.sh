#!/bin/bash

LIB_NAME_HIREDIS="hiredis-1.0.0"
PKG_NAME_HIREDIS="${LIB_NAME_HIREDIS}.tar.gz"
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
mkdir -p ${OUT_DIR}/${LIB_NAME_HIREDIS}

tar -xvf ${PKG_DIR}/${PKG_NAME_HIREDIS} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_HIREDIS}"

mingw_patch=`echo "if(\\${MINGW})\n    set(CMAKE_SHARED_LIBRARY_PREFIX \"\")\n    set(CMAKE_STATIC_LIBRARY_PREFIX \"\")\n    set(CMAKE_SHARED_MODULE_PREFIX \"\")\nendif()"`
sed -i "/^PROJECT(hiredis/a\\$mingw_patch" CMakeLists.txt

sed -i 's/static void redisLibeventHandler(int fd/static void redisLibeventHandler(evutil_socket_t fd/g' adapters/libevent.h

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p .build && \
cd .build && \
cmake ../ \
-DCMAKE_BACKWARDS_COMPATIBILITY=2.6 \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_TESTING=FALSE \
-DBUILD_SHARED_LIBS=TRUE \
-DDISABLE_TESTS=TRUE \
-DENABLE_SSL=TRUE \
-DOPENSSL_ROOT_DIR=${OUT_DIR}/${LIB_NAME_OPENSSL} \
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_INSTALL_PREFIX=${OUT_DIR}/${LIB_NAME_HIREDIS} && \
find . -name "link.txt" | xargs sed -i 's/\-Wl,\-rpath,[^[:space:]]*[[:space:]]/\-Wl,\-rpath,"\\$ORIGIN:\\$ORIGIN\/lib:\\$ORIGIN\/..\/lib" /g' && \
make -j${JOBS} && \
make install -j${JOBS}

popd
