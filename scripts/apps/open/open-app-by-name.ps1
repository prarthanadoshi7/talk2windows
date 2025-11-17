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
keywords:
    - app
    - application
    - launch
    - start
    - run
parameters:
  - name: AppName
    type: string
    description: The name of the application to open (supports fuzzy matching with installed apps).
    required: true
examples:
  - description: Open the Grok application
    args: { AppName: "Grok" }
  - description: Launch the calculator
    args: { AppName: "Calculator" }
  - description: Open BLACKBOX.AI application
    args: { AppName: "BLACKBOX.AI" }
#>

param (
    [string]$AppName
)

try {
    & "$PSScriptRoot/../../say.ps1" "Okay, looking for $AppName."

    $allApps = Get-StartApps
    $appNameLower = $AppName.ToLower()
    
    # Try exact match first (case-insensitive)
    $app = $allApps | Where-Object { $_.Name.ToLower() -eq $appNameLower } | Select-Object -First 1
    
    # If no exact match, try contains matching
    if (-not $app) {
        $app = $allApps | Where-Object { $_.Name.ToLower() -like "*$appNameLower*" } | Select-Object -First 1
    }
    
    # If still no match, try matching all words (e.g., "task manager" matches "Task Manager")
    if (-not $app) {
        $searchWords = $appNameLower -split '\s+'
        $app = $allApps | Where-Object { 
            $name = $_.Name.ToLower()
            $allWordsMatch = $true
            foreach ($word in $searchWords) {
                if ($name -notlike "*$word*") {
                    $allWordsMatch = $false
                    break
                }
            }
            $allWordsMatch
        } | Select-Object -First 1
    }

    if ($app) {
        $appId = $app.AppId
        & "$PSScriptRoot/../../say.ps1" "Opening $($app.Name)."
        Start-Process "shell:AppsFolder\$appId"
    } else {
        & "$PSScriptRoot/../../say.ps1" "Sorry, I couldn't find an application named $AppName."
    }
}
catch {
    & "$PSScriptRoot/../../say.ps1" "Sorry, something went wrong while trying to open the application."
}
