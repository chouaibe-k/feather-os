@echo off
title FeatherOS - 1-Click Windows Dual-Boot Installer
color 1F
cd /d "%~dp0"

echo ============================================================================
echo   FEATHER-OS: ULTRA-LIGHTWEIGHT WINDOWS-STYLE DUAL-BOOT INSTALLER
echo ============================================================================
echo.
echo   - Your existing Windows and personal files stay 100%% safe and untouched.
echo   - Recommended disk size in the wizard: 15 GB to 25 GB
echo   - Recommended desktop profile: "Trinity" (uses only ~140 MB RAM!)
echo.
echo ============================================================================
echo.

REM 1. First check right inside this current folder (%~dp0) for q4os-winsetup.exe
if exist "%~dp0q4os-winsetup.exe" (
    echo [FOUND] Launching q4os-winsetup.exe directly from this folder...
    echo (If Windows asks "Do you want to allow this app to make changes", click YES)
    start "" "%~dp0q4os-winsetup.exe"
    goto :done
)

for %%F in ("%~dp0*winsetup*.exe") do (
    echo [FOUND] Launching %%~nxF directly from this folder...
    echo (If Windows asks "Do you want to allow this app to make changes", click YES)
    start "" "%%~fF"
    goto :done
)

REM 2. If q4os-winsetup.zip is in this folder, unzip and run it
if exist "%~dp0*winsetup*.zip" (
    echo [FOUND ZIP] Extracting q4os-winsetup.exe into this folder...
    for %%Z in ("%~dp0*winsetup*.zip") do (
        powershell -NoProfile -ExecutionPolicy Bypass -Command ^
          "Expand-Archive -Path '%%~fZ' -DestinationPath '%~dp0' -Force"
    )
    if exist "%~dp0q4os-winsetup.exe" (
        start "" "%~dp0q4os-winsetup.exe"
        goto :done
    )
)

REM 3. Fallback: Download into this folder if not present
echo q4os-winsetup.exe was not found in this folder. Downloading it now...
set "ZIP_PATH=%~dp0q4os-winsetup.zip"
set "DOWNLOAD_URL=https://sourceforge.net/projects/q4os/files/stable/q4os-winsetup-6.10-r1.zip/download"

curl.exe -L -A "Wget/1.21" "%DOWNLOAD_URL%" -o "%ZIP_PATH%"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%~dp0' -Force" 2>nul

if exist "%~dp0q4os-winsetup.exe" (
    start "" "%~dp0q4os-winsetup.exe"
) else (
    start "" "https://www.q4os.org/downloads1.html"
)

:done
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
