#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
loader=$(cat "$NIX_CC/nix-support/dynamic-linker")
for v in 4.4.5 4.5.0; do
  patchelf --set-interpreter "$loader" --set-rpath "$(dirname "$loader")" "builds/binary-$v/bin/cmake" || exit 2
  "builds/binary-$v/bin/cmake" --version | head -1
done
CMAKE_445="$PWD/builds/binary-4.4.5/bin/cmake" CMAKE_450="$PWD/builds/binary-4.5.0/bin/cmake" ./scripts/compare-versions.sh
