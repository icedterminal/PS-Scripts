<#
.SYNOPSIS
Create Bootable Windows USB

.DESCRIPTION
v1.0.3
This script exists because the Windows Media Creation tool is not ideal in some scenarios.
It uses an outdated copy of Windows from the milestone release.
After install, you go through several updates.
Sites like UUPDump allow you to create an up-to-date ISO.
FAT file systems do not support files larger than 4GB. All standard EFI firmwares are guaranteed to read FAT.
Many cannot read NTFS, ext3/4, etc.
There are exceptions to this, such as Apple's own UEFI firmware and those that include ISO-9660 (CD).
Additional drivers are required to read a file system such as NTFS. This may be skipped.
The downside is when the ISO is written to a USB with third party tools it may fail secure boot.
These tools modify the boot process by adding their own bootloaders.
To get around this, split the <install.wim> file on a USB device formatted as FAT32.
This method will pass secure boot because you are not altering the boot process.

.LINK
https://github.com/icedterminal/PS-Scripts

.NOTES
While this script is clearly safe, if you download a file Windows may block it.
You will need to unblock it if that's the case.
Additionally, PowerShell blocks running scripts for safety. Run the command:
	set-executionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
	set-executionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
You can revert this change with the command:
	set-executionPolicy -ExecutionPolicy Default -Scope LocalMachine
	set-executionPolicy -ExecutionPolicy Default -Scope CurrentUser

You can read more about how to use this script here: https://go.icedterminal.me/usb

.EXAMPLE
Right click this file and click "Run with PowerShell 7"
#>

# Check for admin.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process pwsh.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
$Error.Clear()

# Custom colors
$Host.UI.RawUI.BackgroundColor = ($bckgrnd = 'Black')
$Host.UI.RawUI.ForegroundColor = 'White'
$Host.PrivateData.ErrorForegroundColor = 'Red'
$Host.PrivateData.ErrorBackgroundColor = $bckgrnd
$Host.PrivateData.WarningForegroundColor = 'Magenta'
$Host.PrivateData.WarningBackgroundColor = $bckgrnd
$Host.PrivateData.DebugForegroundColor = 'Yellow'
$Host.PrivateData.DebugBackgroundColor = $bckgrnd
$Host.PrivateData.VerboseForegroundColor = 'Green'
$Host.PrivateData.VerboseBackgroundColor = $bckgrnd
$Host.PrivateData.ProgressForegroundColor = 'Cyan'
$Host.PrivateData.ProgressBackgroundColor = $bckgrnd
Clear-Host

# Welcome message.
Write-Host '=============================' -ForegroundColor Blue
Write-Host 'Windows Bootable Media Script' -ForegroundColor Blue
Write-Host '=============================' -ForegroundColor Blue
start-sleep 1
Write-Host "`n+++++ WARNING! +++++" -ForegroundColor Red
Write-Host "Your USB device needs to be completely erased to make it bootable."
write-host "Ensure you have secured any existing data before you continue!"
write-host "Press any key to continue..."
[void][System.Console]::ReadKey($true)

# List all the USB devices on the computer.
# Prompt for the disk number and store it as variable <$DiskNum>.
# USB variable <$DiskNum> to get total size and store it as variable <$DiskSize>.
write-host "`n1. Select your USB device number." -ForegroundColor Yellow
write-host "================================================="
write-host "Note: Only USB devices are shown."
get-disk | Where-Object -FilterScript {$_.Bustype -Eq "USB"} | Sort-Object Number | Format-Table -Property Number, @{n="Disk Name";e={$_.FriendlyName}}, @{n="Total Size in GiB";e={[math]::truncate($_.Size / 1GB)}}
$DiskNum = Read-Host -Prompt 'Enter number'
$DiskSize = (get-disk $DiskNum).Size

# Add an Open File window so the user can select an ISO.
# Then store the location as variable <$SelectedFile>.
write-host "`n2. Select your Windows ISO." -ForegroundColor Yellow
write-host "================================================="
Add-Type -AssemblyName System.Windows.Forms
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Title = "Select a Windows ISO"
$OpenFileDialog.InitialDirectory = $initialDirectory
$OpenFileDialog.filter = "Disc Image File (*.iso)| *.iso"
$OpenFileDialog.ShowDialog() | Out-Null
$Global:SelectedFile = $OpenFileDialog.FileName
write-host "$SelectedFile" -ForegroundColor Green

# Try to format the USB device. If it fails, display the error in a friendly way.
try {
    # Grab the existing drive letter for the USB device and store it as variable <$USBLetter>.
    # Erase the USB device.
    # Create a new partition on the USB device using the stored drive letter.
    # Format the new partition as FAT32 using the stored drive letter.
    $USBLetter = (get-partition -DiskNumber $DiskNum).DriveLetter
    Write-Host "`n3. Formatting USB device on $DiskNum, mount letter $USBLetter" -ForegroundColor Yellow
    write-host "================================================="
    if ($DiskSize -ge 31180455936 | Select-String -Pattern 'True' -CaseSensitive -SimpleMatch) {
        Clear-Disk -Number $DiskNum -RemoveData -RemoveOEM -Confirm:$false -ErrorAction Stop
        write-host "`nAllocating 16GB due to limitations"
        New-Partition -DiskNumber $DiskNum -DriveLetter $USBLetter -Size 16GB -ErrorAction Stop
    }
    else {
        Clear-Disk -Number $DiskNum -RemoveData -RemoveOEM -Confirm:$false -ErrorAction Stop
        New-Partition -DiskNumber $DiskNum -DriveLetter $USBLetter -Size -UseMaximumSize -ErrorAction Stop
    }
    Format-Volume -DriveLetter $USBLetter -FileSystem FAT32 -NewFileSystemLabel WinUSB -Confirm:$false -ErrorAction Stop | out-null
    write-host "Format complete!" -ForegroundColor Green
    
    # Try to mount the ISO. If it fails, display the error in a friendly way.
    try {
        # Mount the ISO and store it's results as variable <$Result>.
        # Use the <$Result> to get the drive letter of the ISO and store that as variable <$ISOLetter>.
        # Recursively copy the ISO contents excluding <install.wim>.
        write-host "`n4. Mounting ISO." -ForegroundColor Yellow
        write-host "================================================="
        $Result = Mount-DiskImage -ImagePath "$SelectedFile" -ErrorAction Stop
        $ISOLetter = ($Result | Get-Volume).DriveLetter
        write-host "Windows ISO mounted at $ISOLetter" -ForegroundColor Green
        if (Test-Path -Path "${ISOLetter}:\sources\install.esd" -PathType Leaf | Select-String -Pattern 'True' -CaseSensitive -SimpleMatch) {
            # We cannot use ESD archives. To convert them requires selecting an index. Which we do not want to do.
            write-host "`nCannot use this ISO because the install file is ESD format. Need WIM." -ForegroundColor Red
            start-sleep 10
            exit
        }
        else {
            Write-Host "`n5. Creating bootable media." -ForegroundColor Yellow
            write-host "================================================="
            Write-Host "Please be patient. This takes time."
            Write-Host "`nCopying files..."
            copy-item -path "${ISOLetter}:\*" -destination "${USBLetter}:\" -recurse -exclude install.wim
            Write-Host "`nSplitting install.wim..."
            # Try to split the <install.wim> file with DISM. If it fails, display the error in a friendly way.
            if (dism /split-image /imagefile:${ISOLetter}:\sources\install.wim /swmfile:${USBLetter}:\sources\install.swm /filesize:3000 | select-string -pattern 'The operation completed successfully') {
                write-host "`nYour bootable media ready to use!" -ForegroundColor Green
                start-sleep 5
                [void][System.Console]::ReadKey($true)
            }
            # Let user know if DISM has had an error.
            else {
                write-host "`nDISM has failed." -ForegroundColor Red
                write-host "Your <install.wim> file is incomplete, damaged, or missing." -ForegroundColor Red
                [void][System.Console]::ReadKey($true)
            }
        }
    }
    # Catch the mount ISO error.
    catch [System.Exception] {
        Write-Host "`nUnable to mount selected ISO." -ForegroundColor Red
        [void][System.Console]::ReadKey($true)
    }
}
# Catch the USB format error.
catch [System.Exception] {
    Write-Host "`nThis USB device cannot be used!" -ForegroundColor Red
    Write-Host "Is it read-only? Some USB devices are write protected." -ForegroundColor Red
    [void][System.Console]::ReadKey($true)
}