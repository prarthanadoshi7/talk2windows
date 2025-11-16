<#
.SYNOPSIS
    Checks the weather 
.DESCRIPTION
    Queries the current weather report and tells it by text-to-speech (TTS).
.EXAMPLE
    PS> ./check-weather
.LINK
    https://github.com/fleschutz/talk2windows
.NOTES
    Author: Markus Fleschutz | License: CC0
#>

<#
id: check-weather
name: Check Weather
description: Retrieves and announces current weather conditions
category: information
risk_level: low
side_effects: Makes HTTP request to weather service
parameters:
- name: location
  type: string
  description: Location for weather check (empty for auto-detect)
  required: false
examples:
- description: Check weather for current location
  args: {}
- description: Check weather for New York
  args: {"location": "New York"}
#>

param([string]$location = "") # empty means determine automatically

try {
	$Weather = (Invoke-WebRequest http://wttr.in/${location}?format=j1 -userAgent "curl" -useBasicParsing).Content | ConvertFrom-Json

	$Temp = $Weather.current_condition.temp_C
	$Precip = $Weather.current_condition.precipMM
	$Humidity = $Weather.current_condition.humidity
	$WindSpeed = $Weather.current_condition.windspeedKmph
	$WindDir = $Weather.current_condition.winddir16Point
	$Clouds = $Weather.current_condition.cloudcover
	$Visib = $Weather.current_condition.visibility

	& "$PSScriptRoot/../../say.ps1" "$Temp degrees celcius, $($Precip)mm rain, $($Humidity)% humidity, $($WindSpeed)km/h wind from $WindDir with $($Clouds)% clouds and $($Visib)km visibility."
	exit 0 # success
} catch {
	& "$PSScriptRoot/../../say.ps1" "Sorry: $($Error[0])"
	exit 1
}
