<#
.SYNOPSIS
    Launches the Microsoft Teams app
.DESCRIPTION
    This PowerShell script launches the Microsoft Teams application.
#>

<#
id: open-teams
name: Open Teams
description: Launches the Microsoft Teams application
category: communication
risk_level: low
side_effects: Opens Teams application
parameters: []
examples:
- description: Open Microsoft Teams
  args: {}
- description: Launch Teams
  args: {}
- description: Start Teams app
  args: {}
#>

try {
	Start-Process msteams:
	exit 0 # success
} catch {
	& "$PSScriptRoot/../../say.ps1" "Sorry: $($Error[0])"
	exit 1
}
