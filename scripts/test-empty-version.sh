#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
export NINJA_REAL="$(command -v ninja)"
for v in 4.4.5 4.5.0; do
  rm -rf "builds/silent-ninja-$v"
  "builds/binary-$v/bin/cmake" -S repro/basic -B "builds/silent-ninja-$v" -G Ninja --debug-trycompile "-DCMAKE_MAKE_PROGRAM=$PWD/scripts/ninja-empty-version.sh" >"logs/silent-ninja-$v.stdout" 2>"logs/silent-ninja-$v.stderr"
  printf '%s: exit %s\n' "$v" "$?"
done
