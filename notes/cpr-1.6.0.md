# cpr-1.6.0

Windows 下，修改 CMakeLists.txt，一般情况都是放在 project 后面

```cmake
if(${MINGW})
    set(CMAKE_SHARED_LIBRARY_PREFIX "")
    set(CMAKE_STATIC_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_MODULE_PREFIX "")
endif()
```



将 `set(CMAKE_CXX_STANDARD 11)` 改为 `set(CMAKE_CXX_STANDARD 17)`

将 `find_package(CURL COMPONENTS HTTP HTTPS SSL)` 改为 `find_package(CURL)`

另外，如果还有报错，可以注释下面几行

```cmake
            #if(CMAKE_USE_OPENSSL AND WIN32 AND (NOT (CURL_VERSION_STRING VERSION_GREATER_EQUAL "7.71.0")))
            #    message(FATAL_ERROR "Your system curl version (${CURL_VERSION_STRING}) is too old to support OpenSSL on Windows which requires curl >= 7.71.0. Update your curl version, use WinSSL, disable SSL or use the build in version of curl.")
            #endif()
```

