<#
.SYNOPSIS
WoW Simple Sync

.DESCRIPTION
v1.0.3
Sync just your World of Warcraft Toon Folder (WTF) with git accounts.

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

You can read more about how to use this script here: https://go.icedterminal.me/wtf

.EXAMPLE
Right click this file and click "Run with PowerShell"

#>

# Check for admin.
# If your WoW install is in a location where your user account does not freely have access to read/write, you need to uncomment the line below.
#if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# First move to the root of WoW. You may need to alter this path if you installed WoW somewhere else.
Set-Location "C:\Program Files (x86)\World of Warcraft"

# Then look through for different install versions.
# You're going to have a branch for each version you have installed.
Get-ChildItem -Path "_*_" -Recurse -Filter "WTF" | ForEach-Object {
	# Once they are found, check the git status for untracked changes and files.
	if (Set-Location $_ && git status | Select-String -Pattern "Changes not staged|Untracked files" ) {
		# Before pushing, a branch has to be specified. There is already a variable that collects this information: the path.
		# The path must be converted to a string.
		$path = Convert-Path $_
		# Trim the path string down to the version using regex and use that as the branch to push to.
		# If you want to see the regex in action: https://regexr.com/7dlfr
		$branch = $path -replace '^[^_]*_|_\\(?:.(?!\\))+$',''
		write-host "`nChanges for `"$branch`" found" -ForegroundColor Yellow
		# Give the commit message the date and time. Easy to sort through.
		$timestamp = Get-Date -Format G
		# Add untracked files, if any. If you installed new addons this is a must.
		git add .
		# Add changes.
		git commit -am "Auto sync at $timestamp"
		# Add changes and sign. Do not use this one unless you have setup GPG.
		#git commit -S -am "Auto sync at $timestamp"
		# Push the commit.
		git push -u origin $branch
		# Pause for a few seconds to review.
		start-sleep 3
	}
	else {
		# Again converting path to string and trimming.
		# This time we just report no changes and close.
		$path = Convert-Path $_
		$branch = $path -replace '^[^_]*_|_\\(?:.(?!\\))+$',''
		write-host "`nNo changes for `"$branch`"" -ForegroundColor Green
		# Pause for a few seconds to review.
		start-sleep 3
	}
}