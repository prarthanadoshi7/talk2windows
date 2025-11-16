<#
.SYNOPSIS
    Launches Edge 
.DESCRIPTION
    This PowerShell script launches the Microsoft Edge Web browser.
#>

<#
id: open-edge
name: Open Edge
description: Launches the Microsoft Edge Web browser
category: productivity
risk_level: low
side_effects: Opens a new browser window
parameters: []
examples:
- description: Open Microsoft Edge
  args: {}
- description: Launch Edge browser
  args: {}
- description: Start Edge
  args: {}
#>

& "$PSScriptRoot/../../say.ps1" "Okay"
Start-Process microsoft-edge://
