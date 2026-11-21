#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p sources builds logs
if [[ ! -d sources/cmake/.git ]]; then git clone https://github.com/Kitware/CMake.git sources/cmake; fi
if [[ ! -d sources/vcpkg/.git ]]; then git clone https://github.com/microsoft/vcpkg.git sources/vcpkg; fi
git -C sources/vcpkg checkout --detach 9eec002df1cd109f8f104cd966a763daf9751489
for v in 4.4.5 4.5.0; do
  src="$PWD/sources/cmake-$v"
  if [[ ! -d "$src" ]]; then git -C sources/cmake worktree add --detach "$src" "v$v"; fi
  cmake -S "$src" -B "builds/cmake-$v" -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
  cmake --build "builds/cmake-$v" --parallel "${JOBS:-2}"
  "builds/cmake-$v/bin/cmake" --version
done
