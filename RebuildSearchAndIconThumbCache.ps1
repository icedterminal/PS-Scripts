<#
.SYNOPSIS
Rebuild Search, Icon, Thumbnails

.DESCRIPTION
v2.0.0
A comprehensive approach to resetting data.
Search option resets this data for all of Windows, including Explorer/Start and UWP Settings.
Icon and Thumbnail resets this data for all of Windows, including Explorer/Start and UWP Settings.

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

You can read more about how to use this script here: https://go.icedterminal.me/srch

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
clear-host

Function Menu { clear-host
    Do {
        Clear-Host                                                                       
        Write-Host '====================================' -ForegroundColor Yellow
        Write-Host '  Rebuild Search, Icon, Thumbnails' -ForegroundColor Yellow
        Write-Host '====================================' -ForegroundColor Yellow
        Write-Host '1. Rebuild Search'
        Write-Host '2. Rebuild Icon and Thumbnail cache'
        Write-Host 'Q. Quit'
        Write-Host $errout -ForegroundColor Red
        $Menu = Read-Host -Prompt 'Please enter an option'
        switch ($Menu) {
            1 { # Check for safe mode. If true, continue.
                if (Get-CimInstance win32_computersystem | Select-Object -Property bootupstate | Select-String -Pattern 'fail-safe' -SimpleMatch ) {
                    write-host "`nYou are in Safe Mode." -foregroundcolor Green
                    write-host "After this process completes, your computer will restart normally."
                    write-host "`nOnce restarted, please wait a few minutes for the search indexer to complete before you change settings."
                    write-host "Press any key to continue..."
                    [void][System.Console]::ReadKey($true)
                    taskkill /f /im explorer.exe >$null 2>&1
                    taskkill /f /im RuntimeBroker.exe >$null 2>&1
                    taskkill /f /im dllhost.exe >$null 2>&1
                    remove-item "C:\ProgramData\Microsoft\Search\*" -recurse -force >$null 2>&1
                    taskkill /f /im SearchApp.exe >$null 2>&1
                    remove-item "$env:localappdata\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\AC\TokenBroker\Cache\*" -recurse -force >$null 2>&1
                    remove-item "$env:localappdata\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\AC\Microsoft\*" -recurse -force >$null 2>&1
                    remove-item "$env:localappdata\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\AppData\*" -recurse -force >$null 2>&1
                    remove-item "$env:localappdata\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\LocalState\*" -recurse -force >$null 2>&1
                    remove-item "$env:localappdata\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\TempState\*" -recurse -force >$null 2>&1
                    remove-item "$env:localappdata\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\Settings\*" -recurse -force >$null 2>&1
                    taskkill /f /im StartMenuExperienceHost.exe >$null 2>&1
                    remove-item "$env:localappdata\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\TempState\*" -recurse -force >$null 2>&1
                    remove-item "$env:localappdata\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\Settings\*" -recurse -force >$null 2>&1
                    remove-item "$env:localappdata\Packages\windows.immersivecontrolpanel_cw5n1h2txyewy\Settings\*" -recurse -force >$null 2>&1
                    bcdedit /deletevalue safeboot >$null
                    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "Index Settings" -Value "rundll32.exe shell32.dll,Control_RunDLL srchadmin.dll" -PropertyType "STRING"  >$null 2>&1
                    shutdown /r /t 0
                }
                else { # If not safe mode, offer to do this. Then reboot with the a one-time reg entry to run this script on login.
                    write-host "`nYou are not in Safe Mode!" -ForegroundColor Red
                    $title = 'You must run this script again in Safe Mode.'
                    $question = 'Do you want to do this now?'
                    $choice  = '&Yes', '&No'
                    $yesno = $Host.UI.PromptForChoice($title, $question, $choice, 0)
                    if ($yesno -eq 0) {
                        bcdedit /set safeboot minimal >$null
                        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "*RebuildScript" -Value "pwsh.exe -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -PropertyType "STRING"  >$null 2>&1
                        $i = 10
                        do {
                            clear-host
                            write-host "Restarting in" $i
                            start-sleep 1
                            $i--
                        } while ($i -gt 0)
                        shutdown /r /t 0
                    }
                    else {
                        Menu
                    }
                }
            }
            2 { # Clear icon and thumbnail data.
                write-host "`nPlease save your work!" -foregroundcolor Red
                write-host "After this process completes you will be logged out."
                write-host "Press any key to continue..."
                [void][System.Console]::ReadKey($true)
                taskkill /f /im explorer.exe >$null 2>&1
                taskkill /f /im RuntimeBroker.exe >$null 2>&1
                taskkill /f /im dllhost.exe >$null 2>&1
                taskkill /f /im taskmgr.exe >$null 2>&1
                remove-item "$env:localappdata\Microsoft\Windows\Explorer\*" -recurse -force >$null 2>&1
                taskkill /f /im SearchApp.exe >$null 2>&1
                remove-item "$env:localappdata\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\LocalState\AppIconCache\*" -recurse -force >$null 2>&1
                remove-item "$env:localappdata\Packages\Microsoft.Windows.Search_cw5n1h2txyewy\TempState\*" -recurse -force >$null 2>&1
                taskkill /f /im StartMenuExperienceHost.exe >$null 2>&1
                remove-item "$env:localappdata\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\TempState\*" -recurse -force >$null 2>&1
                (Get-Process -PID $pid).SessionID | ForEach-Object {logoff ($_.SessionID)}
            }
            Q { # Clearly this just closes the script. ha.
                exit
            }
            default {
                $errout = 'Invalid option entered!'
            }
        }
    } until ($Menu -eq 'q')
} Menu