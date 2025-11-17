param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptID,

    [Parameter(Mandatory=$true)]
    [string]$ParamsJson
)

try {
    if ($ScriptID -match '\.\.') {
        throw "Invalid script id: $ScriptID"
    }
    
    # If ScriptID contains path separators, use it as-is (relative to scripts/)
    # Otherwise, search recursively in scripts/ directory
    $scriptsRoot = Join-Path $PSScriptRoot "../../../scripts"
    
    if ($ScriptID -match '[\\/]') {
        # Path provided, use it directly
        $scriptPath = Join-Path $scriptsRoot "$ScriptID.ps1"
    } else {
        # Search for script recursively
        $found = Get-ChildItem -Path $scriptsRoot -Recurse -Filter "$ScriptID.ps1" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            $scriptPath = $found.FullName
        } else {
            $scriptPath = Join-Path $scriptsRoot "$ScriptID.ps1"
        }
    }
    $paramsJson = $ParamsJson | ConvertFrom-Json
    $params = @{}
    if ($paramsJson) {
        $paramsJson.PSObject.Properties | ForEach-Object { $params[$_.Name] = $_.Value }
    }
} catch {
    $stderr = "Invalid JSON in ParamsJson: $($_.Exception.Message)"
    $exit_code = -1
    $result = @{
        exit_code = $exit_code
        stdout = ""
        stderr = $stderr
    }
    Write-Output ($result | ConvertTo-Json -Compress)
    exit
}

$stdout = ""
$stderr = ""
$exit_code = 0

# Generate unique temp file names
$tempStdout = "stdout_$([guid]::NewGuid().ToString()).tmp"
$tempStderr = "stderr_$([guid]::NewGuid().ToString()).tmp"

try {
    if (-not (Test-Path $scriptPath)) {
        throw "Script not found: $ScriptID"
    }

    # Build argument list
    $argList = @("-NoProfile", "-File", $scriptPath)
    foreach ($param in $params.GetEnumerator()) {
        $argList += "-$($param.Key)"
        $argList += $param.Value
    }

    # Execute the target script
    $process = Start-Process powershell.exe -ArgumentList $argList -PassThru -Wait -RedirectStandardOutput $tempStdout -RedirectStandardError $tempStderr
    
    $stdout = Get-Content $tempStdout -Raw
    $stderr = Get-Content $tempStderr -Raw
    $exit_code = $process.ExitCode

} catch {
    $stderr = $_.Exception.Message
    $exit_code = -1
} finally {
    # Clean up temp files
    Remove-Item $tempStdout, $tempStderr -ErrorAction SilentlyContinue

    # Output the results as a single JSON object
    $result = @{
        exit_code = $exit_code
        stdout = $stdout
        stderr = $stderr
    }
    Write-Output ($result | ConvertTo-Json -Compress)
}