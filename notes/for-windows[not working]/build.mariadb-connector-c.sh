#!/bin/bash

LIB_NAME_MARIADB_CONNECTOR_C="mariadb-connector-c-3.1.11"
PKG_NAME_MARIADB_CONNECTOR_C="${LIB_NAME_MARIADB_CONNECTOR_C}.tar.gz"
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
mkdir -p ${OUT_DIR}/${LIB_NAME_MARIADB_CONNECTOR_C}

tar -xvf ${PKG_DIR}/${PKG_NAME_MARIADB_CONNECTOR_C} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_MARIADB_CONNECTOR_C}"

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p .build && \
cd .build && \
cmake ../ \
-DCMAKE_BACKWARDS_COMPATIBILITY=2.6 \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_TESTING=FALSE \
-DWITH_SSL=ON \
-DOPENSSL_ROOT_DIR=${OUT_DIR}/${LIB_NAME_OPENSSL} \
-DCURL_INCLUDE_DIR=${OUT_DIR}/${LIB_NAME_CURL}/include \
-DCURL_LIBRARY_DEBUG=${OUT_DIR}/${LIB_NAME_CURL}/lib/libcurl.so \
-DCURL_LIBRARY_RELEASE=${OUT_DIR}/${LIB_NAME_CURL}/lib/libcurl.so \
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_INSTALL_PREFIX=${OUT_DIR}/${LIB_NAME_MARIADB_CONNECTOR_C} && \
find . -name "link.txt" | xargs sed -i 's/\-Wl,\-rpath,[^[:space:]]*[[:space:]]/\-Wl,\-rpath,"\\$ORIGIN:\\$ORIGIN\/lib:\\$ORIGIN\/..\/lib" /g' && \
make -j${JOBS} && \
make install -j${JOBS}

popd
