<#
.SYNOPSIS
    Generate Serenade configuration that uses Gemini AI backend
.DESCRIPTION
    This creates a Serenade JavaScript file that routes voice commands
    through the Gemini agent for smart natural language understanding.
#>

param(
    [string]$wakeWord = "Windows",
    [string]$targetFile = "$HOME\.serenade\scripts\Talk2WindowsGemini.js"
)

try {
    Write-Host "Generating Gemini-powered Serenade configuration..." -ForegroundColor Cyan
    
    # Ensure directory exists
    $dir = Split-Path -Parent $targetFile
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    # Get paths
    $pythonExe = (Get-Command python).Source -replace "\\", "\\\\"
    $projectRoot = (Split-Path -Parent $PSScriptRoot) -replace "\\", "\\\\"
    
    # Generate JavaScript configuration
    $js = @"
/* 
 * Talk2Windows + Gemini AI Integration
 * Generated automatically - routes voice commands through Gemini for smart NLU
 */

// Configuration
const PYTHON_EXE = "$pythonExe";
const PROJECT_ROOT = "$projectRoot";
const WAKE_WORD = "$($wakeWord.toLower())";

// Main voice command handler - routes everything to Gemini
serenade.global().command(WAKE_WORD + " <%text%>", async (api, matches) => {
    const userCommand = matches.text;
    
    // Route to Gemini agent - run Python module from project root
    await api.runShell(PYTHON_EXE, ["-m", "src.agent.serenade_bridge", userCommand], {
        shell: true,
        cwd: PROJECT_ROOT
    });
});

// Quick commands for common actions (bypass Gemini for speed)
serenade.global().command(WAKE_WORD + " hello", async (api) => {
    await api.runShell(PYTHON_EXE, ["-m", "src.agent.serenade_bridge", "say hello"], {
        shell: true,
        cwd: PROJECT_ROOT
    });
});

serenade.global().command(WAKE_WORD + " goodbye", async (api) => {
    await api.runShell(PYTHON_EXE, ["-m", "src.agent.serenade_bridge", "say goodbye"], {
        shell: true,
        cwd: PROJECT_ROOT
    });
});

serenade.global().command(WAKE_WORD + " help", async (api) => {
    await api.runShell(PYTHON_EXE, ["-m", "src.agent.serenade_bridge", "list available commands"], {
        shell: true,
        cwd: PROJECT_ROOT
    });
});
"@
    
    $js | Set-Content -Path $targetFile -Encoding UTF8
    
    Write-Host "✅ Generated: $targetFile" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage in Serenade:" -ForegroundColor Cyan
    Write-Host "  • '$wakeWord tell me the time'" -ForegroundColor White
    Write-Host "  • '$wakeWord open calculator'" -ForegroundColor White
    Write-Host "  • '$wakeWord what's the weather'" -ForegroundColor White
    Write-Host "  • '$wakeWord launch chrome browser'" -ForegroundColor White
    Write-Host ""
    Write-Host "The Gemini agent will understand natural language!" -ForegroundColor Green
    
    exit 0
} catch {
    Write-Error "ERROR: $($_.Exception.Message)"
    exit 1
}
 
