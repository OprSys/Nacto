#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="nacto"
MAIN_FILE="main.nim"
OUTPUT_DIR="bin"

echo "What are you compiling for?"
echo "1. Linux"
echo "2. Windows"
read -rp "> " opt

case "$opt" in
    1)
        TARGET="linux"
        NIM_OS=""
        EXT=""
        ;;
    2)
        TARGET="windows"
        NIM_OS="-d:mingw"
        EXT=".exe"
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac

mkdir -p "$OUTPUT_DIR"

echo "Compiling $PROJECT_NAME for $TARGET..."
nim c $NIM_OS --out:"$OUTPUT_DIR/$PROJECT_NAME$EXT" --path:"imports" --hints:on --warnings:on "$MAIN_FILE"

cp -r initramfs "$OUTPUT_DIR/initramfs"
echo "Build complete: $OUTPUT_DIR/$PROJECT_NAME$EXT"
