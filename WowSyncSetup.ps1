<#
.SYNOPSIS
WoW Sync Setup Helper

.DESCRIPTION
v1.0.0
Helps you setup syncing your World of Warcraft Interface AddOns, WTF, and Fonts with git accounts.

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
#if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process pwsh.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# First move to the root of WoW. You may need to alter this path if you installed WoW somewhere else.
Set-Location "C:\Program Files (x86)\World of Warcraft"
write-host "If you have not already done so, create a repo with GitHub, GitLab, or Gitea."
$origin = Read-Host -Prompt 'Enter the full URL to your git repo'

# Then look through for different install versions.
Get-ChildItem -Path "_*_" | ForEach-Object {
	# Once they are found, check the git status to make sure there isn't one there.
	if (Set-Location $_ && git status | Select-String -Pattern "not a git repository" ) {
		write-host "`nCreating a repo" -ForegroundColor Green
		# Before pushing, a branch has to be specified. There is already a variable that collects this information: the path.
		# The path must be converted to a string.
		$path = Convert-Path $_
		# Trim the path string down to the version using regex and use that as the branch to push to.
		$branch = $path -replace '^[^_]*_|_+$',''
		# Create the branch
		git init -b $branch --shared=false
		# Ignore lots of stuff
		Set-Content ".gitignore" -Value "# Don't upload these
		Cache/
		Errors/
		Logs/
		Screenshots/
		Utils/
		*.exe
		*.dll"
		# Set the end of file type
		git config core.autocrlf false
		# add all your files
		git add .
		# Commit them
		git commit -am "Upload"
		#git commit -S -am "Upload"
		# Specify the origin which is what you set earlier with the URL
		git remote add origin $origin
		# Specify branch
		git branch -M $branch
		# Upload files
		git push -u origin $branch
		start-sleep 3
	}
	else {
		write-host "This location already has a git repo!" -ForegroundColor Red
		# Pause for a few seconds to review.
		start-sleep 3
	}
}