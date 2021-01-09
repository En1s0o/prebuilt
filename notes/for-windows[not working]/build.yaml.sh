#!/bin/bash

LIB_NAME_YAML="yaml-cpp"
PKG_NAME_YAML="${LIB_NAME_YAML}.tar.gz"

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
mkdir -p ${OUT_DIR}/${LIB_NAME_YAML}

tar -xvf ${PKG_DIR}/${PKG_NAME_YAML} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_YAML}"

mingw_patch=`echo "if(\\${MINGW})\n    set(CMAKE_SHARED_LIBRARY_PREFIX \"\")\n    set(CMAKE_STATIC_LIBRARY_PREFIX \"\")\n    set(CMAKE_SHARED_MODULE_PREFIX \"\")\nendif()"`
sed -i "/^project(YAML_CPP/a\\$mingw_patch" CMakeLists.txt

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p .build && \
cd .build && \
cmake ../ \
-DCMAKE_TOOLCHAIN_FILE=${DIR}/toolchain-mingw64.cmake \
-DCMAKE_BACKWARDS_COMPATIBILITY=2.6 \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_TESTING=FALSE \
-DBUILD_SHARED_LIBS=TRUE \
-DYAML_CPP_BUILD_TESTS=FALSE \
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_INSTALL_PREFIX=${OUT_DIR}/${LIB_NAME_YAML} && \
make -j${JOBS} && \
make install -j${JOBS}

popd
