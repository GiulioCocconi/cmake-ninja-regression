# CMake 4.5 / Ninja compiler-detection investigation

## Executive summary

The reported regression is **not reproduced** in this NixOS environment. Official CMake 4.4.5 and 4.5.0 both configure the basic C/C++ project and the pinned vcpkg `detect_compiler` project successfully, with GCC 15.2.0 and Ninja 1.13.2 in the same Nix shell. The vcpkg command reproduces the supplied options and additional options found in the pinned port's implementation, but is not a recorded invocation from the failing Ubuntu runner. Therefore this does not disprove the reported Ubuntu failure or establish its cause.

A controlled diagnostic experiment shows that a Ninja wrapper that exits successfully **without printing a version** produces the same empty-version and compiler-ABI `try_compile` errors in *both* CMake versions. This demonstrates one way to produce the signature, not the cause of the original failure. A missing or uninitialized version field could also account for it.

## Environment and provenance

Pinned nixpkgs revision `a799d3e3886da994fa307f817a6bc705ae538eeb`, with lock and metadata at `flake.lock` and `evidence/flake-metadata.json`. `evidence/nix-toolchain.txt` records executable paths and versions: GCC/G++ 15.2.0, Ninja 1.13.2, Python 3.13.13, NixOS kernel 6.19.11. This environment differs from Ubuntu 26.04, and the test does not recreate the original Emscripten or CI environment.

The official upstream Linux release archives for CMake 4.4.5 and 4.5.0 were downloaded and verified against the SHA-256 files distributed alongside them; see `evidence/binary-fetch.log`. For NixOS execution, the extracted CMake executables were modified with `patchelf` to use the Nix shell's glibc interpreter and library directory. The archives remain unmodified. The vcpkg checkout is exactly `9eec002df1cd109f8f104cd966a763daf9751489`; CMake Git tags and history are present under `sources/cmake` for later source analysis and bisect. SHA-256 files were obtained over HTTPS from the same release source, but their PGP signatures were not independently verified.

## Version comparisons

| Experiment | 4.4.5 | 4.5.0 |
|---|---:|---:|
| Basic `project(... LANGUAGES C CXX)` and `check_c_source_compiles` | exit 0 | exit 0 |
| Pinned vcpkg `scripts/detect_compiler`, vcpkg toolchain and Linux chainload | exit 0 | exit 0 |
| Synthetic silent `ninja --version`, basic project | exit 1, empty-version diagnostic | exit 1, empty-version diagnostic |

Basic comparison is `evidence/comparison.json`; stdout and stderr are `evidence/basic-4.4.5.*` and `evidence/basic-4.5.0.*`. vcpkg comparison summary is `evidence/vcpkg-comparison-full.txt`, with full output in `evidence/detect-4.4.5.*` and `evidence/detect-4.5.0.*`. Config caches, configure logs and retained try-compile directories remain locally under the ignored `builds/basic-*` and `builds/detect-*`; they are not part of the repository. The latter script approximates the native x64-linux invocation, including flags from `scripts/cmake/vcpkg_configure_cmake.cmake`; compare against the exact CI command and environment before assuming complete equivalence. It does not run vcpkg's package installation process.

Synthetic experiment output is `evidence/silent-ninja-comparison.txt` and `evidence/silent-ninja-4.4.5.*` / `evidence/silent-ninja-4.5.0.*`. The wrapper `scripts/ninja-empty-version.sh` is intentionally defective and is **not** an authentic reproduction or recommended workaround.

## Commands

From this directory with Nix network/daemon access:

```sh
nix flake metadata --json path:. > evidence/flake-metadata.json
nix develop path:. --command ./scripts/fetch-vcpkg.sh
nix develop path:. --command ./scripts/fetch-official-binaries.sh
nix develop path:. --command ./scripts/test-official-binaries.sh
nix develop path:. --command env CMAKE_445="$PWD/builds/binary-4.4.5/bin/cmake" CMAKE_450="$PWD/builds/binary-4.5.0/bin/cmake" ./scripts/vcpkg-detect.sh
nix develop path:. --command ./scripts/trace-detect.sh
nix develop path:. --command ./scripts/test-empty-version.sh
```

`scripts/fetch-official-binaries.sh` downloads and verifies the official release archives; `scripts/fetch-build.sh` instead fetches exact tags and builds from source. A source build of 4.4.5 completed; the subsequent source build was stopped because the verified release binaries were already available. Set `CMAKE_445` and `CMAKE_450` to the desired actual executables when running `scripts/compare-versions.sh`. The commands clean their individual build directories. `scripts/trace-detect.sh` requires `strace` on PATH.

## Process trace and technical analysis

`evidence/detect-4.5.0.execve` records execution of the actual official 4.5.0 `cmake` binary and repeated executions of the same Nix-store Ninja with `--version`; all those observed Ninja version processes and the CMake process exited 0. No separate CMake executable appears in this trace during the internal `try_compile` configuration. This successful trace does not establish what happened in the failing Ubuntu environment. It captures process execution and exit, not the bytes written to stdout/stderr.

In both upstream tags, `cmGlobalNinjaGenerator::FindMakeProgram` obtains `CMAKE_MAKE_PROGRAM`, invokes it with `--version`, captures stdout and stderr separately, and trims stdout into `NinjaVersion`. It passes a null status pointer to `RunSingleCommand`; its implementation treats a nonzero exit status as failure and reports a different `Running ... failed with` error. A successful process producing empty stdout is accepted and can reach the minimum-version check with an empty string, as demonstrated here. Equally, an empty generator field caused by a different initialization path is not excluded. The relevant version-check implementation did not materially change between the two releases. `evidence/cmake-selected-history.txt` preserves selected source history, not a full causal analysis; the generated diff is retained locally in `logs/cmake-selected.diff`.

The detector starts `project(detect_compiler NONE)` then enables C and CXX separately. The vcpkg configure helper normally supplies `CMAKE_MAKE_PROGRAM` when it acquires Ninja, but its path behavior differs when `VCPKG_FORCE_SYSTEM_BINARIES` is defined. The original CI's actual process command, exact environment, and Ninja stdout/stderr/exit status are required to distinguish process output, different executable selection, generator initialization, and toolchain/environment interactions.

## Upstream reports, bisect, and next steps

Searches of CMake and vcpkg issue indexes on 2026-11-21 revealed no clearly matching 4.5 root-cause report, but indexing is incomplete. [vcpkg #33660](https://github.com/microsoft/vcpkg/issues/33660) has a similar secondary compiler error in a different situation; it is not an established duplicate. Search both official trackers directly, including closed issues, before filing.

No defensible good/bad test exists here, so a bisect cannot identify a first bad commit. No verified fix or upstream destination can be assigned. Obtain the complete failing Ubuntu `detect_compiler` command, parent and child environments, exact binaries and full stderr, then trace `execve`, stdout/stderr and status of each Ninja probe; compare with a 4.4.5 run with all other inputs unchanged. Preserve logs before minimizing. A draft in `ISSUE-DRAFT.md` remains incomplete and should not be submitted.

The user's reported workaround, CMake 3.31.10 with `VCPKG_FORCE_SYSTEM_BINARIES=1`, was not independently tested here. No SILICON files were changed and no issue, PR or patch was submitted.

## Public CI log attempt

The unauthenticated GitHub API initially returned HTTP 403 for the run log archive. The GitHub connector later retrieved the failed WASM job log and its exact detector command; the separate detector error log was not included. See the following section.

## Original Ubuntu Actions job recovered

The GitHub connector recovered the exact command from [the failed WASM job](https://github.com/GiulioCocconi/SILICON/actions/runs/44884091366/job/136789167018), image `ubuntu-26.04` version `20261116.202.1`. `evidence/original-ci-selected.log` preserves the exact command and selected environment lines. In that job, `LD_LIBRARY_PATH` included Python 3.15.2 and Qt 6.11.0 WebAssembly libraries; this is an observed difference from the earlier Nix test, not an established cause. The job log names separate configure output/error files but does not include their contents. The job output itself establishes a compiler-detection failure but does not display the empty Ninja version message.

`.github/workflows/ubuntu-26.04-repro.yml` is a prepared, **unexecuted** standalone workflow for a separate GitHub repository. It restores Emscripten and Qt, downloads the two releases, runs the original detector argument set with dynamic paths and traces execve, write, writev and exits into per-process files. It omits SILICON and its manifest/install nesting, so a failure difference could depend on those omissions. Running and inspecting it on a hosted runner remains necessary. The available GitHub connector does not expose workflow dispatch or repository creation, and SILICON changes are prohibited; no runner job was started.
