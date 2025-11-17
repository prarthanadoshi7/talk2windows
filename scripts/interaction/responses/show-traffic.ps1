<#
.SYNOPSIS
    Shows the current traffic 
.DESCRIPTION
    This PowerShell script launches the Web browser with MSN showing the current traffic.
#>

& "$PSScriptRoot/../../say.ps1" "Hold on."
& "\$PSScriptRoot/../../apps/open/open-browser.ps1" "https://www.msn.com/en-us/traffic?lvl=11&intent=roadClosures"

