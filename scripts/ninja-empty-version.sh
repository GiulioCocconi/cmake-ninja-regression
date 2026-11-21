#!/usr/bin/env bash
# Diagnostic experiment only: simulate a successful, silent version probe.
if [[ ${1:-} == --version ]]; then exit 0; fi
exec "${NINJA_REAL:?}" "$@"
