<#
.SYNOPSIS
    Plays folk music
.DESCRIPTION
    This PowerShell script launches the Web browser and plays folk music.
#>

& "$PSScriptRoot/../../say.ps1" "Okay."
& "$PSScriptRoot/../../apps/open/open-browser.ps1" "http://streema.com/radios/play/Real_Country_96.5_KBDN"
