# CMake / Ninja compiler-detection investigation

This repository investigates a reported vcpkg compiler-detection failure on Ubuntu 26.04. It does **not** establish a CMake regression: on NixOS, both CMake 4.4.5 and 4.5.0 passed the basic and approximated vcpkg tests. A deliberately silent Ninja version probe reproduces the diagnostic in both versions; that experiment does not identify the CI failure's cause. See [REPORT.md](REPORT.md) for observations, limitations, and next steps.

## Reproduce on NixOS

The flake pins nixpkgs and supplies GCC, Ninja, build tools and strace. In a fresh clone:

```sh
nix develop path:. --command ./scripts/fetch-vcpkg.sh
nix develop path:. --command ./scripts/fetch-official-binaries.sh
nix develop path:. --command ./scripts/test-official-binaries.sh
nix develop path:. --command env CMAKE_445="$PWD/builds/binary-4.4.5/bin/cmake" CMAKE_450="$PWD/builds/binary-4.5.0/bin/cmake" ./scripts/vcpkg-detect.sh
nix develop path:. --command ./scripts/trace-detect.sh
n```

These commands download upstream release binaries and the pinned vcpkg revision. The Nix test adjusts the downloaded CMake executables' ELF interpreter and library path to use Nix glibc. Builds, downloads and new logs stay in ignored `builds/`, `sources/` and `logs/` directories. The tracked `evidence/` directory preserves selected outputs from the original experiments; paths inside those files describe the original machine, not the current checkout.

The `ninja-empty-version.sh` wrapper and `test-empty-version.sh` deliberately simulate a successful Ninja probe with no output. They are diagnostic controls, not a reproduction of the Ubuntu failure.

## Ubuntu GitHub Actions

[The manually dispatched workflow](.github/workflows/ubuntu-26.04-repro.yml) prepares an Ubuntu 26.04 runner with Emscripten and Qt, runs both CMake versions with the observed detector arguments, and uploads per-process strace files and configure results. **It has not yet been run or validated.** The workflow exercises the detector directly; it does not reproduce SILICON's outer manifest-install process. Review traces before sharing because process output and paths may contain environment details.

No issue or patch should be submitted until a version-specific failure is reproduced and diagnosed. The existing [issue draft](ISSUE-DRAFT.md) is incomplete.
