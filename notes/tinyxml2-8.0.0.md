# tinyxml2-8.0.0

Windows 下，修改 CMakeLists.txt，一般情况都是放在 project 后面

```cmake
if(${MINGW})
    set(CMAKE_SHARED_LIBRARY_PREFIX "")
    set(CMAKE_STATIC_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_MODULE_PREFIX "")
endif()
```

