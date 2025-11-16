<#
.SYNOPSIS
    Closes Notepad
.DESCRIPTION
    This PowerShell script closes the Notepad application gracefully.
#>

<#
id: close-notepad
name: Close Notepad
description: Closes the Notepad application gracefully
category: productivity
risk_level: low
side_effects: Terminates Notepad processes
parameters: []
examples:
- description: Close Notepad
  args: {}
- description: Exit text editor
  args: {}
- description: Stop Notepad application
  args: {}
#>

& "$PSScriptRoot/../../say.ps1" "Okay."
& "$PSScriptRoot/close-program.ps1" "Notepad" "notepad" "notepad"
exit 0 # success
