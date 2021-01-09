#!/bin/bash

LIB_NAME_GRPC="grpc-1.33.2"
PKG_NAME_GRPC="${LIB_NAME_GRPC}.tar.gz"
LIB_NAME_CARES="c-ares-1.17.1"
PKG_NAME_CARES="${LIB_NAME_CARES}.tar.gz"
LIB_NAME_ZLIB="zlib-1.2.11"
LIB_NAME_OPENSSL="openssl-1.1.1h"
LIB_NAME_PROTOBUF="protobuf-3.14.0"
LIB_NAME_ABSL="abseil-cpp-20200923.2"
LIB_NAME_RE2="re2-2020-11-01"

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
mkdir -p ${OUT_DIR}/${LIB_NAME_GRPC}

tar -xvf ${PKG_DIR}/${PKG_NAME_GRPC} -C ${BUILD_DIR}
tar -xvf ${PKG_DIR}/${PKG_NAME_CARES} -C ${BUILD_DIR}/${LIB_NAME_GRPC}/third_party/cares/cares --strip-components 1

pushd "${BUILD_DIR}/${LIB_NAME_GRPC}"

mingw_patch=`echo "if(\\${MINGW})\n    set(CMAKE_SHARED_LIBRARY_PREFIX \"\")\n    set(CMAKE_STATIC_LIBRARY_PREFIX \"\")\n    set(CMAKE_SHARED_MODULE_PREFIX \"\")\nendif()"`
sed -i "/^project(/a\\$mingw_patch" CMakeLists.txt

zlib_inject=`echo "  set(_gRPC_ZLIB_INCLUDE_DIR ${OUT_DIR}/${LIB_NAME_ZLIB}/include)\n  set(_gRPC_ZLIB_LIBRARIES ${OUT_DIR}/${LIB_NAME_ZLIB}/bin/zlib.dll)\n" | sed 's@\/@\\\/@g'`
sed -i '/^elseif(gRPC_ZLIB_PROVIDER STREQUAL "package")$/,/^endif()$/{/^elseif(gRPC_ZLIB_PROVIDER STREQUAL "package")$/b;/^endif()$/b;/.*/d}' cmake/zlib.cmake
sed -i "/^elseif(gRPC_ZLIB_PROVIDER STREQUAL \"package\")$/{n;s/^endif()$/$zlib_inject&/g}" cmake/zlib.cmake

patch_code=`echo "  for (TraceFlag\\* t = root_tracer_; t != nullptr; t = t->next_tracer_) {\n    if (t == flag) {\n      return;\n    }\n  }\n"`
sed -i "/^void TraceFlagList::Add(TraceFlag\* flag) {$/{n;s/^  flag->next_tracer_ = root_tracer_;$/$patch_code&/g}" src/core/lib/debug/trace.cc

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p .build && \
mkdir -p ${OUT_DIR}/${LIB_NAME_GRPC}/bin && \
cp -arfL ${OUT_DIR}/${LIB_NAME_PROTOBUF}/lib/libproto* .build && \
cp -arfL ${OUT_DIR}/${LIB_NAME_PROTOBUF}/lib/libproto* ${OUT_DIR}/${LIB_NAME_GRPC}/bin && \
cd .build && \
cmake ../ \
-DCMAKE_TOOLCHAIN_FILE=${DIR}/toolchain-mingw64.cmake \
-DCMAKE_BACKWARDS_COMPATIBILITY=2.6 \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=TRUE \
-DBUILD_TESTING=FALSE \
-DCARES_BUILD_TOOLS=TRUE \
-DCARES_SHARED=TRUE \
-DCARES_STATIC=TRUE \
-DCARES_STATIC_PIC=TRUE \
-DABSL_ENABLE_INSTALL=TRUE \
-DINSTALL_BIN_DIR=${OUT_DIR}/${LIB_NAME_GRPC}/bin \
-DINSTALL_INC_DIR=${OUT_DIR}/${LIB_NAME_GRPC}/include \
-DINSTALL_LIB_DIR=${OUT_DIR}/${LIB_NAME_GRPC}/lib \
-DINSTALL_MAN_DIR=${OUT_DIR}/${LIB_NAME_GRPC}/share/man \
-DINSTALL_PKGCONFIG_DIR=${OUT_DIR}/${LIB_NAME_GRPC}/lib/pkgconfig \
-DOPENSSL_ROOT_DIR=${OUT_DIR}/${LIB_NAME_OPENSSL} \
-DProtobuf_DIR=${OUT_DIR}/${LIB_NAME_PROTOBUF}/lib/cmake/protobuf \
-DZLIB_DIR=${OUT_DIR}/${LIB_NAME_ZLIB} \
-Dabsl_DIR=${OUT_DIR}/${LIB_NAME_ABSL}/lib/cmake/absl \
-DgRPC_ABSL_PROVIDER=package \
-DgRPC_BACKWARDS_COMPATIBILITY_MODE=TRUE \
-DgRPC_BUILD_TESTS=FALSE \
-DgRPC_BUILD_CODEGEN=TRUE \
-DgRPC_BUILD_GRPC_CPP_PLUGIN=TRUE \
-DgRPC_BUILD_GRPC_CSHARP_PLUGIN=FALSE \
-DgRPC_BUILD_GRPC_NODE_PLUGIN=FALSE \
-DgRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=FALSE \
-DgRPC_BUILD_GRPC_PHP_PLUGIN=FALSE \
-DgRPC_BUILD_GRPC_PYTHON_PLUGIN=FALSE \
-DgRPC_BUILD_GRPC_RUBY_PLUGIN=FALSE \
-DgRPC_CARES_PROVIDER=module \
-DgRPC_INSTALL=TRUE \
-DgRPC_PROTOBUF_PACKAGE_TYPE=CONFIG \
-DgRPC_PROTOBUF_PROVIDER=package \
-DgRPC_RE2_PROVIDER=package \
-DgRPC_SSL_PROVIDER=package \
-DgRPC_USE_PROTO_LITE=FALSE \
-DgRPC_ZLIB_PROVIDER=package \
-Dre2_DIR=${OUT_DIR}/${LIB_NAME_RE2}/lib/cmake/re2 \
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_INSTALL_PREFIX=${OUT_DIR}/${LIB_NAME_GRPC} && \
find . -name "link.txt" | xargs sed -i 's/\-Wl,\-rpath,[^[:space:]]*[[:space:]]/\-Wl,\-rpath,"\\$ORIGIN:\\$ORIGIN\/lib:\\$ORIGIN\/..\/lib" /g' && \
make -j${JOBS} && \
make install -j${JOBS} && \
mkdir -p ${OUT_DIR}/${LIB_NAME_CARES}/include && \
mkdir -p ${OUT_DIR}/${LIB_NAME_CARES}/lib && \
mkdir -p ${OUT_DIR}/${LIB_NAME_CARES}/lib/pkgconfig && \
mkdir -p ${OUT_DIR}/${LIB_NAME_CARES}/lib/cmake/c-ares && \
mv -f ${OUT_DIR}/${LIB_NAME_GRPC}/include/ares* ${OUT_DIR}/${LIB_NAME_CARES}/include && \
mv -f ${OUT_DIR}/${LIB_NAME_GRPC}/lib/libcares* ${OUT_DIR}/${LIB_NAME_CARES}/lib && \
mv -f ${OUT_DIR}/${LIB_NAME_GRPC}/lib/pkgconfig/libcares.pc ${OUT_DIR}/${LIB_NAME_CARES}/lib/pkgconfig && \
mv -f ${OUT_DIR}/${LIB_NAME_GRPC}/lib/cmake/c-ares/* ${OUT_DIR}/${LIB_NAME_CARES}/lib/cmake/c-ares

popd
