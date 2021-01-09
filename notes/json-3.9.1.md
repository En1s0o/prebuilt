# json-3.9.1

留意这个补丁，其实为了能让 spdlog 正常打印

```shell
patch_content=`echo "    template<typename OStream>\n    friend OStream& operator<<(OStream& o, const basic_json& j)"`
sed -i "/friend std::ostream& operator<<(std::ostream& o, const basic_json& j)/c\\$patch_content" ${OUT_DIR}/${LIB_NAME_JSON}/include/nlohmann/json.hpp
```

