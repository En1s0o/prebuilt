## 编译

```shell
./build.sh
```

> 编译输出路径 ./out



重新编译

```shell
rm -rf build
rm -rf out
./build.sh
```



> **注意**
>
> 为了统一，已经将 abseil 和 grpc 的 C++ 版本设置为 C++17，即 -DCMAKE_CXX_STANDARD=17
>
> 在 Ubuntu 18.04 LTS 编译，使用正常



