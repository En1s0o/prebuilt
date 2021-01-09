#!/bin/bash

LIB_NAME_PROTOBUF="protobuf-3.14.0"
PKG_NAME_PROTOBUF="${LIB_NAME_PROTOBUF}.tar.gz"
LIB_NAME_ZLIB="zlib-1.2.11"

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
mkdir -p ${OUT_DIR}/${LIB_NAME_PROTOBUF}

tar -xvf ${PKG_DIR}/${PKG_NAME_PROTOBUF} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_PROTOBUF}"

mingw_patch=`echo "if(\\${MINGW})\n    set(CMAKE_SHARED_LIBRARY_PREFIX \"\")\n    set(CMAKE_STATIC_LIBRARY_PREFIX \"\")\n    set(CMAKE_SHARED_MODULE_PREFIX \"\")\nendif()"`
sed -i "/^project(protobuf/a\\$mingw_patch" cmake/CMakeLists.txt

# 暂时不知道怎样写
#src_patch=`echo "#if defined(_MSC_VER)\n#define PROTOBUF_MAYBE_CONSTEXPR"`
#dst_patch=`echo "#if defined(_MSC_VER) || defined(_WIN32)\n#define PROTOBUF_MAYBE_CONSTEXPR"`
#sed "/#if defined(_MSC_VER)/{n;/#define PROTOBUF_MAYBE_CONSTEXPR/{N;/.*/i\asdf}}" src/google/protobuf/port_def.inc

zlib_inject=`echo "  set(HAVE_ZLIB 1)\n  set(ZLIB_INCLUDE_DIRECTORIES ${OUT_DIR}/${LIB_NAME_ZLIB}/include)\n  set(ZLIB_LIBRARIES ${OUT_DIR}/${LIB_NAME_ZLIB}/bin/zlib.dll)\n" | sed 's@\/@\\\/@g'`
sed -i '/^if (protobuf_WITH_ZLIB)$/,/^endif (protobuf_WITH_ZLIB)$/{/^if (protobuf_WITH_ZLIB)$/b;/^endif (protobuf_WITH_ZLIB)$/b;/.*/d}' cmake/CMakeLists.txt
sed -i "/^if (protobuf_WITH_ZLIB)$/{n;s/^endif (protobuf_WITH_ZLIB)$/$zlib_inject&/g}" cmake/CMakeLists.txt
sed -i 's/PROPERTY INSTALL_RPATH "$ORIGIN.*/PROPERTY INSTALL_RPATH "\$ORIGIN:\$ORIGIN\/lib:\$ORIGIN\/..\/lib")/g' cmake/install.cmake

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p .build && \
cd .build && \
cmake ../cmake/ \
-DCMAKE_TOOLCHAIN_FILE=${DIR}/toolchain-mingw64.cmake \
-DCMAKE_BACKWARDS_COMPATIBILITY=2.6 \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=TRUE \
-DBUILD_TESTING=FALSE \
-Dprotobuf_BUILD_SHARED_LIBS=TRUE \
-Dprotobuf_WITH_ZLIB=TRUE \
-Dprotobuf_BUILD_TESTS=OFF \
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_INSTALL_PREFIX=${OUT_DIR}/${LIB_NAME_PROTOBUF} && \
find . -name "link.txt" | xargs sed -i 's/\-Wl,\-rpath,[^[:space:]]*[[:space:]]/\-Wl,\-rpath,"\\$ORIGIN:\\$ORIGIN\/lib:\\$ORIGIN\/..\/lib" /g' && \
make -j${JOBS} && \
make install -j${JOBS}

popd
