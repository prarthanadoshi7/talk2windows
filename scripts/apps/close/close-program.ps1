<#
.SYNOPSIS
    Closes a program's processes 
.DESCRIPTION
    This PowerShell script closes a program's processes gracefully.
.PARAMETER FullProgramName
    Specifies the full program name
.PARAMETER ProgramName
    Specifies the program name
.PARAMETER ProgramAliasName
    Specifies the program alias name
.EXAMPLE
    PS> ./close-program "Google Chrome" "chrome.exe"
.NOTES
    Author: Markus Fleschutz / License: CC0
.LINK
    https://github.com/fleschutz/talk2windows
#>

<#
id: close-program
name: Close Program
description: Closes a program's processes gracefully
category: system
risk_level: low
side_effects: Terminates running processes
parameters:
- name: FullProgramName
  type: string
  description: The full name of the program to close
  required: false
- name: ProgramName
  type: string
  description: The process name (e.g., chrome.exe)
  required: true
- name: ProgramAliasName
  type: string
  description: Alternative process name if primary fails
  required: false
examples:
- description: Close Google Chrome
  args: {"ProgramName": "chrome"}
- description: Close Notepad with alias
  args: {"ProgramName": "notepad", "ProgramAliasName": "notepad.exe"}
#>

param([string]$FullProgramName = "", [string]$ProgramName = "", [string]$ProgramAliasName = "")

try {
	if ($ProgramName -eq "") {
		get-process | where-object {$_.mainWindowTitle} | format-table Id, Name, mainWindowtitle -AutoSize
		$ProgramName = read-host "Enter program name"
	}
	if ($FullProgramName -eq "") {
		$FullProgramName = $ProgramName
	}

	$Processes = get-process -name $ProgramName -errorAction 'silentlycontinue'
	if ($Processes.Count -ne 0) {
		foreach ($Process in $Processes) {
			$Process.CloseMainWindow() | Out-Null
		} 
		start-sleep -milliseconds 100
		stop-process -name $ProgramName -force -errorAction 'silentlycontinue'
	} else {
		$Processes = get-process -name $ProgramAliasName -errorAction 'silentlycontinue'
		if ($Processes.Count -eq 0) {
			throw "$FullProgramName isn't running"
		}
		foreach ($Process in $Processes) {
			$_.CloseMainWindow() | Out-Null
		} 
		start-sleep -milliseconds 100
		stop-process -name $ProgramName -force -errorAction 'silentlycontinue'
	}
	if ($($Processes.Count) -eq 1) {
		"$FullProgramName closed (1 process stopped)."
	} else {
		"$FullProgramName closed ($($Processes.Count) processes stopped)."
	}
	exit 0 # success
} catch {
	& "$PSScriptRoot/../../say.ps1" "Sorry: $($Error[0])"
	exit 1
}
