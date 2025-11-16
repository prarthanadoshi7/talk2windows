<#
.SYNOPSIS
    Opens the recycle bin folder
.DESCRIPTION
    This PowerShell script launches the File Explorer with the user's recycle bin folder.
#>

<#
id: open-recycle-bin
name: Open Recycle Bin
description: Opens the recycle bin folder in File Explorer
category: system
risk_level: low
side_effects: Opens File Explorer to recycle bin
parameters: []
examples:
- description: Open recycle bin
  args: {}
- description: Show trash
  args: {}
- description: Launch recycle bin folder
  args: {}
#>

start shell:recyclebinfolder
& "$PSScriptRoot/../../say.ps1" "Your recycle bin."
