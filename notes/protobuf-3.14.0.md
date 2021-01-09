# protobuf-3.14.0

Windows 下，修改 CMakeLists.txt，一般情况都是放在 project 后面

```cmake
if(${MINGW})
    set(CMAKE_SHARED_LIBRARY_PREFIX "")
    set(CMAKE_STATIC_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_MODULE_PREFIX "")
endif()
```



另外，还需要修改，用这种方式，虽然破坏了灵活性，但能解决各种水土不服

```cmake
if (protobuf_WITH_ZLIB)
  set(HAVE_ZLIB 1)
  set(ZLIB_INCLUDE_DIRECTORIES C:/prebuilt/out/zlib-1.2.11/include)
  set(ZLIB_LIBRARIES C:/prebuilt/out/zlib-1.2.11/bin/zlib.dll)
endif (protobuf_WITH_ZLIB)
```



修改 src/google/protobuf/port_def.inc，解决 MinGW 编译问题

```cpp
#if defined(_MSC_VER)
#define PROTOBUF_MAYBE_CONSTEXPR
#else
#define PROTOBUF_MAYBE_CONSTEXPR constexpr
#endif
```

改为（加上 || defined(_WIN32)）

```cpp
#if defined(_MSC_VER) || defined(_WIN32)
#define PROTOBUF_MAYBE_CONSTEXPR
#else
#define PROTOBUF_MAYBE_CONSTEXPR constexpr
#endif
```

