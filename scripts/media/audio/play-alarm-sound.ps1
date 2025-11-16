<#
.SYNOPSIS
    Plays an Alarm Sound
.DESCRIPTION
    This PowerShell script plays an alarm sound.
#>

& "$PSScriptRoot/../../_core/_play-sound.ps1" "$PSScriptRoot/data/sounds/alarm.wav"
exit 0 # success
