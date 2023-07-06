<#
.SYNOPSIS
WoW Sync

.DESCRIPTION
v1.0.6
Sync your World of Warcraft Interface AddOns, WTF, and Fonts with git accounts.

.LINK
https://github.com/icedterminal/PS-Scripts

.NOTES
While this script is clearly safe, if you download a file Windows may block it.
You will need to unblock it if that's the case.
Additionally, PowerShell blocks running scripts for safety. Run the command:
	set-executionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
	set-executionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

You can read more about how to use this script here: https://go.icedterminal.me/wtf

.EXAMPLE
Execute this script with a scheduled task on the process termination of wow.exe

#>

# First move to the root of WoW. You may need to alter this path if you installed WoW somewhere else.
Set-Location "C:\Program Files (x86)\World of Warcraft"
# Stop the launcher so it doesn't freak out when permissions are being dealt with later on.
stop-process -name "Battle.net" | out-null
# Then look through for different install versions.
Get-ChildItem -Path "_*_" | ForEach-Object {
	# Once they are found, check the git status for untracked changes and files.
	if (Set-Location $_ && git status | Select-String -Pattern "Changes not staged|Untracked files" ) {
		# Before pushing, a branch has to be specified. There is already a variable that collects this information: the path.
		# The path must be converted to a string.
		$path = Convert-Path $_
		# Trim the path string down to the version using regex and use that as the branch to push to.
		$branch = $path -replace '^[^_]*_|_+$',''
		write-host "`nChecking $branch"
		write-host "Adding and committing files..." -ForegroundColor Yellow
		# Give the commit message the date and time. Easy to sort through.
		$timestamp = Get-Date -Format G
		$tagtime = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
		# Add untracked files, if any.
		git add .
		# Commit changes.
		git commit -S -am "Auto commit for $branch at $timestamp"
		# Push the commit to the correct branch.
		git push -u origin $branch
		# Tag the commit so you can simply download a zip at a later date.
		git tag "$branch`_$tagtime"
		# Push the tag
		git push origin --tags
		# Due to the bnet launcher being programmed to set its own permissions, need to make adjustments.
		# Each time the bnet launcher starts it does a permissions check. If it can't manage permissions on something it throws a fit with "Update" loops.
		# One such issue is read-only flags. Since git marks things has read-only to commit them, we have to unset it for next launch.
		write-host "Processing permissions..." -ForegroundColor Yellow
		dir ".git" -r * | ForEach-Object { attrib -r $_.FullName }
		write-host "Complete!" -ForegroundColor Green
		start-sleep 3
	}
	else {
		# Again converting path to string and trimming.
		# This time we just report no changes and close.
		$path = Convert-Path $_
		$branch = $path -replace '^[^_]*_|_+$',''
		write-host "`nChecking $branch"
		write-host "No changes" -ForegroundColor Green
		# Pause for a few seconds to review.
		start-sleep 3
	}
}