# Autopilot Hash Collection
Semi-Automatic Hash Retrieval for Windows Autopilot Devices using a USB Stick.
<img src="./usb_hash_collection.svg" alt="USB Hash Collection Workflow"/>

## What this is
A small USB stick toolkit for manually enrolling Windows devices into Microsoft Intune Autopilot when they were not pre-registered by a vendor. 
You collect hardware hashes from each device during OOBE, then upload them all at once from your admin laptop.

No internet connection is required on the target devices. No PowerShell modules need to be installed on them either.

## Files
| File | Description |
|---|---|
| `CH.bat` | Run this on each target device during OOBE |
| `CH.ps1` | Hash collection logic called by CH.bat |
| `UH.ps1` | Merges hashes and opens the Intune import page |
| `Start_Upload.bat` | Launcher for UH.ps1 on your admin laptop |
| `Get-WindowsAutoPilotInfo.ps1` | Microsoft script — download once before use |
| `GroupTags.csv` | Optional — maps short codes to Autopilot group tags |

## Setup
Download the Microsoft script once and place it on the stick:

```powershell
Save-Script -Name Get-WindowsAutoPilotInfo -Path D:\
```

## Usage
**On each target device** — plug in the USB stick, press `Shift + F10` at the OOBE screen and run:

```
D:\CH.bat
```

Type `D:\C` and press `Tab` to autocomplete. The hash is saved to `Hashes\` on the stick. Repeat for each device, then move on.

**On your admin laptop** — plug in the stick and double-click `Start_Upload.bat`. The script will ask whether to add a group tag, then merge all collected hashes into a single CSV and open the Intune Autopilot import page in Edge (InPrivate). The folder path is copied to your clipboard automatically.

Processed hashes are moved to `Hashes_Old\` after the merge.

## Group tags
If `GroupTags.csv` is present on the stick, UH.ps1 will offer to assign a group tag to all devices. 
Enter a short code in the format `[CountryCode][DeviceType]`, for example `AT1LAP` or `DE1WKS`. The lookup table can be extended freely.

## Requirements

- Windows device with PowerShell 5.1 or later
- Microsoft Edge installed on the admin laptop
- Intune admin account with `DeviceManagementServiceConfig.ReadWrite.All`
