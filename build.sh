#!/usr/bin/env bash
set -e -u -o pipefail

BUILD_MODE="debug"

PROJECT_NAME="nacto"
MAIN_FILE="main.nim"
OUTPUT_DIR="bin"

TARGET=""

# Helpers
set-linux() {
    TARGET="linux"
    NIM_OS=""
    EXT=""
}

set-windows() {
    TARGET="windows"
    NIM_OS="-d:mingw"
    EXT=".exe"
}

build() {
    mkdir -p "$OUTPUT_DIR"

    echo "Compiling $PROJECT_NAME for $TARGET..."
    nim c $NIM_OS --out:"$OUTPUT_DIR/$PROJECT_NAME$EXT" --path:"imports" --hints:on -d:$BUILD_MODE --warnings:on "$MAIN_FILE"

    cp -r "initfs" "$OUTPUT_DIR/initfs"

    echo "Build complete: $OUTPUT_DIR/$PROJECT_NAME$EXT"

    exit 0
}

# Non-interactive
case "${1:-}" in
    "linux")
        set-linux
        build
        ;;
    "windows")
        set-windows
        build
        ;;
    "")
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac

# Interactive
echo "What are you compiling for?"
echo "1. Linux"
echo "2. Windows"
read -rp "> " opt

case "$opt" in
    1)
        set-linux
        build
        ;;
    2)
        set-windows
        build
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac
