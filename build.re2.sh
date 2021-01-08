#!/bin/bash

LIB_NAME_RE2="re2-2020-11-01"
PKG_NAME_RE2="${LIB_NAME_RE2}.tar.gz"

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
mkdir -p ${OUT_DIR}/${LIB_NAME_RE2}

tar -xvf ${PKG_DIR}/${PKG_NAME_RE2} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_RE2}"

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p .build && \
cd .build && \
cmake ../ \
-DCMAKE_BACKWARDS_COMPATIBILITY=2.6 \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=TRUE \
-DBUILD_TESTING=FALSE \
-DRE2_BUILD_TESTING=FALSE \
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_INSTALL_PREFIX=${OUT_DIR}/${LIB_NAME_RE2} && \
make -j${JOBS} && \
make install -j${JOBS}

popd
