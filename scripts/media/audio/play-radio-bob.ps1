<#
.SYNOPSIS
    Plays radio BOB!
.DESCRIPTION
    This PowerShell script launches the Web browser and plays radio BOB!
#>

& "$PSScriptRoot/../../say.ps1" "Oh yeah!"
& "$PSScriptRoot/../../apps/open/open-browser.ps1" "https://streema.com/radios/play/RADIO_BOB_BOBs_Alternative"
exit 0 # success
