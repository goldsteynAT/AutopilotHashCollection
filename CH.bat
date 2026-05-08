@echo off
:: =============================================================
::  CH.bat
::  Launcher for CH.ps1 - Autopilot Hash Collector
::
::  Run this file during OOBE:
::  Shift + F10 -> type D:\CH.bat and press Enter
::  (use Tab to autocomplete the filename)
::
::  NOTE: Must be run during OOBE on the target device, or as
::  Administrator on your own laptop (right-click > Run as Administrator).
::  Administrator/SYSTEM rights are required to read the hardware
::  hash via WMI/CIM.
:: =============================================================

:: Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo  WARNING: This script requires administrator rights.
    echo  Please run CH.bat during OOBE on the target device
    echo  ^(Shift + F10 -^> type D:\CH.bat^)
    echo  If you want to run it on your own laptop,
    echo  right-click CH.bat and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0CH.ps1"
