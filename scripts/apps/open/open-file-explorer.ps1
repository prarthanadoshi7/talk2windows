<#
.SYNOPSIS
    Launches the File Explorer
.DESCRIPTION
    This PowerShell script launches the File Explorer (optional with the given path).
#>

<#
id: open-file-explorer
name: Open File Explorer
description: Launches the File Explorer, optionally with a specified path
category: system
risk_level: low
side_effects: Opens File Explorer window
parameters:
- name: path
  type: string
  description: The path to open in File Explorer
  required: false
examples:
- description: Open File Explorer
  args: {}
- description: Open File Explorer to root
  args: {}
- description: Open File Explorer to a specific folder
  args: {"path": "C:\\Users"}
#>

param([string]$path = "")

try {
	if ("$path" -ne "") {
		Start-Process explorer.exe "$path"
	} else {
		Start-Process explorer.exe
	}
	exit 0 # success
} catch {
	& "$PSScriptRoot/../../say.ps1" "Sorry: $($Error[0])"
	exit 1
}
