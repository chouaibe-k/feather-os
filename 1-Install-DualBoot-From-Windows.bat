@echo off
title FeatherOS - 1-Click Windows Dual-Boot Installer
color 1F
echo ============================================================================
echo   FEATHER-OS: ULTRA-LIGHTWEIGHT WINDOWS-STYLE DUAL-BOOT INSTALLER
echo ============================================================================
echo.
echo   This script automatically downloads, extracts, and launches the visual
echo   Dual-Boot Setup Wizard (q4os-winsetup.exe) right inside Windows!
echo.
echo   - Your existing Windows and personal files stay 100%% safe and untouched.
echo   - Recommended disk size in the wizard: 15 GB to 25 GB
echo   - Recommended desktop profile: "Trinity" (uses only ~140 MB RAM!)
echo.
echo ============================================================================
echo.

set "WORK_DIR=%USERPROFILE%\Downloads\FeatherOS-Installer"
set "ZIP_PATH=%WORK_DIR%\q4os-winsetup.zip"
set "EXE_PATH=%WORK_DIR%\q4os-winsetup.exe"
set "DOWNLOAD_URL=https://sourceforge.net/projects/q4os/files/stable/q4os-winsetup-6.10-r1.zip/download"

if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"

echo [1/3] Downloading the Dual-Boot Installer (33 MB)...
where curl.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    curl.exe -L -A "Wget/1.21" "%DOWNLOAD_URL%" -o "%ZIP_PATH%"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -UserAgent 'Wget/1.21' -OutFile '%ZIP_PATH%' -UseBasicParsing"
)

echo [2/3] Extracting q4os-winsetup.exe...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%WORK_DIR%' -Force" 2>nul

for /r "%WORK_DIR%" %%F in (*winsetup*.exe) do set "EXE_PATH=%%F"

if exist "%EXE_PATH%" (
    echo [3/3] Launching Dual-Boot Setup Wizard...
    echo (If Windows asks "Do you want to allow this app to make changes", click YES)
    start "" "%EXE_PATH%"
) else (
    echo Automatic download was blocked by your browser/network.
    echo Opening the official download page — click "Q4OS Andromeda, WinSetup.exe":
    start "" "https://www.q4os.org/downloads1.html"
)

echo.
echo ============================================================================
echo   WHAT TO DO NEXT:
echo   1. In the wizard that just opened, pick your disk size (e.g. 20 GB),
echo      enter a password, and click Install.
echo   2. Restart your laptop and select Q4OS from the boot menu.
echo   3. Double-click "Activate-FeatherOS.desktop" to turn on your Antivirus
echo      Fortress, RAM Booster, and AI Auto-Updates!
echo ============================================================================
pause
