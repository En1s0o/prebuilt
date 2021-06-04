#!/bin/bash

LIB_NAME_CPR="cpr-1.6.0"
PKG_NAME_CPR="${LIB_NAME_CPR}.tar.gz"
LIB_NAME_ZLIB="zlib-1.2.11"
LIB_NAME_OPENSSL="openssl-1.1.1h"
LIB_NAME_CURL="curl-7.73.0"

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
mkdir -p ${OUT_DIR}/${LIB_NAME_CPR}

tar -xvf ${PKG_DIR}/${PKG_NAME_CPR} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_CPR}"

sed -i "s/set(CMAKE_CXX_STANDARD 11)/set(CMAKE_CXX_STANDARD 17)/g" CMakeLists.txt

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p .build && \
cd .build && \
cmake ../ \
-DCMAKE_BACKWARDS_COMPATIBILITY=2.6 \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=TRUE \
-DBUILD_TESTING=FALSE \
-DCPR_BUILD_TESTS=OFF \
-DCPR_BUILD_TESTS_SSL=OFF \
-DCPR_FORCE_OPENSSL_BACKEND=ON \
-DCPR_FORCE_USE_SYSTEM_CURL=ON \
-DCURL_CONFIG_EXECUTABLE=${OUT_DIR}/${LIB_NAME_CURL}/bin/curl-config \
-DCURL_LIBRARY=${OUT_DIR}/${LIB_NAME_CURL} \
-DCURL_INCLUDE_DIR=${OUT_DIR}/${LIB_NAME_CURL}/include \
-DCURL_LIBRARY_DEBUG=${OUT_DIR}/${LIB_NAME_CURL}/lib/libcurl.so \
-DCURL_LIBRARY_RELEASE=${OUT_DIR}/${LIB_NAME_CURL}/lib/libcurl.so \
-DZLIB_INCLUDE_DIR=${OUT_DIR}/${LIB_NAME_ZLIB}/include \
-DZLIB_LIBRARY_DEBUG=${OUT_DIR}/${LIB_NAME_ZLIB}/lib/libz.so \
-DZLIB_LIBRARY_RELEASE=${OUT_DIR}/${LIB_NAME_ZLIB}/lib/libz.so \
-DOPENSSL_ROOT_DIR=${OUT_DIR}/${LIB_NAME_OPENSSL} \
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_INSTALL_PREFIX=${OUT_DIR}/${LIB_NAME_CPR} && \
find . -name "link.txt" | xargs sed -i 's/\-Wl,\-rpath,[^[:space:]]*[[:space:]]/\-Wl,\-rpath,"\\$ORIGIN:\\$ORIGIN\/lib:\\$ORIGIN\/..\/lib" /g' && \
make -j${JOBS} && \
make install -j${JOBS}

popd
