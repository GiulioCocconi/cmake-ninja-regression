# Draft — do not submit until reproduced and checked for duplicates

## Possible compiler detection failure with CMake 4.5.0 and Ninja

A CI build using vcpkg reports `The detected version of Ninja () is less than the version of Ninja required by CMake (1.3)` during the compiler ABI `try_compile`. The reporter observed a passing build with an older CMake and failure with 4.5.0. This observation has not yet been independently reproduced or isolated.

Expected: native C and C++ compiler detection succeeds with a working Ninja 1.13.2.

Actual: [Insert exact command, complete log, CMake executable path, Ninja subprocess invocation and exit status, and environment.]

Reproduction: [Insert smallest verified project and commands; compare 4.4.5 and 4.5.0 under identical conditions.]

Environment: [Insert verified OS, compiler, CMake and Ninja versions and vcpkg revision, if necessary.]

Root cause / related issues: [Unknown. Search both trackers for existing reports before submitting.]
