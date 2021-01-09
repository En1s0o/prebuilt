#!/bin/bash

LIB_NAME_LIBICONV="libiconv-1.16"
PKG_NAME_LIBICONV="${LIB_NAME_LIBICONV}.tar.gz"

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
mkdir -p ${OUT_DIR}/${LIB_NAME_LIBICONV}

tar -xvf ${DIR}/packages/${PKG_NAME_LIBICONV} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_LIBICONV}"

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
./configure --host=x86_64-w64-mingw32 --prefix=${OUT_DIR}/${LIB_NAME_LIBICONV} && \
make -j${JOBS} && \
make install -j${JOBS}

popd
