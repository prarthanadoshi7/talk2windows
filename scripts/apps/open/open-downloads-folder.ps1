<#
.SYNOPSIS
    Opens the user's downloads folder
.DESCRIPTION
    This PowerShell script launches the File Explorer showing the user's downloads folder.
#>

<#
id: open-downloads
name: Open Downloads
description: Opens the user's downloads folder in File Explorer
category: system
risk_level: low
side_effects: Opens File Explorer to downloads folder
parameters: []
examples:
- description: Open downloads folder
  args: {}
- description: Show my downloads
  args: {}
- description: Launch downloads directory
  args: {}
#>

try {
	$path = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
	if (-not(Test-Path "$path" -pathType container)) { throw "Your downloads folder at $path is currently missing" }
	& "$PSScriptRoot/open-file-explorer.ps1" "$path"
	$reply = "Your downloads."
} catch { $reply = "Sorry: $($Error[0])" }
& "$PSScriptRoot/../../say.ps1" $reply
