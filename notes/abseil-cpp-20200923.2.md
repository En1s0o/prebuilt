# abseil-cpp-20200923.2



> **注意**
>
> abseil 更新之后，编译脚本可能发送变化，最后生成的 cmake 需要同步更新到项目中



1、强制生成 DLL，在 Linux 下为 so
sed -i 's/set(ABSL_BUILD_DLL FALSE)/set(ABSL_BUILD_DLL TRUE)/g' absl/copts/AbseilConfigureCopts.cmake



2、这里希望生成的动态库为 libabsl.so 或者 absl.dll 而不是 libabseil_dll.so 或者 abseil_dll.dll
sed -i 's/abseil_dll/absl/g' CMake/AbseilDll.cmake
sed -i 's/abseil_dll/absl/g' CMake/AbseilHelpers.cmake



3、完成上述修改后，先编译一遍，看看最后生成的文件中，多出了哪些 .a，然后想办法把这些 .a 也加入动态库的链接中。例如：

> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_strerror.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_flags_program_name.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_flags_config.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_flags_marshalling.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_flags_commandlineflag_internal.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_flags_commandlineflag.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_flags_private_handle_accessor.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_flags_reflection.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_flags_internal.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_flags.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_flags_usage_internal.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_flags_usage.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_flags_parse.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_random_internal_distribution_test_util.a
> -- Installing: /home/eniso/prebuilt/out/abseil-cpp-20200923.2/lib/libabsl_statusor.a



那么需要处理的有：

> strerror
> flags
> random_internal_distribution_test_util
> statusor



需要这么做：

- 需要给 ABSL_INTERNAL_DLL_FILES 追加相应的 *.h *.cc 源码（有些可能已经在里面了，只是没有链接而已）
- 需要给 ABSL_INTERNAL_DLL_TARGETS 追加上面的库



> 其实，build.abseil.sh 已经做了：
>
> ```shell
> # 删除 flag 和 random 开头的源文件
> sed -i 's/"flags\/.*//g' CMake/AbseilDll.cmake
> sed -i 's/"random\/.*//g' CMake/AbseilDll.cmake
> # 加入 flag 和 random 所有源文件（这里需要把 test 文件移除）
> flags_src=`ls absl/flags/{*.h,*.cc,internal/*.h,internal/*.cc} | grep -v "_test.cc$" | sed 's/absl\//  "/g' | sed 's/$/&"/g' | sed 's/\"/\\\"/g' | sed 's@\/@\\\/@g' | sed 's/\./\\\./g' | sed ':label;N;s/\n/\\\\n/g;b label'`
> random_src=`ls absl/random/{*.h,*.cc,internal/*.h,internal/*.cc} | grep -v "_test.cc$" | sed 's/absl\//  "/g' | sed 's/$/&"/g' | sed 's/\"/\\\"/g' | sed 's@\/@\\\/@g' | sed 's/\./\\\./g' | sed ':label;N;s/\n/\\\\n/g;b label'`
> sed -i "/set(ABSL_INTERNAL_DLL_FILES/a\\$flags_src" CMake/AbseilDll.cmake
> sed -i "/set(ABSL_INTERNAL_DLL_FILES/a\\$random_src" CMake/AbseilDll.cmake
> # 性能测试的源文件也移除
> sed -i '/flags\/flag_benchmark/d' CMake/AbseilDll.cmake
> sed -i '/random\/benchmarks/d' CMake/AbseilDll.cmake
> sed -i '/random\/internal\/randen_benchmarks/d' CMake/AbseilDll.cmake
> sed -i '/random\/internal\/nanobenchmark/d' CMake/AbseilDll.cmake
> 
> # 添加链接到 dll 或者 so
> targets='\n  "strerror"\n  "flags_program_name"\n  "flags_config"\n  "flags_marshalling"\n  "flags_commandlineflag_internal"\n  "flags_commandlineflag"\n  "flags_private_handle_accessor"\n  "flags_reflection"\n  "flags_internal"\n  "flags"\n  "flags_usage_internal"\n  "flags_usage"\n  "flags_parse"\n  "random_internal_distribution_test_util"\n  "statusor"'
> sed -i "/set(ABSL_INTERNAL_DLL_TARGETS/a\\$targets" CMake/AbseilDll.cmake
> ```



如果不是 Windows 平台，需要删除：

>    PRIVATE
>        ABSL_BUILD_DLL
>        NOMINMAX

Windows 平台如果是使用 MinGW 编译，需要添加链接选项：

```cmake
      $<$<BOOL:${MINGW}>:"advapi32">
      $<$<BOOL:${MINGW}>:"bcrypt">
      $<$<BOOL:${MINGW}>:"dbghelp">
```



```shell
# 非 Windows 平台
sed -i ':label;N;s/[[:space:]]*PRIVATE[[:space:]]*ABSL_BUILD_DLL[[:space:]]*NOMINMAX//;b label' CMake/AbseilDll.cmake

# 给 MinGW 添加链接选项
sed -i 's/\${ABSL_DEFAULT_LINKOPTS}/${ABSL_DEFAULT_LINKOPTS}\n      \$<\$<BOOL:\${MINGW}>:"advapi32">\n      \$<\$<BOOL:\${MINGW}>:"bcrypt">\n      \$<\$<BOOL:${MINGW}>:"dbghelp">/g' CMake/AbseilDll.cmake

# 这个可能不需要，看情况定
# sed -i ':label;N;s/[[:space:]]*ABSL_CONSUME_DLL//;b label' CMake/AbseilHelpers.cmake
sed -i '/ABSL_CONSUME_DLL/d' CMake/AbseilHelpers.cmake
```



Windows 不希望以 lib 开头，可以在 CMakeLists.txt 添加

```cmake
if(${MINGW})
    set(CMAKE_SHARED_LIBRARY_PREFIX "")
    set(CMAKE_STATIC_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_MODULE_PREFIX "")
endif()
```



## 我一般是这么编译的

Linux 下，直接执行脚本编译。

Wihndows 下，先在 Linux 修改编译脚本，生成需要编译的代码，打包，再放到 Windows 下编译。本来想在 Linux 交叉编译 Windows 版本的二进制文件，但是经常出现难以解决的错误，所以直接放在 Windows 下编译了。

