<#
.SYNOPSIS
    Replies to "What's the time?" 
.DESCRIPTION
    This PowerShell script speaks the current time by text-to-speech (TTS).
#>

<#
id: what-is-the-time
name: What is the Time
description: Announces the current time using text-to-speech
category: information
risk_level: low
side_effects: none
parameters: []
examples:
- description: Tell the current time
  args: {}
#>

try {
	[system.threading.thread]::currentThread.currentCulture = [system.globalization.cultureInfo]"en-US"
	$CurrentTime = (Get-Date).ToShortTimeString()

	& "$PSScriptRoot/../../say.ps1" "It's $CurrentTime."
	exit 0 # success
} catch {
	& "$PSScriptRoot/../../say.ps1" "Sorry: $($Error[0])"
	exit 1
}
