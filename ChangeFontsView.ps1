<#
.SYNOPSIS
Change Fonts View

.DESCRIPTION
v1.0.3
Changes Windows Font folder to and from the default bundled and generic views.

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

You can read more about how to use this script here: https://go.icedterminal.me/fonts

.EXAMPLE
Right click this file and click "Run with PowerShell"

#>

# Check for admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process pwsh.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

Function Menu {
    Clear-Host        
        Do {
            Clear-Host                                                                       
            Write-Host '====================================' -ForegroundColor Yellow
            Write-Host 'CHANGE FONTS FOLDER VIEW' -ForegroundColor Yellow
            Write-Host '====================================' -ForegroundColor Yellow
            Write-Host '1. Generic folder view'
            Write-Host '2. Default folder view'
            Write-Host 'Q. Quit'
            Write-Host $errout -ForegroundColor Red
            $Menu = Read-Host -Prompt 'Please enter an option'

                switch ($Menu) {
                    1 {
                        # First make sure the <desktop.ini> file even exists. Just in case someone has removed it.
                        if (Test-Path -Path "C:\Windows\Fonts\desktop.ini" -PathType Leaf | Select-String -Pattern 'True' -CaseSensitive -SimpleMatch) {
                            # Explorer must be stopped to prevent issues.
                            taskkill /f /im explorer.exe
                            Set-Location "C:\Windows\Fonts"
                            # Remove hidden system attrib for permission reasons
                            attrib -s -h desktop.ini
                            # Backup original
                            Copy-Item "desktop.ini" "desktop.ini.bak"
                            # Remove original
                            Remove-Item "desktop.ini"
                            # Create a new one with custom view
                            New-Item -Name "desktop.ini" -ItemType "file"
                            Set-Content "desktop.ini" -Value "[ViewState]`nFolderType=Generic"
                            # Add hidden system attrib for permission reasons
                            attrib +s +h desktop.ini
                            attrib +s +h desktop.ini.bak
                            Start-Process "explorer.exe"
                            start-sleep 3
                        }
                        # In case someone has removed the original <desktop.ini>, let's create two.
                        # One with the generic view the user has asked for, and the default view for restoring to later.
                        else {
                            # Explorer must be stopped to prevent issues.
                            taskkill /f /im explorer.exe
                            Set-Location "C:\Windows\Fonts"
                            # Create a new one with custom view
                            New-Item -Name "desktop.ini" -ItemType "file"
                            Set-Content "desktop.ini" -Value "[ViewState]`nFolderType=Generic"
                            # Create a new backup one with default view
                            New-Item -Name "desktop.ini.bak" -ItemType "file"
                            Set-Content "desktop.ini.bak" -Value "[.ShellClassInfo]`nCLSID={BD84B380-8CA2-1069-AB1D-08000948F534}"
                            # Add hidden system attrib for permission reasons
                            attrib +s +h desktop.ini
                            attrib +s +h desktop.ini.bak
                            Start-Process "explorer.exe"
                            start-sleep 3
                        }
                    }
                    2 {
                        # First make sure the <desktop.ini.bak> file even exists. Just in case someone has removed it.
                        if (Test-Path -Path "C:\Windows\Fonts\desktop.ini.bak" -PathType Leaf | Select-String -Pattern 'True' -CaseSensitive -SimpleMatch) {
                            # Explorer must be stopped to prevent issues.
                            taskkill /f /im explorer.exe
                            Set-Location "C:\Windows\Fonts"
                            # Remove hidden system attrib for permission reasons
                            attrib -s -h desktop.ini
                            attrib -s -h desktop.ini.bak
                            # Delete existing
                            Remove-Item "desktop.ini"
                            # Replace with backup
                            Copy-Item "desktop.ini.bak" "desktop.ini"
                            # Delete backup
                            Remove-Item "desktop.ini.bak"
                            # Add hidden system attrib for permission reasons
                            attrib +s +h desktop.ini
                            Start-Process "explorer.exe"
                            start-sleep 3
                        }
                        # In case someone has removed or doesn't have the <desktop.ini.bak>, let's just create an original.
                        else {
                            # Explorer must be stopped to prevent issues.
                            taskkill /f /im explorer.exe
                            Set-Location "C:\Windows\Fonts"
                            # Create a new one with default view
                            New-Item -Name "desktop.ini" -ItemType "file"
                            Set-Content "desktop.ini" -Value "[.ShellClassInfo]`nCLSID={BD84B380-8CA2-1069-AB1D-08000948F534}"
                            Start-Process "explorer.exe"
                            # Add hidden system attrib for permission reasons
                            attrib +s +h desktop.ini
                            start-sleep 3
                        }
                    }
                    Q {
                        Exit
                    }   
                    default {
                        $errout = 'Invalid option entered!'
                    }
                }
        }
    until ($Menu -eq 'q')
}   
Menu