@echo off
title FeatherOS - Windows Dual-Boot Installer
color 1F
echo ============================================================================
echo   FEATHER-OS: ULTRA-LIGHTWEIGHT WINDOWS-STYLE DUAL-BOOT INSTALLER
echo ============================================================================
echo.
echo   This will download and launch the graphical Dual-Boot Setup Wizard
echo   so you can install your new lightweight OS right alongside Windows.
echo.
echo   - Your existing Windows and files stay 100%% safe and untouched.
echo   - Recommended disk space to choose in the wizard: 15 GB to 25 GB
echo   - Recommended desktop profile: "Trinity" (uses only ~140 MB RAM!)
echo.
echo ============================================================================
echo.
set "INSTALLER_PATH=%USERPROFILE%\Downloads\q4os-winsetup.exe"
set "DOWNLOAD_URL=https://sourceforge.net/projects/q4os/files/stable/q4os-5.8-x64-winsetup.exe/download"

echo [1/2] Downloading the Dual-Boot Installer to your Downloads folder...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%INSTALLER_PATH%' -UseBasicParsing" 2>nul

if exist "%INSTALLER_PATH%" (
    echo [2/2] Launching the Dual-Boot Setup Wizard...
    start "" "%INSTALLER_PATH%"
) else (
    echo Opening direct download in your web browser...
    start "" "https://www.q4os.org/downloads1.html"
)

echo.
echo ============================================================================
echo   NEXT STEP (After your laptop restarts into your new OS):
echo   Double-click "2-Activate-Security-And-AutoPilot.sh" (or run setup.sh)
echo   to activate your Antivirus Fortress, RAM Booster, and AI Auto-Updates!
echo ============================================================================
pause
