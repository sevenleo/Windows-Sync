@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

:: ==========================================================
:: PATH SETTINGS
:: ==========================================================
set SCRIPT_NAME=windows-sync.ahk
set EXE_NAME=Windows-Sync.exe
set ICON_NAME=icon.ico

:: Likely paths for the Compiler and the V2 engine
set AHK_V2_EXE=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe
set COMPILER_V2=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe

echo ==========================================
echo       Windows-Sync - V2 Compiler
echo ==========================================

:: Check if the icon file exists
if exist "%ICON_NAME%" (
    set HAS_ICON=1
    echo [+] Icon found: %ICON_NAME%
) else (
    set HAS_ICON=0
    echo [!] WARNING: %ICON_NAME% not found.
)

:: Check if the V2 engine exists
if not exist "%AHK_V2_EXE%" (
    echo [ERROR] AutoHotkey v2 not found in:
    echo "%AHK_V2_EXE%"
    echo Please check if AutoHotkey v2 is installed.
    pause
    exit /b
)

:: Check if the Compiler exists
if not exist "%COMPILER_V2%" (
    :: Try alternative v2 path
    if exist "C:\Program Files\AutoHotkey\v2\Compiler\Ahk2Exe.exe" (
        set COMPILER_V2=C:\Program Files\AutoHotkey\v2\Compiler\Ahk2Exe.exe
    ) else (
        echo [ERROR] Ahk2Exe.exe not found.
        echo Please install the AutoHotkey compiler.
        pause
        exit /b
    )
)

echo [+] Compiler: "%COMPILER_V2%"
echo [+] Using V2 engine: "%AHK_V2_EXE%"

:: Execute compilation
if %HAS_ICON% EQU 1 (
    echo [^>] Compiling with icon...
    "%COMPILER_V2%" /in "%SCRIPT_NAME%" /out "%EXE_NAME%" /icon "%ICON_NAME%" /bin "%AHK_V2_EXE%"
) else (
    echo [^>] Compiling without icon...
    "%COMPILER_V2%" /in "%SCRIPT_NAME%" /out "%EXE_NAME%" /bin "%AHK_V2_EXE%"
)

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [SUCCESS] File %EXE_NAME% generated successfully!
) else (
    echo.
    echo [ERROR] Compilation failed. Code: %ERRORLEVEL%
    echo Verify if the paths above are correct on your PC.
)

echo.
pause