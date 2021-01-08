#!/bin/bash

LIB_NAME_JSON="json-3.9.1-include"
PKG_NAME_JSON="${LIB_NAME_JSON}.zip"

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
mkdir -p ${OUT_DIR}/${LIB_NAME_JSON}

unzip -o ${PKG_DIR}/${PKG_NAME_JSON} "include/*" -d ${OUT_DIR}/${LIB_NAME_JSON}

patch_content=`echo "    template<typename OStream>\n    friend OStream& operator<<(OStream& o, const basic_json& j)"`
sed -i "/friend std::ostream& operator<<(std::ostream& o, const basic_json& j)/c\\$patch_content" ${OUT_DIR}/${LIB_NAME_JSON}/include/nlohmann/json.hpp
