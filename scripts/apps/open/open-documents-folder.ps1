<#
.SYNOPSIS
    Opens the documents folder
.DESCRIPTION
    This PowerShell script launches the File Explorer with the documents folder.
#>

<#
id: open-documents
name: Open Documents
description: Opens the user's documents folder in File Explorer
category: system
risk_level: low
side_effects: Opens File Explorer to documents folder
parameters: []
examples:
- description: Open documents folder
  args: {}
- description: Show my documents
  args: {}
- description: Launch documents directory
  args: {}
#>

try {
        $path = [Environment]::GetFolderPath('MyDocuments')
	if (-not(Test-Path "$path" -pathType container)) { throw "Your documents folder at $path doesn't exist (yet)" }
	& "$PSScriptRoot/open-file-explorer.ps1" "$path"
	$reply = "Your documents."
} catch { $reply = "Sorry: $($Error[0])" }
& "$PSScriptRoot/../../say.ps1" $reply
