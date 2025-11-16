<#
.SYNOPSIS
    Launches Firefox
.DESCRIPTION
    This PowerShell script launches the Mozilla Firefox Web browser.
#>

<#
id: open-firefox
name: Open Firefox
description: Launches the Mozilla Firefox Web browser
category: productivity
risk_level: low
side_effects: Opens a new browser window
parameters:
- name: URL
  type: string
  description: The URL to open in Firefox
  required: false
examples:
- description: Open Firefox
  args: {}
- description: Launch Firefox with default page
  args: {}
- description: Open Firefox to a specific URL
  args: {"URL": "https://example.com"}
#>

param([string]$URL = "http://www.fleschutz.de")

try {
	& "$PSScriptRoot/../../say.ps1" "Hold on."

	Start-Process firefox.exe "$URL"
	exit 0 # success
} catch {
	& "$PSScriptRoot/../../say.ps1" "Sorry: $($Error[0])"
	exit 1
}
