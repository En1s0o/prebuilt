# this is required
SET(CMAKE_SYSTEM_NAME Windows)
SET(CMAKE_SYSTEM_PROCESSOR x86_64)

# specify the cross compiler
SET(CROSS_COMPILER x86_64-w64-mingw32-)
SET(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc-posix)
SET(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++-posix)
SET(CMAKE_RC_COMPILER x86_64-w64-mingw32-windres)
SET(CMAKE_RANLIB x86_64-w64-mingw32-gcc-ranlib-posix)
SET(CMAKE_AR x86_64-w64-mingw32-gcc-ar-posix)
SET(CMAKE_LD x86_64-w64-mingw32-ld)
SET(CMAKE_NM x86_64-w64-mingw32-gcc-nm-posix)
SET(CMAKE_STRIP x86_64-w64-mingw32-strip)

# where is the target environment 
#SET(CMAKE_FIND_ROOT_PATH /usr/share/mingw-w64/include)

# search for programs in the build host directories (not necessary)
#SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
#SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
#SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
