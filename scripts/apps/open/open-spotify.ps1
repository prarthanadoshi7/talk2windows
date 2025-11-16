<#
.SYNOPSIS
    Launches the Spotify app
.DESCRIPTION
    This PowerShell script launches the Spotify application.
#>

<#
id: open-spotify
name: Open Spotify
description: Launches the Spotify application
category: entertainment
risk_level: low
side_effects: Opens Spotify application
parameters: []
examples:
- description: Open Spotify
  args: {}
- description: Launch music player
  args: {}
- description: Start Spotify app
  args: {}
#>

& "$PSScriptRoot/../../say.ps1" "Hold on."
Start-Process spotify:
