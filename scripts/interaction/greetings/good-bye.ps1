<#
.SYNOPSIS
    Replies to 'good bye'
.DESCRIPTION
    This PowerShell script says a reply to 'good bye' by text-to-speech (TTS).
#>

<#
id: say-goodbye
name: Say Goodbye
description: Responds with a farewell message using text-to-speech
category: communication
risk_level: low
side_effects: Plays audio farewell
parameters: []
examples:
- description: Say goodbye
  args: {}
- description: Farewell response
  args: {}
- description: Goodbye message
  args: {}
#>

$reply = "Bye!", "Bye bye!", "Good bye!", "See you!", "Cheers!", "So long!", "Take care!" | Get-Random
& "$PSScriptRoot/../../say.ps1" $reply
