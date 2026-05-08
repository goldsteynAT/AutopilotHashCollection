@echo off
:: =============================================================
::  Start_Upload.bat
::  Launcher for UH.ps1 - Autopilot Hash Merger & Upload
::
::  Double-click to run. No administrator rights required.
::  Merges all collected hashes and opens the Intune Autopilot
::  import page in Microsoft Edge (InPrivate).
:: =============================================================

start "Autopilot Upload" /wait powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0UH.ps1"
