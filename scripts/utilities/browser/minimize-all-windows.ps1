<#
.SYNOPSIS
    Minimizes all windows
.DESCRIPTION
    This PowerShell script minimizes all open windows.
#>

<#
id: minimize-all-windows
name: Minimize All Windows
description: Minimizes all currently open windows
category: system
risk_level: low
side_effects: Minimizes all application windows
parameters: []
examples:
- description: Minimize all windows
  args: {}
- description: Hide all open apps
  args: {}
- description: Clear desktop
  args: {}
#>

try {
	$shell = New-Object -ComObject "Shell.Application"
	$shell.minimizeall()
	exit 0 # success
} catch {
	& "$PSScriptRoot/../../say.ps1" "Sorry: $($Error[0])"
	exit 1
}
