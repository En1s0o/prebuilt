# grpc-1.33.2

Linux 下，在 Ubuntu 18.04 LTS 中，需要给代码打补丁，不然出现一个 cpu 占用 100%，程序无法正常运行的情况，参考脚本：

```shell
patch_code=`echo "  for (TraceFlag\\* t = root_tracer_; t != nullptr; t = t->next_tracer_) {\n    if (t == flag) {\n      return;\n    }\n  }\n"`
sed -i "/^void TraceFlagList::Add(TraceFlag\* flag) {$/{n;s/^  flag->next_tracer_ = root_tracer_;$/$patch_code&/g}" src/core/lib/debug/trace.cc
```

其实，是修改 src/core/lib/debug/trace.cc

```cpp
void TraceFlagList::Add(TraceFlag* flag) {
  // >>> 补丁开始
  for (TraceFlag* t = root_tracer_; t != nullptr; t = t->next_tracer_) {
    if (t == flag) {
      return;
    }
  }
  // <<< 补丁结束
  flag->next_tracer_ = root_tracer_;
  root_tracer_ = flag;
}
```



Windows 下，修改 CMakeLists.txt

```cmake
if(${MINGW})
    set(CMAKE_SHARED_LIBRARY_PREFIX "")
    set(CMAKE_STATIC_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_MODULE_PREFIX "")
endif()
```



修改 cmake\zlib.cmake

```cmake
elseif(gRPC_ZLIB_PROVIDER STREQUAL "package")
  set(_gRPC_ZLIB_INCLUDE_DIR C:/prebuilt/out/zlib-1.2.11/include)
  set(_gRPC_ZLIB_LIBRARIES C:/prebuilt/out/zlib-1.2.11/bin/zlib.dll)
endif()
```



将 cares 代码解压到 third_party/cares/cares



> **注意**
>
> 到 out 路径下，拷贝 zlib.dll 到 protobuf 的 bin 路径下，因为 grpc 会用到 protoc.exe
>
> 到 out 路径下，拷贝下列库到 grpc 的编译路径下，才能通过编译
> absl.dll
> protobuf.dll
> protobuf-lite.dll
> protoc.dll
> zlib.dll

