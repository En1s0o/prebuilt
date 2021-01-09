# sqlpp11-connector-mysql-0.29

cmake/FindMySql.cmake

```cmake
find_package_handle_standard_args(MYSQL
  FOUND_VAR MYSQL_FOUND
  REQUIRED_VARS MYSQL_LIBRARY MYSQL_INCLUDE_DIR
  )
```

改为（MYSQL 改为 MySql）

```cmake
find_package_handle_standard_args(MySql
  FOUND_VAR MYSQL_FOUND
  REQUIRED_VARS MYSQL_LIBRARY MYSQL_INCLUDE_DIR
  )
```



在 Linux 下，上述操作已经写在脚本上了，参考：

```shell
sed -i "s/find_package_handle_standard_args(MYSQL/find_package_handle_standard_args(MySql/g" cmake/FindMySql.cmake
```

