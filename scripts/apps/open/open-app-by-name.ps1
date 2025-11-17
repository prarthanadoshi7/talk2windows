<#
.SYNOPSIS
    Opens an application by name, checking if it's already running.
.DESCRIPTION
    This PowerShell script launches an application based on its name.
    If the application is already running, it will be brought to the foreground.
.PARAMETER AppName
    The name of the application to open.
#>

<#
id: open-app-by-name
name: Open App by Name
description: Launches a Windows application by its name, or brings it to the foreground if already running.
category: utility
risk_level: low
side_effects: Launches a new application window or focuses an existing one.
parameters:
  - name: AppName
    type: string
    description: The name of the application to open.
    required: true
examples:
  - description: Open the Grok application
    args: { AppName: "Grok" }
  - description: Launch the calculator
    args: { AppName: "Calculator" }
#>

param (
    [string]$AppName
)

try {
    & "$PSScriptRoot/../../say.ps1" "Okay, looking for $AppName."

    $apps = Get-StartApps | Where-Object { $_.Name.ToLower() -eq $AppName.ToLower() }

    if ($apps) {
        $app = $apps[0]
        $appId = $app.AppId

        # Always launch/activate the app - Start-Process handles both cases for UWP apps
        & "$PSScriptRoot/../../say.ps1" "Opening $($app.Name)."
        Start-Process "shell:AppsFolder\$appId"
    } else {
        & "$PSScriptRoot/../../say.ps1" "Sorry, I couldn't find an application named $AppName."
    }
}
catch {
    & "$PSScriptRoot/../../say.ps1" "Sorry, something went wrong while trying to open the application."
}
