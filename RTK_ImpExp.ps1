<#
.SYNOPSIS
Backup and restore your Realtek Audio settings.

.DESCRIPTION
v1.0.6
You get a "Full" and "EQ" reg file on backup. It is encouraged to only restore the "EQ" version.
All consequences are unknown if you import "Full".
You cannot double click the either reg file without loading the hive! It will not work.

.LINK
https://github.com/icedterminal/PS-Scripts

.NOTES
While this script is clearly safe, if you download a file Windows may block it.
You will need to unblock it if that's the case.
Additionally, PowerShell blocks running scripts for safety. Run the command:
	set-executionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine
	set-executionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
You can revert this change with the command:
	set-executionPolicy -ExecutionPolicy Default -Scope LocalMachine
	set-executionPolicy -ExecutionPolicy Default -Scope CurrentUser

You can read more about how to use this script here: https://go.icedterminal.me/rtk

.EXAMPLE
Right click this file and click "Run with PowerShell"

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

Function Menu {
    Clear-Host        
        Do {
            Clear-Host                                                                       
            Write-Host '====================================' -ForegroundColor Yellow
            Write-Host ' REALTEK UWP SETTINGS EXPORT/IMPORT' -ForegroundColor Yellow
            Write-Host '====================================' -ForegroundColor Yellow
            Write-Host '1. Export Settings'
            Write-Host '2. Import Settings'
            Write-Host 'Q. Quit'
            Write-Host $errout -ForegroundColor Red
            $Menu = Read-Host -Prompt 'Please enter an option'

                switch ($Menu) {
                    1 {
                        # This is simple, just load the hive and export the settings into their respective .reg files.
                        Write-Host "`nExport settings selected."
                        Write-Host "`nLoading hive..."
                        reg load HKU\RTK "$env:LocalAppData\Packages\RealtekSemiconductorCorp.RealtekAudioControl_dt26b99r8h8gj\Settings\settings.dat"
                        Write-Host "`nSaving to desktop..."
                        reg export HKU\RTK\LocalState\EQ "$env:userprofile\Desktop\RealtekEQBackup.reg"
                        reg export HKU\RTK\LocalState "$env:userprofile\Desktop\RealtekFullBackup.reg"
                        Write-Host "`nUnloading hive..."
                        reg unload HKU\RTK
                        Write-Host "`nDone!"
                        start-sleep 3
                    }
                    2 {
                        # This needs to be more involved. For user friendly-ness, we need a UI to select a file.
                        # Lock the file type to .reg only.
                        write-host "`nPLEASE OPEN AND CLOSE REALTEK AUDIO CONSOLE AT LEAST ONCE!" -ForegroundColor Red
                        write-host "THIS IS REQUIRED!" -ForegroundColor Red
                        write-host "`nIf you have done this, press ENTER to continue"
                        Read-Host
                        Write-Host "`nImport settings selected."
                        Add-Type -AssemblyName System.Windows.Forms
                        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
                        $OpenFileDialog.Title = "Select a REG file"
                        $OpenFileDialog.InitialDirectory = $initialDirectory
                        $OpenFileDialog.filter = "Registration Entries (*.reg)| *.reg"
                        $OpenFileDialog.ShowDialog() | Out-Null
                        $Global:SelectedFile = $OpenFileDialog.FileName
                        $ErrorActionPreference = 'Stop'
                        $path = $SelectedFile
                        if(![System.IO.File]::Exists($path)) {
                            # No file selected will loop back to the menu instead of falsely completing it.
                            write-host "`nNo file selected. Exiting." -ForegroundColor Red
                            start-sleep 2
                            Menu
                        }
                        else {
                            # If a file is selected, determine if it is a .reg file. These are just text based with the leading line "Windows Registry Editor Version 5.00"
                            if (Get-Content $SelectedFile | ForEach-Object{$_ -match "Windows Registry Editor Version 5.00"}) {
                                Write-Host "`nLoading hive..."
                                reg load HKU\RTK "$env:LocalAppData\Packages\RealtekSemiconductorCorp.RealtekAudioControl_dt26b99r8h8gj\Settings\settings.dat"
                                Write-Host "`nImporting reg...".
                                reg import $SelectedFile
                                Write-Host "`nUnloading hive..."
                                reg unload HKU\RTK
                                Write-Host "`nDone!"
                                start-sleep 3
                            }
                            else {
                                # If invalid, loop back to menu.
                                write-host "`nNot a valid registry file. Exiting." -ForegroundColor Red
                                start-sleep 2
                                Menu
                            }
                        }
                    }
                    Q {
                        Exit
                    }   
                    default {
                        # Any other key besides the ones listed, error out and reset menu.
                        $errout = 'Invalid option entered!'
                    }
                }
        }
    until ($Menu -eq 'q')
}   
Menu