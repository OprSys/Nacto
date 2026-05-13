@echo off
setlocal enabledelayedexpansion

set PROJECT_NAME=nacto
set MAIN_FILE=main.nim
set OUTPUT_DIR=bin

echo What are you compiling for?
echo 1. Linux
echo 2. Windows
set /p opt=^> 

if "%opt%"=="1" (
    set TARGET=linux
    set NIM_OS=
    set EXT=
) else if "%opt%"=="2" (
    set TARGET=windows
    set NIM_OS=-d:mingw
    set EXT=.exe
) else (
    echo Invalid option.
    exit /b 1
)

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo Compiling %PROJECT_NAME% for %TARGET%...
nim c %NIM_OS% --out:"%OUTPUT_DIR%/%PROJECT_NAME%%EXT%" --path:"imports" --hints:on --warnings:on "%MAIN_FILE%"

xcopy /E /I "initramfs" "%OUTPUT_DIR%/initramfs"
echo Build complete: %OUTPUT_DIR%/%PROJECT_NAME%%EXT%
