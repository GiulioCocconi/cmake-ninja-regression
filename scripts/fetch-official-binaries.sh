#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p sources builds logs
for v in 4.4.5 4.5.0; do
  base="cmake-$v-linux-x86_64.tar.gz"
  url="https://github.com/Kitware/CMake/releases/download/v$v"
  curl -fL --retry 2 -o "sources/$base" "$url/$base"
  curl -fL --retry 2 -o "sources/cmake-$v-SHA-256.txt" "$url/cmake-$v-SHA-256.txt"
  (cd sources && grep " $base\$" "cmake-$v-SHA-256.txt" | sha256sum -c -)
  mkdir -p "builds/binary-$v"
  tar -xzf "sources/$base" --strip-components=1 -C "builds/binary-$v"
done
