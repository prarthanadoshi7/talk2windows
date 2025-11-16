# 04: PowerShell Executor

The PowerShell Executor is the bridge between the Python-based Agent Service and the Talk2Windows PowerShell script library. Its sole purpose is to execute a specified `.ps1` script with the correct arguments in a secure and observable way.

## 1. Design

Instead of having the Python service build complex PowerShell commands as strings, we will use a dedicated wrapper script. This approach is cleaner, more secure, and easier to manage.

The Agent Service will invoke a single, generic PowerShell script (e.g., `run-script.ps1`) and pass it two arguments:
1.  The name of the target script to run (e.g., `close-program`).
2.  A JSON string containing the parameters for the target script.

This `run-script.ps1` wrapper will then be responsible for constructing and executing the final command.

## 2. `run-script.ps1` Wrapper

This script will be the only PowerShell script that the Python Agent Service directly calls.

### Responsibilities:

1.  **Accept Arguments:** It will define two parameters: `$ScriptID` and `$ParamsJson`.
2.  **Find Script Path:** It will construct the full path to the target script (e.g., `$PSScriptRoot/../scripts/$ScriptID.ps1`).
3.  **Parse Parameters:** It will parse the `$ParamsJson` string into a PowerShell hashtable.
4.  **Construct Command:** It will dynamically build the command to execute the target script, splatting the hashtable of parameters to it. This is safer than string concatenation.
5.  **Execute:** It will execute the command.
6.  **Capture Output:** It will capture `stdout`, `stderr`, and the script's `exit code`.
7.  **Return Structured Output:** It will format the results into a single JSON object and write it to its own standard output. This gives the Python parent process a single, easy-to-parse string to consume.

### Example Invocation from Python

```python
# In AgentService, calling the executor
import subprocess
import json

def run(tool_name, args):
    executor_path = "path/to/run-script.ps1"
    params_json = json.dumps(args)

    # The command to run the wrapper
    command = [
        "powershell.exe",
        "-NoProfile",
        "-File",
        executor_path,
        "-ScriptID",
        tool_name,
        "-ParamsJson",
        params_json
    ]

    # Execute and capture output
    result = subprocess.run(command, capture_output=True, text=True)

    # The wrapper script's stdout is a JSON object with the results
    try:
        output = json.loads(result.stdout)
        return output['exit_code'], output['stdout'], output['stderr']
    except (json.JSONDecodeError, KeyError):
        # Handle cases where the wrapper itself failed
        return -1, "", f"Executor script failed: {result.stderr}"
```

### Example `run-script.ps1` Implementation

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptID,

    [Parameter(Mandatory=$true)]
    [string]$ParamsJson
)

$scriptPath = Join-Path $PSScriptRoot "scripts/$ScriptID.ps1"
$params = $ParamsJson | ConvertFrom-Json -AsHashtable

$stdout = ""
$stderr = ""
$exit_code = 0

try {
    if (-not (Test-Path $scriptPath)) {
        throw "Script not found: $ScriptID"
    }

    # Execute the target script, splatting the parameters
    # Redirect stdout and stderr to capture them
    $process = Start-Process pwsh -ArgumentList "-NoProfile -File `"$scriptPath`" @params" -PassThru -Wait -RedirectStandardOutput "stdout.tmp" -RedirectStandardError "stderr.tmp"
    
    $stdout = Get-Content "stdout.tmp" -Raw
    $stderr = Get-Content "stderr.tmp" -Raw
    $exit_code = $process.ExitCode

} catch {
    $stderr = $_.Exception.Message
    $exit_code = -1
} finally {
    # Clean up temp files
    Remove-Item "stdout.tmp", "stderr.tmp" -ErrorAction SilentlyContinue

    # Output the results as a single JSON object
    $result = @{
        exit_code = $exit_code
        stdout = $stdout
        stderr = $stderr
    }
    Write-Output ($result | ConvertTo-Json -Compress)
}
```
*(Note: The exact implementation of output redirection and process management might be refined for robustness, but this illustrates the core concept.)*

This architecture creates a clean, secure, and observable interface between the agent's "brain" and its "hands," which is fundamental to the Plan-Act-Observe loop.
