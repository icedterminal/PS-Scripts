<#
.SYNOPSIS
Custom Context Menu Creator

.DESCRIPTION
v1.0.1
Create quickly accessible commands for various files on right-click.

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

You can read more about how to use this script here: https://go.icedterminal.me/ctxt

.EXAMPLE
Right click this file and click "Run with PowerShell 7"

#>

# Check for admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process pwsh.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

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

Write-Host '====================================' -ForegroundColor Yellow
Write-Host '    CUSTOM CONTEXT MENU CREATOR' -ForegroundColor Yellow
Write-Host '====================================' -ForegroundColor Yellow
Write-Host 'Enter a file extension'
$ext = Read-Host -Prompt 'Please include the period'
if (test-path "HKLM:\SOFTWARE\Classes\SystemFileAssociations\$ext") {
    write-host "> Extension exists"
    if (test-path "HKLM:\SOFTWARE\Classes\SystemFileAssociations\$ext\shell") {
        Write-Host ">> Extension shell exists"
    }
    else {
        Write-Host ">> Extension shell does not exist"
        New-Item -Path "HKLM:\SOFTWARE\Classes\SystemFileAssociations\$ext" -Name "shell" | out-null
        write-host ">>> Extension shell added"
    }
}
else {
    write-host "> Extension does not exists"
    New-Item -Path "HKLM:\SOFTWARE\Classes\SystemFileAssociations" -Name "$ext" | out-null
    New-Item -Path "HKLM:\SOFTWARE\Classes\SystemFileAssociations\$ext" -Name "shell" | out-null
    write-host ">> Extension added"
}
write-host "`n"
$name = Read-Host -Prompt 'Enter context menu name'
New-Item -Path "HKLM:\SOFTWARE\Classes\SystemFileAssociations\$ext\shell" -Name "$name" | out-null
write-host "> Context menu name added"
write-host "`n"
write-host "Enter the command line action below that will be executed by PowerShell."
write-host "Please ensure you have used the variable %1 in place of actual file names."
$cmd = Read-Host -Prompt 'powershell -command'
New-Item -Path "HKLM:\SOFTWARE\Classes\SystemFileAssociations\$ext\shell\$name" -Name "command" | out-null
New-ItemProperty -Path "HKLM:\SOFTWARE\Classes\SystemFileAssociations\$ext\shell\$name\command" -Name "(Default)" -Value "powershell -command $cmd" -PropertyType "STRING" | out-null
write-host "> Command added"
write-host ">> Create removal reg"
New-Item -path ~/Desktop -name "Remove $name context.reg" | out-null
Set-Content "~/Desktop/Remove $name context.reg" "Windows Registry Editor Version 5.00`n[-HKEY_LOCAL_MACHINE\SOFTWARE\Classes\SystemFileAssociations\$ext\shell\$name]"
Start-Sleep 3