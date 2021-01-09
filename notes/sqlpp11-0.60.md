# sqlpp11-0.60

dependencies/CMakeLists.txt

```cmake
FetchContent_Declare(date
    GIT_REPOSITORY https://github.com/HowardHinnant/date.git
    GIT_TAG        v3.0.0
) 
```

改为，专治各种水土不服

```cmake
FetchContent_Declare(date
  URL      C:/prebuilt/packages/date-3.0.0.tar.gz
) 
```



在 Linux 下，上述操作已经写在脚本上了

