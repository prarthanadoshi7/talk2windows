<#
.SYNOPSIS
    Replies to "Say hello"
.DESCRIPTION
    This PowerShell script replies to "Say hello" by text-to-speech (TTS).
#>

<#
id: say-hello
name: Say Hello
description: Responds with a greeting using text-to-speech
category: communication
risk_level: low
side_effects: Plays audio greeting
parameters: []
examples:
- description: Say hello
  args: {}
- description: Greet the user
  args: {}
- description: Hello response
  args: {}
#>

& "$PSScriptRoot/../../say.ps1" "Hello everyone."
