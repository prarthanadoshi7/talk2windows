<#
.SYNOPSIS
    Opens the calculator
.DESCRIPTION
    This PowerShell script launches the calculator application.
#>

<#
id: open-calculator
name: Open Calculator
description: Launches the Windows Calculator application
category: utility
risk_level: low
side_effects: Launches a new application window
parameters: []
examples:
- description: Open the calculator application
  args: {}
#>

& "$PSScriptRoot/../../say.ps1" "Okay."
Start-Process ms-calculator:

