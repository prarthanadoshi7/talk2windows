<#
.SYNOPSIS
    Checks the Internet Speed
.DESCRIPTION
    This PowerShell script launches the Web browser with Cloudflare's Speed Test website.
.EXAMPLE
    PS> ./check-internet-speed
.NOTES
    Author: Markus Fleschutz / License: CC0
.LINK
    https://github.com/fleschutz/talk2windows
#>

<#
id: check-internet-speed
name: Check Internet Speed
description: Opens Cloudflare's speed test website to check internet connection speed
category: information
risk_level: low
side_effects: Opens web browser to speed test site
parameters: []
examples:
- description: Check internet speed
  args: {}
- description: Test connection speed
  args: {}
- description: Run speed test
  args: {}
#>

& "$PSScriptRoot/../../apps/open/open-browser.ps1" "https://speed.cloudflare.com/"
exit 0 # success
