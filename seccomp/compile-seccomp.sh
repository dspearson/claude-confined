#!/bin/bash
# Compile the seccomp filter generator
# This script compiles the C program that generates seccomp BPF filters

set -e

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SOURCE="${SCRIPT_DIR}/generate-seccomp.c"
OUTPUT="${SCRIPT_DIR}/generate-seccomp"

# Check if already compiled and up-to-date
if [[ -x "${OUTPUT}" ]] && [[ "${OUTPUT}" -nt "${SOURCE}" ]]; then
    exit 0
fi

# Check if gcc and libseccomp-dev are available
if ! command -v gcc >/dev/null 2>&1; then
    echo "Error: gcc not found. Please install: sudo apt-get install gcc" >&2
    exit 1
fi

# Try to compile
if ! gcc -o "${OUTPUT}" "${SOURCE}" -lseccomp 2>/dev/null; then
    echo "Error: Failed to compile seccomp filter generator" >&2
    echo "Install libseccomp-dev with: sudo apt-get install libseccomp-dev" >&2
    exit 1
fi

chmod +x "${OUTPUT}"
echo "Compiled seccomp filter generator successfully" >&2
