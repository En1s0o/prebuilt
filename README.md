## 说在前面的话

这里提供的脚本，能在 Ubuntu 18.04 LTS 中成功编译。Windows 并没有提供可以简化编译的脚本，取而代之的是 build.rar 编译参考，当然还有无法正确编译的参考脚本（为什么不把脚本开发好？因为本来就没有打算在 Windows 上运行，仅仅是为了能在 Windows 上开发），见路径 notes 。

编译后的产物不一定有 cmake，即使有，也不一定能正常使用。所以，我都是自己写一些符合自己的 cmake 脚本引入这些库。



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
>
> Windows 上编译方法，请参考 notes 笔记



## 调试库

backward-cpp 我觉得在 Linux 下挺好的，Windows 上目前并不好。

编译 binutils，可能需要修改 bfd/dwarf2.c，不然打印很多错误，具体怎么修改，根据版本情况才能确定。可以先不修改，编译一版，然后运用在有段错误的代码上，看看打印了哪些不必要的东西，然后再修改。



## 核心思想和强迫症观点

### 观点一

大部分情况，我们都希望在 Windows 下，库的名称不要出现 lib 开头，而在 Linux 则应该以 lib 开头，例如：zlib.dll、libz.so。所以一般情况下，Windows 下编译都会在 CMakeList.txt 加上：

```cmake
if(${MINGW})
    set(CMAKE_SHARED_LIBRARY_PREFIX "")
    set(CMAKE_STATIC_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_MODULE_PREFIX "")
endif()
```

当然，也有特殊情况，例如：libcurl.dll 就很合理，这种情况就可以不修改。



### 观点二

如果 bin / so 还依赖其他库，应该使用相对 RUNPATH。而我个人倾向使用：

```shell
 0x000000000000001d (RUNPATH)            Library runpath: [$ORIGIN:$ORIGIN/lib:$ORIGIN/../lib]
```

表示依赖库查找顺序：

- 从当前 so 库所在目录寻找，例如：

  > a.out
  >
  > liba.so

- 从当前 so 库所在目录的 lib 目录下寻找，例如：

  > a.out
  >
  > lib
  >
  > ​	liba.so

- 从当前 so 库所在目录的上级目录的 lib 目录寻找，例如：

  > bin
  >
  > ​	a.out
  >
  > lib
  >
  > ​	liba.so



```shell
eniso@ubuntu:~$ readelf -d out/zlib-1.2.11/lib/libz.so

Dynamic section at offset 0x1bdd0 contains 28 entries:
  Tag        Type                         Name/Value
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
 0x000000000000000e (SONAME)             Library soname: [libz.so.1]
 0x000000000000001d (RUNPATH)            Library runpath: [$ORIGIN:$ORIGIN/lib:$ORIGIN/../lib]
 0x000000000000000c (INIT)               0x20e8
 0x000000000000000d (FINI)               0x159e8
 0x0000000000000019 (INIT_ARRAY)         0x21bc70
 0x000000000000001b (INIT_ARRAYSZ)       8 (bytes)
 0x000000000000001a (FINI_ARRAY)         0x21bc78
 0x000000000000001c (FINI_ARRAYSZ)       8 (bytes)
 0x000000006ffffef5 (GNU_HASH)           0x1f0
 0x0000000000000005 (STRTAB)             0x10d0
 0x0000000000000006 (SYMTAB)             0x590
 0x000000000000000a (STRSZ)              1457 (bytes)
 0x000000000000000b (SYMENT)             24 (bytes)
 0x0000000000000003 (PLTGOT)             0x21c000
 0x0000000000000002 (PLTRELSZ)           1080 (bytes)
 0x0000000000000014 (PLTREL)             RELA
 0x0000000000000017 (JMPREL)             0x1cb0
 0x0000000000000007 (RELA)               0x19b0
 0x0000000000000008 (RELASZ)             768 (bytes)
 0x0000000000000009 (RELAENT)            24 (bytes)
 0x000000006ffffffc (VERDEF)             0x1778
 0x000000006ffffffd (VERDEFNUM)          14
 0x000000006ffffffe (VERNEED)            0x1960
 0x000000006fffffff (VERNEEDNUM)         1
 0x000000006ffffff0 (VERSYM)             0x1682
 0x000000006ffffff9 (RELACOUNT)          28
 0x0000000000000000 (NULL)               0x0

```



在 CMake 中想要实现这点，假设 CMakeLists.txt 写得好，那么只需要在生成 Makefile 时，指定以下参数即可：

```shell
-DCMAKE_INSTALL_RPATH="\$ORIGIN:\$ORIGIN/lib:\$ORIGIN/../lib" \
-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE \
-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE \
```



但是，这种假设有时候比较理想，所以还需要根据实际情况，修改生成的 Makefile。

即使很理想，但是我们如果依赖其他 so，这时还会把这些 so 的路径包含到 RUNPATH 中。

> 当然也可以在生成 bin / so 之后使用 patchelf 工具修改，我一般不这么做，即：
>
> ```shell
> patchelf --set-rpath '$ORIGIN:$ORIGIN/lib:$ORIGIN/../lib' libz.so
> ```

由于种种原因，我们可能需要在编译前，修改 RUNPATH，方法还不尽相同，我一般这样做：

> **注意**
>
> 下面代码均是放在 *.sh 里面执行，如果直接在命令行执行，**可能**写法会有所不同。
>
> 一会是：
>
> ```shell
> '"\$$ORIGIN:\$$ORIGIN/lib:\$$ORIGIN/../lib"'
> ```
>
> 一会是：
>
> ```shell
> "\\$ORIGIN:\\$ORIGIN\/lib:\\$ORIGIN\/..\/lib"
> ```
>
> 一会是：
>
> ```shell
> "\$ORIGIN:\$ORIGIN\/lib:\$ORIGIN\/..\/lib"
> ```
>
> ……
>
> 至于修改是否正确，需要通过 grep 找出 “-Wl,-rpath”，看看是否符合要求。
>
> CMake 中，以下命令满足大部分情况：
>
> ```shell
> find . -name "link.txt" | xargs sed -i 's/\-Wl,\-rpath,[^[:space:]]*[[:space:]]/\-Wl,\-rpath,"\\$ORIGIN:\\$ORIGIN\/lib:\\$ORIGIN\/..\/lib" /g'
> ```

- openssl

  ```shell
  ./Configure --prefix=${OUT_DIR}/${LIB_NAME_OPENSSL} linux-x86_64 no-asm no-unit-test shared -Wl,-rpath,'"\$$ORIGIN:\$$ORIGIN/lib:\$$ORIGIN/../lib"'
  ```

- libcurl

  ```shell
  find . -name "link.txt" | xargs sed -i 's/\-Wl,\-rpath,[^[:space:]]*[[:space:]]/\-Wl,\-rpath,"\\$ORIGIN:\\$ORIGIN\/lib:\\$ORIGIN\/..\/lib" /g'
  ```

- protobuf

  ```shell
  # 先做一些简单的替换，方便后面的匹配
  sed -i 's/PROPERTY INSTALL_RPATH "$ORIGIN.*/PROPERTY INSTALL_RPATH "\$ORIGIN:\$ORIGIN\/lib:\$ORIGIN\/..\/lib")/g' cmake/install.cmake
  ......
  # 有了上面操作，这里匹配就更加准确了
  find . -name "link.txt" | xargs sed -i 's/\-Wl,\-rpath,[^[:space:]]*[[:space:]]/\-Wl,\-rpath,"\\$ORIGIN:\\$ORIGIN\/lib:\\$ORIGIN\/..\/lib" /g'
  ```

