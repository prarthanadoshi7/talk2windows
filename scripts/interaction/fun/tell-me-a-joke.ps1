<#
.SYNOPSIS
    Tells a joke
.DESCRIPTION
    This PowerShell script tells a random Chuck Norris joke from data/jokes.csv by text-to-speech (TTS).
#>

<#
id: tell-me-a-joke
name: Tell Me a Joke
description: Tells a random joke using text-to-speech
category: entertainment
risk_level: low
side_effects: none
parameters: []
examples:
- description: Tell a joke
  args: {}
#>

try {
	$Table = Import-CSV "$PSScriptRoot/data/jokes.csv"

	$Generator = New-Object System.Random
	$Index = [int]$Generator.next(0, $Table.Count - 1)
	$reply = $Table[$Index].Joke
} catch { $reply = "Sorry: $($Error[0])" }
& "$PSScriptRoot/../../say.ps1" $reply
