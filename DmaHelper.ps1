<#
.SYNOPSIS
DMA Whitelist

.DESCRIPTION
v1.0.1
Creates a list of all PCI devices that may trip DMA security

Some of this script was sourced from here: https://superuser.com/a/1589473

.LINK
https://github.com/icedterminal/PS-Scripts

.NOTES
YOU NEED SYSTEM LEVEL ELEVATION TO MODIFY THIS PORTION OF THE REGISTRY!!

While this script is clearly safe, if you download a file Windows may block it.
You will need to unblock it if that's the case.
Additionally, PowerShell blocks running scripts for safety. Run the command:
	set-executionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine
	set-executionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
You can revert this change with the command:
	set-executionPolicy -ExecutionPolicy Default -Scope LocalMachine
	set-executionPolicy -ExecutionPolicy Default -Scope CurrentUser

You can read more about how to use this script here: https://go.icedterminal.me/dma

.EXAMPLE
With a SYSTEM elevated PowerShell window open, paste in the path to the script and press ENTER.
Example:

PS C:\> & "C:\Users\yourname\Downloads\DmaHelper.ps1"

#>

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

write-host "ALLOWED DMA CAPABLE DEVICES" -ForegroundColor Green
write-host "Note: If no devices are listed below, this is normal"
get-item -path HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity\AllowedBuses | Select-Object -ExpandProperty Property
write-host "`n======================================================================================="
write-host "ALL DMA CAPABLE DEVICES" -ForegroundColor Yellow
write-host "Note: It is normal for devices to appear as if they are duplicates"
Get-PnPDevice -InstanceId PCI* | Format-Table -Property FriendlyName,InstanceId -HideTableHeaders -AutoSize

$title = 'The devices found may not be listed in Allowed DMA'
$question = 'Do you want to allow them?'
$choice  = '&Yes', '&No'
$yesno = $Host.UI.PromptForChoice($title, $question, $choice, 1)
if ($yesno -eq 0) {
    reg export HKLM\SYSTEM\CurrentControlSet\Control\DmaSecurity\AllowedBuses "$env:homedrive\DefaultDMA.reg"
    $regprint = "$($env:homedrive)\AllowDMA.reg"
    'Windows Registry Editor Version 5.00
    
    [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\DmaSecurity\AllowedBuses]'`
    | Out-File $regprint
    (Get-PnPDevice -InstanceId PCI* `
    | Format-Table -Property FriendlyName,InstanceId -HideTableHeaders -AutoSize `
    | Out-String -Width 300).trim() `
    -split "`r`n" `
    -replace '&SUBSYS.*', '' `
    -replace '\s+PCI\\', '"="PCI\\' `
    | Foreach-Object{ "{0}{1}{2}" -f '"',$_,'"' } `
    | Out-File $regprint -Append
    reg import $regprint
    write-host "`nThe following devices have been added:" -ForegroundColor Green
    get-item -path HKLM:\SYSTEM\CurrentControlSet\Control\DmaSecurity\AllowedBuses | Select-Object -ExpandProperty Property
    write-host "`nPress any key to exit"
    [void][System.Console]::ReadKey($true)
    exit

} else {
    write-host "`nClosing"
    start-sleep 2
    exit
}