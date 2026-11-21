#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p sources
if [[ ! -d sources/vcpkg/.git ]]; then
  git clone --no-checkout https://github.com/microsoft/vcpkg.git sources/vcpkg
fi
git -C sources/vcpkg checkout --detach 9eec002df1cd109f8f104cd966a763daf9751489
