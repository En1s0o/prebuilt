#!/bin/bash

LIB_NAME_CURL="curl-7.73.0"
PKG_NAME_CURL="${LIB_NAME_CURL}.tar.gz"
LIB_NAME_CARES="c-ares-1.17.1"
LIB_NAME_ZLIB="zlib-1.2.11"
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
mkdir -p ${OUT_DIR}/${LIB_NAME_CURL}

tar -xvf ${PKG_DIR}/${PKG_NAME_CURL} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_CURL}"

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p .build && \
cd .build && \
cmake ../ \
-DCMAKE_BACKWARDS_COMPATIBILITY=2.6 \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=TRUE \
-DBUILD_TESTING=FALSE \
-DBUILD_CURL_EXE=TRUE \
-DCMAKE_USE_OPENSSL=TRUE \
-DCURL_ZLIB=TRUE \
-DENABLE_ARES=TRUE \
-DOPENSSL_ROOT_DIR=${OUT_DIR}/${LIB_NAME_OPENSSL} \
-DCARES_INCLUDE_DIR=${OUT_DIR}/${LIB_NAME_CARES}/include \
-DCARES_LIBRARY=${OUT_DIR}/${LIB_NAME_CARES}/lib/libcares.so \
-DZLIB_INCLUDE_DIR=${OUT_DIR}/${LIB_NAME_ZLIB}/include \
-DZLIB_LIBRARY_DEBUG=${OUT_DIR}/${LIB_NAME_ZLIB}/lib/libz.so \
-DZLIB_LIBRARY_RELEASE=${OUT_DIR}/${LIB_NAME_ZLIB}/lib/libz.so \
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_INSTALL_PREFIX=${OUT_DIR}/${LIB_NAME_CURL} && \
find . -name "link.txt" | xargs sed -i 's/\-Wl,\-rpath,[^[:space:]]*[[:space:]]/\-Wl,\-rpath,"\\$ORIGIN:\\$ORIGIN\/lib:\\$ORIGIN\/..\/lib" /g' && \
make -j${JOBS} && \
make install -j${JOBS}

popd
