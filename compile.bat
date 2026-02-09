@echo off
setlocal
cd /d "%~dp0"

echo [INFO] Closing all AutoHotkey instances...
taskkill /F /IM "AutoHotkey.exe" /T >nul 2>&1
taskkill /F /IM "Windows-Sync.exe" /T >nul 2>&1

:: Paths
set "COMPILER=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
set "BASE=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
set "IN=windows-sync.ahk"
set "OUT=releases\Windows-Sync.exe"
set "ICON=icon.ico"

if not exist "%COMPILER%" (
    echo [ERROR] Compiler not found at: "%COMPILER%"
    pause
    exit /b 1
)

if not exist "releases" mkdir "releases"

echo [INFO] Compiling windows-sync...
"%COMPILER%" /in "%IN%" /out "%OUT%" /icon "%ICON%" /base "%BASE%"

if exist "%OUT%" (
    echo.
    echo [SUCCESS] Windows-Sync.exe created!
) else (
    echo.
    echo [ERROR] Compilation failed.
)

