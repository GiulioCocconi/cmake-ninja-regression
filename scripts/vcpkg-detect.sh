#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
root="$PWD"
vcpkg="$root/sources/vcpkg"
expected=9eec002df1cd109f8f104cd966a763daf9751489
[[ -d "$vcpkg/.git" && $(git -C "$vcpkg" rev-parse HEAD) == "$expected" ]] || { echo 'Pinned vcpkg checkout missing' >&2; exit 2; }
: "${NINJA:=$(command -v ninja)}"
mkdir -p logs builds
status=0
for version in 4.4.5 4.5.0; do
  case "$version" in
    4.4.5) exe="${CMAKE_445:-$root/builds/cmake-$version/bin/cmake}" ;;
    4.5.0) exe="${CMAKE_450:-$root/builds/cmake-$version/bin/cmake}" ;;
  esac
  [[ -x "$exe" ]] || { echo "$version executable missing" >&2; status=1; continue; }
  actual=$($exe --version | head -1)
  [[ "$actual" == "cmake version $version" ]] || { echo "wrong executable: $actual" >&2; status=1; continue; }
  build="$root/builds/detect-$version"
  rm -rf "$build"
  rm -f "$root/builds/compiler-cache-$version.json"
  "$exe" -S "$vcpkg/scripts/detect_compiler" -B "$build" -G Ninja --debug-trycompile \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=Linux -DCMAKE_MAKE_PROGRAM="$NINJA" \
    -DCMAKE_INSTALL_PREFIX="$root/builds/install-$version" \
    -DVCPKG_CHAINLOAD_TOOLCHAIN_FILE="$vcpkg/scripts/toolchains/linux.cmake" \
    -DCMAKE_TOOLCHAIN_FILE="$vcpkg/scripts/buildsystems/vcpkg.cmake" \
    -DVCPKG_TARGET_TRIPLET=x64-linux -DVCPKG_CRT_LINKAGE=dynamic \
    -DVCPKG_TARGET_ARCHITECTURE=x64 -DVCPKG_MANIFEST_INSTALL=OFF \
    -DBUILD_SHARED_LIBS=OFF -DVCPKG_SET_CHARSET_FLAG=ON -DVCPKG_PLATFORM_TOOLSET=external \
    -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON \
    -DCMAKE_FIND_PACKAGE_NO_SYSTEM_PACKAGE_REGISTRY=ON -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=TRUE \
    -DCMAKE_VERBOSE_MAKEFILE=ON -DVCPKG_APPLOCAL_DEPS=OFF -DCMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION=ON \
    -DVCPKG_CXX_FLAGS= -DVCPKG_CXX_FLAGS_RELEASE= -DVCPKG_CXX_FLAGS_DEBUG= \
    -DVCPKG_C_FLAGS= -DVCPKG_C_FLAGS_RELEASE= -DVCPKG_C_FLAGS_DEBUG= \
    -DVCPKG_LINKER_FLAGS= -DVCPKG_LINKER_FLAGS_RELEASE= -DVCPKG_LINKER_FLAGS_DEBUG= \
    -DCMAKE_INSTALL_LIBDIR:STRING=lib -DCMAKE_INSTALL_BINDIR:STRING=bin \
    "-DVCPKG_COMPILER_CACHE_FILE=$root/builds/compiler-cache-$version.json" \
    -D_VCPKG_ROOT_DIR="$vcpkg" -DZ_VCPKG_ROOT_DIR="$vcpkg" \
    -D_VCPKG_INSTALLED_DIR="$root/builds/installed-$version" \
    >"$root/logs/detect-$version.stdout" 2>"$root/logs/detect-$version.stderr"
  rc=$?
  printf '%s\n' "$rc" > "$root/logs/detect-$version.status"
  printf '%s: exit %s\n' "$version" "$rc"
  (( rc == 0 )) || status=1
done
exit "$status"
