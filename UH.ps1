# =============================================================
#  UH.ps1
#  Autopilot Hash Merger & Upload Launcher
#
#  Run this script from your own laptop after all hashes
#  have been collected using CH.ps1.
#
#  1. Optionally assigns a Group Tag via GroupTags.csv lookup
#  2. Merges all individual device CSVs into one import file
#  3. Moves processed CSVs from Hashes\ to Hashes_Old\
#  4. Copies the Autopilot-Import folder path to your clipboard
#  5. Opens the Intune Autopilot import page in Microsoft Edge
#     (InPrivate mode) so you can upload the file manually
#
#  No admin rights required.
#  No PowerShell module installation required.
# =============================================================

Set-ExecutionPolicy Bypass -Scope Process -Force

$scriptPath    = Split-Path -Parent $MyInvocation.MyCommand.Definition
$hashFolder    = Join-Path $scriptPath "Hashes"
$archiveFolder = Join-Path $scriptPath "Hashes_Old"
$importFolder  = Join-Path $scriptPath "Autopilot-Import"
$groupTagsFile = Join-Path $scriptPath "GroupTags.csv"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Autopilot Hash Merger" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if the Hashes folder exists
if (-not (Test-Path $hashFolder)) {
    Write-Host "ERROR: No 'Hashes' folder found!" -ForegroundColor Red
    Write-Host "Please run CH.ps1 on the target devices first." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Read CSV files from the Hashes folder
$files = Get-ChildItem -Path $hashFolder -Filter "*.csv"

if ($files.Count -eq 0) {
    Write-Host "ERROR: No CSV files found in the Hashes folder!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Build list of serial numbers from filenames
$serials = $files | ForEach-Object { $_.BaseName }

Write-Host "Devices found: $($files.Count)" -ForegroundColor Cyan
Write-Host ""
$serials | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
Write-Host ""

# -- GROUP TAG ---------------------------------------------------
$groupTag = ""

if (Test-Path $groupTagsFile) {
    do {
        Write-Host "Do you want to add a group tag to all devices? (Y/N)" -ForegroundColor Yellow
        $tagAnswer = Read-Host "  (Y/N)"
        if ($tagAnswer -ne "Y" -and $tagAnswer -ne "y" -and $tagAnswer -ne "N" -and $tagAnswer -ne "n") {
            Write-Host "  Invalid input. Please enter Y or N." -ForegroundColor Red
            Write-Host ""
        }
    } while ($tagAnswer -ne "Y" -and $tagAnswer -ne "y" -and $tagAnswer -ne "N" -and $tagAnswer -ne "n")

    if ($tagAnswer -eq "Y" -or $tagAnswer -eq "y") {
        $groupTagsData = Import-Csv -Path $groupTagsFile

        Write-Host ""
        Write-Host "  Format: [CountryCode][DeviceType]" -ForegroundColor Cyan
        Write-Host "    Country codes : AT1, CH1, DE1, US1, ..." -ForegroundColor Gray
        Write-Host "    Device types  : LAP (Laptop)  WKS (Workstation)" -ForegroundColor Gray
        Write-Host "    Example       : AT1LAP  or  DE1WKS" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Available short codes:" -ForegroundColor Gray
        $groupTagsData | ForEach-Object { Write-Host "    $($_.ShortCode)  ->  $($_.GroupTag)" -ForegroundColor Gray }
        Write-Host ""

        do {
            $shortCode = Read-Host "  Enter short code (e.g. AT1LAP)"
            $match = $groupTagsData | Where-Object { $_.ShortCode -eq $shortCode }
            if (-not $match) {
                Write-Host "  ERROR: '$shortCode' not found in GroupTags.csv." -ForegroundColor Red
                Write-Host "  Please use the format [CountryCode][DeviceType], e.g. AT1LAP or DE1WKS." -ForegroundColor Yellow
                Write-Host ""
            }
        } while (-not $match)

        $groupTag = $match.GroupTag
        Write-Host "  Group tag set to: $groupTag" -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "Group tag skipped." -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host "NOTE: GroupTags.csv not found - group tag skipped." -ForegroundColor Gray
    Write-Host ""
}
# -- END GROUP TAG -----------------------------------------------

# Create Autopilot-Import and Hashes_Old folders if they do not exist
foreach ($folder in @($importFolder, $archiveFolder)) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
    }
}

# Merge all CSVs into one combined file saved in Autopilot-Import\
# If a Group Tag was set, add it to the Group Tag column of each row
$mergedFile = Join-Path $importFolder "Autopilot_Import_$(Get-Date -UFormat '%Y%m%d_%H%M').csv"
$first = $true
foreach ($file in $files) {
    $rows = Import-Csv -Path $file.FullName
    if ($groupTag -ne "") {
        $rows | ForEach-Object { $_ | Add-Member -NotePropertyName "Group Tag" -NotePropertyValue $groupTag -Force }
    }
    if ($first) {
        $rows | Export-Csv -Path $mergedFile -NoTypeInformation -Encoding utf8
        $first = $false
    } else {
        $rows | Export-Csv -Path $mergedFile -NoTypeInformation -Encoding utf8 -Append
    }
}

Write-Host "Merged CSV saved:" -ForegroundColor Green
Write-Host "  $mergedFile" -ForegroundColor White
Write-Host ""

# Move processed CSVs from Hashes\ to Hashes_Old\
Write-Host "Archiving processed hashes to Hashes_Old\..." -ForegroundColor Yellow
$moveErrors = 0
foreach ($file in $files) {
    $destination = Join-Path $archiveFolder $file.Name
    # If a file with the same name already exists in Hashes_Old, add a timestamp
    if (Test-Path $destination) {
        $timestamp   = Get-Date -UFormat '%Y%m%d_%H%M%S'
        $destination = Join-Path $archiveFolder "$($file.BaseName)_$timestamp.csv"
    }
    try {
        Move-Item -Path $file.FullName -Destination $destination -ErrorAction Stop
        Write-Host "  Archived: $($file.Name)" -ForegroundColor Gray
    } catch {
        Write-Host "  WARNING: Could not move $($file.Name): $_" -ForegroundColor Yellow
        $moveErrors++
    }
}

if ($moveErrors -eq 0) {
    Write-Host "  All files archived successfully." -ForegroundColor Green
} else {
    Write-Host "  $moveErrors file(s) could not be moved." -ForegroundColor Yellow
}
Write-Host ""

# Copy the FOLDER path to clipboard so it can be pasted into
# the Intune file picker address bar (Ctrl+V, then Enter)
Set-Clipboard -Value $importFolder
Write-Host "Folder path copied to clipboard!" -ForegroundColor Green
Write-Host "  $importFolder" -ForegroundColor Gray
Write-Host ""

# Open the Autopilot-Import folder in Windows Explorer
Write-Host "Opening import folder in Explorer..." -ForegroundColor Yellow
Start-Process explorer.exe -ArgumentList $importFolder

Start-Sleep -Seconds 1

# Open Intune Autopilot import page in Microsoft Edge (InPrivate)
$intuneUrl = "https://intune.microsoft.com/#view/Microsoft_Intune_Enrollment/AutopilotDevices.ReactView"
$edgePath  = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

if (Test-Path $edgePath) {
    Write-Host "Opening Intune Autopilot page in Edge (InPrivate)..." -ForegroundColor Yellow
    Start-Process $edgePath -ArgumentList "--inprivate", $intuneUrl
} else {
    Write-Host "Microsoft Edge not found at default path." -ForegroundColor Yellow
    Write-Host "Opening in default browser instead..." -ForegroundColor Yellow
    Start-Process $intuneUrl
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Next steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Sign in to Intune with your admin account" -ForegroundColor White
Write-Host "  2. Click 'Import' in the Autopilot devices page" -ForegroundColor White
Write-Host "  3. Click 'Select a file'" -ForegroundColor White
Write-Host "  4. In the file picker address bar: press Ctrl+V," -ForegroundColor White
Write-Host "     then press Enter - the import folder opens" -ForegroundColor White
Write-Host "  5. Select the CSV file and click Open" -ForegroundColor White
Write-Host "  6. Click 'Import' to start the upload" -ForegroundColor White
Write-Host "  7. Wait ~15-20 minutes for devices to appear in Intune" -ForegroundColor White
Write-Host ""
Write-Host "  Folder path in your clipboard:" -ForegroundColor Gray
Write-Host "  $importFolder" -ForegroundColor Gray
Write-Host ""

Read-Host "Press Enter to close this window"
