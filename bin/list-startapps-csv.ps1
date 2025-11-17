#<
#.SYNOPSIS
#    Lists all Start Menu apps and saves them to a delimited file (CSV/TSV).
#.DESCRIPTION
#    Enumerates UWP and other apps available via Get-StartApps and writes their
#    Name and AppID to a delimited text file. Supports custom output file and delimiter.
#.PARAMETER OutputFile
#    The path where the output will be written. Defaults to `startapps.csv` in the user's home.
#.PARAMETER Delimiter
#    The delimiter to use for the file. Default is comma (CSV). Use `\t` for TSV.
#.EXAMPLE
#    ./list-startapps-csv.ps1 -OutputFile "C:\Temp\apps.csv" -Delimiter ","
#>

<#
id: list-startapps
name: List Start Apps
description: Lists Start menu application names and AppIDs and saves as delimited output.
category: utility
risk_level: low
side_effects: None — reads system app list and writes file to disk.
parameters:
    - name: OutputFile
        type: string
        description: Destination file path for the CSV/TSV output
        required: false
    - name: Delimiter
        type: string
        description: Delimiter to use in output file (comma for CSV, tab for TSV)
        required: false
examples:
    - description: Export to CSV
        args: { OutputFile: "C:\\Temp\\startapps.csv", Delimiter: "," }
    - description: Export to TSV
        args: { OutputFile: "C:\\Temp\\startapps.tsv", Delimiter: "\t" }
#>

param(
    [string] $OutputFile = "$env:USERPROFILE\startapps.csv",
    [string] $Delimiter = ","
)

try {
    # Ensure output directory exists
    $outDir = Split-Path -Parent $OutputFile
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

    # Get the list of apps
    $apps = Get-StartApps | Select-Object Name, AppID

    if (-not $apps) {
        Write-Host "No Start Apps found."
        exit 0
    }

    # Write header and rows with specified delimiter
    $lines = @()
    $lines += "Name${Delimiter}AppID"
    foreach ($app in $apps) {
        $name = $app.Name -replace '"', '""'
        $id = $app.AppID -replace '"', '""'
        $lines += """$name""${Delimiter}""$id"""
    }

    $lines | Out-File -FilePath $OutputFile -Encoding UTF8 -Force
    Write-Host "Saved $($apps.Count) apps to $OutputFile"
} catch {
    Write-Host "Error generating app list: $($_.Exception.Message)"
    exit 1
}
