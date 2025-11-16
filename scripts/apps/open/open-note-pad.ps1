<#
.SYNOPSIS
    Launches the Notepad app
.DESCRIPTION
    This PowerShell script launches the Notepad application.
#>

<#
id: open-notepad
name: Open Notepad
description: Launches the Notepad application
category: productivity
risk_level: low
side_effects: Opens a new Notepad window
parameters: []
examples:
- description: Open Notepad
  args: {}
- description: Launch text editor
  args: {}
- description: Start Notepad application
  args: {}
#>

try {
	& "$PSScriptRoot/../../say.ps1" "Okay."
	Start-Process notepad.exe
	exit 0 
} catch {
	& "$PSScriptRoot/../../say.ps1" "Sorry: $($Error[0])"
	exit 1
}
