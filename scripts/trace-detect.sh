#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
root=$PWD
v="$root/sources/vcpkg"
rm -rf builds/detect-trace-4.5.0
strace -f -s 4096 -e trace=execve -o logs/detect-4.5.0.execve \
 "$root/builds/binary-4.5.0/bin/cmake" -S "$v/scripts/detect_compiler" -B "$root/builds/detect-trace-4.5.0" -G Ninja --debug-trycompile \
 "-DCMAKE_MAKE_PROGRAM=$(command -v ninja)" -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=Linux \
 "-DCMAKE_TOOLCHAIN_FILE=$v/scripts/buildsystems/vcpkg.cmake" "-DVCPKG_CHAINLOAD_TOOLCHAIN_FILE=$v/scripts/toolchains/linux.cmake" \
 -DVCPKG_TARGET_TRIPLET=x64-linux -DVCPKG_CRT_LINKAGE=dynamic -DVCPKG_TARGET_ARCHITECTURE=x64 -DVCPKG_MANIFEST_INSTALL=OFF \
 > logs/detect-trace-4.5.0.stdout 2> logs/detect-trace-4.5.0.stderr
