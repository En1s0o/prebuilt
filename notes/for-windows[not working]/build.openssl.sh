#!/bin/bash

LIB_NAME_OPENSSL="openssl-1.1.1h"
PKG_NAME_OPENSSL="${LIB_NAME_OPENSSL}.tar.gz"

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
mkdir -p ${OUT_DIR}/${LIB_NAME_OPENSSL}

tar -xvf ${PKG_DIR}/${PKG_NAME_OPENSSL} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_OPENSSL}"

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
CROSS_COMPILE="x86_64-w64-mingw32-" ./Configure --prefix=${OUT_DIR}/${LIB_NAME_OPENSSL} mingw64 no-asm no-unit-test shared && \
make -j${JOBS} && \
make install -j${JOBS}

popd
