<#
.SYNOPSIS
Remove UWP Apps

.DESCRIPTION
v1.0.2
Removes and deprovisions pre-installed UWP apps.

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

You can read more about how to use this script here: https://go.icedterminal.me/uwp

.EXAMPLE
Right click this file and click "Run with PowerShell 7"

#>

# Check for admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process pwsh.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

Write-Host "Please wait while a system restore point is created."
Checkpoint-Computer -Description "Remove Apps Script"
Write-Host "Press any key to continue"
Read-Host
$BloatApps = "3d|alarms|feedback|getstarted|windowscommunicationsapps|maps|messaging|mixedreality|officehub|onenote|onedrivesync|mspaint|people|skype|todo|wallet|weather|WebExperience|Clipchamp|yourphone|zune|teams|news"
$RemoveApps = Get-AppxPackage -allusers | where-object {$_.name -match $BloatApps}
$RemovePrApps = Get-AppxProvisionedPackage -online | where-object {$_.displayname -match $BloatApps}
ForEach ($RemovedApp in $RemoveApps) {
    Write-Host Removing $RemovedApp.name
    Remove-AppxPackage -package $RemovedApp -erroraction silentlycontinue
}
ForEach ($RemovedPrApp in $RemovePrApps) {
    Write-Host Removing provisioned $RemovedPrApp.displayname
    Remove-AppxProvisionedPackage -online -packagename $RemovedPrApp.packagename -erroraction silentlycontinue
}
Write-Host "Removal complete"
Start-Sleep 3
exit