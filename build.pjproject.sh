#!/bin/bash

LIB_NAME_PJPROJECT="pjproject-2.10"
PKG_NAME_PJPROJECT="${LIB_NAME_PJPROJECT}.tar.gz"
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
mkdir -p ${OUT_DIR}/${LIB_NAME_PJPROJECT}

tar -xvf ${PKG_DIR}/${PKG_NAME_PJPROJECT} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_PJPROJECT}"

echo -e "#ifndef OPENSSL\n#define OPENSSL\n#endif" > pjlib/include/pj/config_site.h

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
./configure --prefix=${OUT_DIR}/${LIB_NAME_PJPROJECT} --enable-shared --disable-libwebrtc --with-ssl=${OUT_DIR}/${LIB_NAME_OPENSSL} && \
make dep &&
make -j${JOBS} && \
make install -j${JOBS}

popd
