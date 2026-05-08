# =============================================================
#  CH.ps1
#  Autopilot Hardware Hash Collector
#
#  Requirement: Get-WindowsAutoPilotInfo.ps1 must be located
#  in the same folder as this script (on the USB stick).
#
#  Run during OOBE:
#  Shift+F10 -> powershell -ep Bypass -File D:\CH.bat
# =============================================================

Set-ExecutionPolicy Bypass -Scope Process -Force

# Determine path relative to the script location, not the drive letter
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$outputPath = Join-Path $scriptPath "Hashes"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Autopilot Hash Collection" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Create Hashes folder if it does not exist
if (-not (Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

# Check if the main script is present
$autopilotScript = Join-Path $scriptPath "Get-WindowsAutoPilotInfo.ps1"
if (-not (Test-Path $autopilotScript)) {
    Write-Host "ERROR: Get-WindowsAutoPilotInfo.ps1 not found!" -ForegroundColor Red
    Write-Host "Please place the script in the same folder as CH.ps1." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Read serial number
try {
    $serial = (Get-CimInstance Win32_BIOS).SerialNumber.Trim()
    Write-Host "Serial number detected: $serial" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: Could not read serial number!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$outFile = Join-Path $outputPath "$serial.csv"

# Check if a hash for this device already exists
if (Test-Path $outFile) {
    Write-Host "NOTICE: Hash for $serial already exists." -ForegroundColor Yellow
    $overwrite = Read-Host "Overwrite? (Y/N)"
    if ($overwrite -ne "Y" -and $overwrite -ne "y") {
        Write-Host "Cancelled. No new hash created." -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 0
    }
}

Write-Host ""
Write-Host "Collecting hardware hash... (may take 1-2 minutes)" -ForegroundColor Yellow
Write-Host ""

# Export hash locally from the stick (no internet required)
try {
    & "$autopilotScript" -OutputFile $outFile
} catch {
    Write-Host "ERROR while running the script: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check result - verify file exists AND contains actual hash data (more than just a header)
Write-Host ""
if (Test-Path $outFile) {
    $lineCount = (Get-Content $outFile | Measure-Object -Line).Lines
    if ($lineCount -gt 1) {
        Write-Host "Successfully saved: \Hashes\$serial.csv" -ForegroundColor Green
        Write-Host ""
        Write-Host "USB stick is ready for the next device!" -ForegroundColor Cyan

        # Show total number of devices collected so far
        $count = (Get-ChildItem -Path $outputPath -Filter "*.csv").Count
        Write-Host "Devices collected on this stick so far: $count" -ForegroundColor Cyan
    } else {
        Write-Host "ERROR: File was created but contains no hash data!" -ForegroundColor Red
        Write-Host "The script may not have run with sufficient permissions." -ForegroundColor Yellow
        Write-Host "Make sure to run CH.bat during OOBE (Shift + F10) on the target device," -ForegroundColor Yellow
        Write-Host "not on your own laptop." -ForegroundColor Yellow
        Remove-Item $outFile -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "ERROR: File was not created!" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to exit"
