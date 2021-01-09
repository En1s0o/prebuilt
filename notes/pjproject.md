# pjproject

这个需要修改很多才能满足我的要求

编译 Linux 平台下的程序，可以直接使用 pjproject-2.10.tar.gz，也可以使用 [git-source]pjproject.tar.gz

- [git-source]pjproject.tar.gz 是 git 管理的，里面包含了我对程序的修改记录

- 使用 [git-source]pjproject.tar.gz 编译 Linux 平台程序时，应该执行下面的命令 revert 掉一条记录

  > commit b1a0e6f031d8793f0b080ffd587951975bc537a7
  > Author: Eniso <eniso-92@qq.com>
  > Date:   Mon Sep 28 05:23:10 2020 -0700
  >
  >     删除动态库的主版本号，Windows dll 使用

  ```shell
  git revert b1a0e6f031d8793f0b080ffd587951975bc537a7
  ```

  这条记录只适合 Windows 平台，按照我的想法，Windows 平台的动态库应该是以 *.dll 结尾，而不需要 *.dll.2 这种结尾。

  但是在 Linux 平台，*.so.2 是很正常的，所以编译 Linux 平台程序时，revert 这条记录。



这个程序，也是在 Linux 下交叉编译 Windows 平台程序的。命令如下：

```shell
./configure --host=x86_64-w64-mingw32 --prefix=$(pwd)/out --enable-shared --disable-libwebrtc --with-ssl=${OUT_DIR}/${LIB_NAME_OPENSSL}
```

这要求先编译一个 Windows 平台的 openssl，其实 openssl 也是在 Linux 上交叉编译 Windows 平台程序的。

