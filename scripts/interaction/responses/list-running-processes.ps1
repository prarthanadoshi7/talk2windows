<#
.SYNOPSIS
    Lists the running Processes
.DESCRIPTION
    This PowerShell script lists the running processes in a table.
#>

<#
id: list-running-processes
name: List Running Processes
description: Displays a grid view of all running processes
category: system
risk_level: low
side_effects: Opens a GUI window
parameters: []
examples:
- description: List running processes
  args: {}
#>

& "$PSScriptRoot/../../say.ps1" "OK."
Get-Process | Out-GridView -wait
