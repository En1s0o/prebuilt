#!/bin/bash

LIB_NAME_SQLPP11="sqlpp11-0.60"
PKG_NAME_SQLPP11="${LIB_NAME_SQLPP11}.tar.gz"
LIB_NAME_SQLPP11_CONNECTOR_MYSQL="sqlpp11-connector-mysql-0.29"
PKG_NAME_SQLPP11_CONNECTOR_MYSQL="${LIB_NAME_SQLPP11_CONNECTOR_MYSQL}.tar.gz"
LIB_NAME_DATE="date-3.0.0"
PKG_NAME_DATE="${LIB_NAME_DATE}.tar.gz"
LIB_NAME_MARIADB_CONNECTOR_C="mariadb-connector-c-3.1.11"
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
mkdir -p ${OUT_DIR}/${LIB_NAME_SQLPP11}
mkdir -p ${OUT_DIR}/${LIB_NAME_SQLPP11_CONNECTOR_MYSQL}

tar -xvf ${PKG_DIR}/${PKG_NAME_SQLPP11} -C ${BUILD_DIR}
tar -xvf ${PKG_DIR}/${PKG_NAME_SQLPP11_CONNECTOR_MYSQL} -C ${BUILD_DIR}
tar -xvf ${PKG_DIR}/${PKG_NAME_DATE} -C ${BUILD_DIR}

pushd "${BUILD_DIR}/${LIB_NAME_SQLPP11_CONNECTOR_MYSQL}"

sed -i "s/find_package_handle_standard_args(MYSQL/find_package_handle_standard_args(MySql/g" cmake/FindMySql.cmake

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p .build && \
cd .build && \
cmake ../ \
-DCMAKE_BACKWARDS_COMPATIBILITY=2.6 \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_TESTING=FALSE \
-DENABLE_TESTS=FALSE \
-DUSE_MARIADB=1 \
-DDATE_INCLUDE_DIR=${BUILD_DIR}/${LIB_NAME_DATE}/include \
-DSQLPP11_INCLUDE_DIR=${BUILD_DIR}/${LIB_NAME_SQLPP11}/include \
-DMYSQL_INCLUDE_DIR=${OUT_DIR}/${LIB_NAME_MARIADB_CONNECTOR_C}/include/mariadb \
-DMYSQL_LIBRARY=${OUT_DIR}/${LIB_NAME_MARIADB_CONNECTOR_C}/lib/mariadb/libmariadb.so \
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_INSTALL_PREFIX=${OUT_DIR}/${LIB_NAME_SQLPP11_CONNECTOR_MYSQL} && \
make -j${JOBS} && \
make install -j${JOBS}

popd


pushd "${BUILD_DIR}/${LIB_NAME_SQLPP11}"

date_inject=`echo "  URL      ${PKG_DIR}/${PKG_NAME_DATE}" | sed 's@\/@\\\/@g'`
sed -i "s/.*GIT_REPOSITORY.*/$date_inject/g" dependencies/CMakeLists.txt
sed -i "/.*GIT_TAG.*/d" dependencies/CMakeLists.txt

JOBS=`cat /proc/cpuinfo | grep processor | wc -l`
mkdir -p .build && \
cd .build && \
cmake ../ \
-DCMAKE_BACKWARDS_COMPATIBILITY=2.6 \
-DCMAKE_BUILD_TYPE=Release \
-DBUILD_TESTING=FALSE \
-DBUILD_TZ_LIB=TRUE \
-DCURL_INCLUDE_DIR=${OUT_DIR}/${LIB_NAME_CURL}/include \
-DCURL_LIBRARY_DEBUG=${OUT_DIR}/${LIB_NAME_CURL}/lib/libcurl.so \
-DCURL_LIBRARY_RELEASE=${OUT_DIR}/${LIB_NAME_CURL}/lib/libcurl.so \
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
-DCMAKE_INSTALL_PREFIX=${OUT_DIR}/${LIB_NAME_SQLPP11} && \
make -j${JOBS} && \
make install -j${JOBS}

popd
