#!/bin/bash

LIB_NAME_DEBUG="debug"
LIB_NAME_BACKWARD="backward-cpp-1.5"
PKG_NAME_BACKWARD="${LIB_NAME_BACKWARD}.tar.gz"
LIB_NAME_BINUTILS="binutils-2.35.1"
PKG_NAME_BINUTILS="${LIB_NAME_BINUTILS}.tar.gz"

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
mkdir -p ${OUT_DIR}/${LIB_NAME_DEBUG}
mkdir -p ${OUT_DIR}/${LIB_NAME_BACKWARD}
mkdir -p ${OUT_DIR}/${LIB_NAME_BINUTILS}

tar -xvf ${PKG_DIR}/${PKG_NAME_BINUTILS} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_BINUTILS}"

sed -i '/"DWARF error: could not find "/,/(unsigned long) attr.u.val);/d' bfd/dwarf2.c

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
./configure --prefix=${OUT_DIR}/${LIB_NAME_BINUTILS} --enable-host-shared --enable-shared --with-pic && \
make -j${JOBS} && \
make install -j${JOBS}

popd


mkdir -p ${OUT_DIR}/${LIB_NAME_DEBUG}/include
mkdir -p ${OUT_DIR}/${LIB_NAME_DEBUG}/lib
tar -xvf ${PKG_DIR}/${PKG_NAME_BACKWARD} -C ${OUT_DIR}/${LIB_NAME_DEBUG}/include ${LIB_NAME_BACKWARD}/backward.hpp --strip-components 1
cp -arfL ${OUT_DIR}/${LIB_NAME_BINUTILS}/include/* ${OUT_DIR}/${LIB_NAME_DEBUG}/include
cp -arfL ${OUT_DIR}/${LIB_NAME_BINUTILS}/lib/libbfd* ${OUT_DIR}/${LIB_NAME_DEBUG}/lib
