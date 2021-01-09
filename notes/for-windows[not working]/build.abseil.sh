#!/bin/bash

LIB_NAME_ABSL="abseil-cpp-20200923.2"
PKG_NAME_ABSL="${LIB_NAME_ABSL}.tar.gz"

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
mkdir -p ${OUT_DIR}/${LIB_NAME_ABSL}

tar -xvf ${PKG_DIR}/${PKG_NAME_ABSL} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_ABSL}"

mingw_patch=`echo "if(\\${MINGW})\n    set(CMAKE_SHARED_LIBRARY_PREFIX \"\")\n    set(CMAKE_STATIC_LIBRARY_PREFIX \"\")\n    set(CMAKE_SHARED_MODULE_PREFIX \"\")\nendif()"`
sed -i "/^project(absl /a\\$mingw_patch" CMakeLists.txt

# force shared
sed -i 's/set(ABSL_BUILD_DLL FALSE)/set(ABSL_BUILD_DLL TRUE)/g' absl/copts/AbseilConfigureCopts.cmake

# rename
sed -i 's/abseil_dll/absl/g' CMake/AbseilDll.cmake
sed -i 's/abseil_dll/absl/g' CMake/AbseilHelpers.cmake

# remove first
sed -i 's/"flags\/.*//g' CMake/AbseilDll.cmake
sed -i 's/"random\/.*//g' CMake/AbseilDll.cmake
# set(ABSL_INTERNAL_DLL_FILES ...)
flags_src=`ls absl/flags/{*.h,*.cc,internal/*.h,internal/*.cc} | grep -v "_test.cc$" | sed 's/absl\//  "/g' | sed 's/$/&"/g' | sed 's/\"/\\\"/g' | sed 's@\/@\\\/@g' | sed 's/\./\\\./g' | sed ':label;N;s/\n/\\\\n/g;b label'`
random_src=`ls absl/random/{*.h,*.cc,internal/*.h,internal/*.cc} | grep -v "_test.cc$" | sed 's/absl\//  "/g' | sed 's/$/&"/g' | sed 's/\"/\\\"/g' | sed 's@\/@\\\/@g' | sed 's/\./\\\./g' | sed ':label;N;s/\n/\\\\n/g;b label'`
sed -i "/set(ABSL_INTERNAL_DLL_FILES/a\\$flags_src" CMake/AbseilDll.cmake
sed -i "/set(ABSL_INTERNAL_DLL_FILES/a\\$random_src" CMake/AbseilDll.cmake
# remove benchmark
sed -i '/flags\/flag_benchmark/d' CMake/AbseilDll.cmake
sed -i '/random\/benchmarks/d' CMake/AbseilDll.cmake
sed -i '/random\/internal\/randen_benchmarks/d' CMake/AbseilDll.cmake
sed -i '/random\/internal\/nanobenchmark/d' CMake/AbseilDll.cmake

# set(ABSL_INTERNAL_DLL_TARGETS ...)
targets='\n  "strerror"\n  "flags_program_name"\n  "flags_config"\n  "flags_marshalling"\n  "flags_commandlineflag_internal"\n  "flags_commandlineflag"\n  "flags_private_handle_accessor"\n  "flags_reflection"\n  "flags_internal"\n  "flags"\n  "flags_usage_internal"\n  "flags_usage"\n  "flags_parse"\n  "random_internal_distribution_test_util"\n  "statusor"'
sed -i "/set(ABSL_INTERNAL_DLL_TARGETS/a\\$targets" CMake/AbseilDll.cmake

# for NOT Win
#sed -i ':label;N;s/[[:space:]]*PRIVATE[[:space:]]*ABSL_BUILD_DLL[[:space:]]*NOMINMAX//;b label' CMake/AbseilDll.cmake
sed -i 's/\${ABSL_DEFAULT_LINKOPTS}/${ABSL_DEFAULT_LINKOPTS}\n      \$<\$<BOOL:\${MINGW}>:"advapi32">\n      \$<\$<BOOL:\${MINGW}>:"bcrypt">\n      \$<\$<BOOL:${MINGW}>:"dbghelp">/g' CMake/AbseilDll.cmake
# sed -i ':label;N;s/[[:space:]]*ABSL_CONSUME_DLL//;b label' CMake/AbseilHelpers.cmake
#sed -i '/ABSL_CONSUME_DLL/d' CMake/AbseilHelpers.cmake

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p .build && \
cd .build && \
cmake ../ \
-DCMAKE_TOOLCHAIN_FILE=${DIR}/toolchain-mingw64.cmake \
-DCMAKE_BACKWARDS_COMPATIBILITY=2.6 \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_SHARED_LIBS=TRUE \
-DBUILD_TESTING=FALSE \
-DABSL_BUILD_DLL=TRUE \
-DABSL_ENABLE_INSTALL=TRUE \
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_INSTALL_PREFIX=${OUT_DIR}/${LIB_NAME_ABSL} && \
make -j${JOBS} && \
make install -j${JOBS}

popd
