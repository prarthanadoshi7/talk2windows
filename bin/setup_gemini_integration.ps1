<#
.SYNOPSIS
    Configures Talk2Windows with Gemini AI Integration
.DESCRIPTION
    This script sets up Serenade to use the Gemini AI powered Talk2Windows integration.
    It asks for user preferences, generates the correct configuration, ensures 
    Serenade uses only the AI version, and restarts Serenade properly.
.EXAMPLE
    PS> ./setup_gemini_integration.ps1 
.NOTES
    Author: Talk2Windows Team / License: CC0
.LINK
    https://github.com/fleschutz/talk2windows
#>

#requires -version 2

param([string]$filePattern = "$PSScriptRoot\scripts\*.ps1", [string]$targetFile = "$HOME\.serenade\scripts\Talk2WindowsGemini.js")

function Show-Banner {
    Clear-Host
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "          Talk2Windows + Gemini AI Integration Setup" -ForegroundColor Cyan  
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-SerenadeInstallation {
    Write-Host "[1/6] Checking Serenade installation..." -NoNewline
    if (!(Test-Path "~\.serenade" -pathType container)) { 
        Write-Host " NOT FOUND" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Please download and install Serenade from https://serenade.ai" -ForegroundColor Yellow
        exit 1
    }
    Write-Host " OK" -ForegroundColor Green
}

function Get-WakeWord {
    Write-Host "[2/6] Configuring wake word..." -NoNewline
    $wakeWord = Read-Host "Enter your personal wake word (e.g. Windows, Alexa, Computer)"
    if ([string]::IsNullOrWhiteSpace($wakeWord)) {
        $wakeWord = "Windows"
    }
    Write-Host " OK (using: $wakeWord)" -ForegroundColor Green
    return $wakeWord
}

function Stop-SerenadeProcesses {
    Write-Host "[3/6] Stopping any running Serenade instances..." -NoNewline
    try {
        Stop-Process -Name "Serenade" -Force -ErrorAction SilentlyContinue | Out-Null
        Start-Sleep -Seconds 2
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " OK (no instances found)" -ForegroundColor Green
    }
}

function Generate-GeminiConfig {
    param([string]$wakeWord, [string]$targetFile)
    
    Write-Host "[4/6] Generating Gemini-powered configuration..." -NoNewline
    try {
        # Ensure directory exists
        $dir = Split-Path -Parent $targetFile
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        # Get paths
        $pythonExe = (Get-Command python).Source -replace "\\", "\\"
        $projectRoot = (Split-Path -Parent $PSScriptRoot) -replace "\\", "\\"
        
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
    console.log('[Talk2Windows] Captured command:', userCommand);
    
    try {
        // Route to Gemini agent - run Python module from project root
        const result = await api.runShell(PYTHON_EXE, ["-m", "src.agent.integration.serenade_bridge", userCommand], {
            shell: true,
            cwd: PROJECT_ROOT
        });
        console.log('[Talk2Windows] Command result:', result);
    } catch (error) {
        console.error('[Talk2Windows] Command failed:', error);
    }
});

// Alternative patterns for better matching
serenade.global().command(WAKE_WORD + " <%action%> <%target%>", async (api, matches) => {        
    const userCommand = matches.action + ' ' + matches.target;
    console.log('[Talk2Windows] Alternative pattern - ' + userCommand);

    await api.runShell(PYTHON_EXE, ["-m", "src.agent.integration.serenade_bridge", userCommand], {
        shell: true,
        cwd: PROJECT_ROOT
    });
});

serenade.global().command(WAKE_WORD + " <%target%> <%action%>", async (api, matches) => {        
    const userCommand = matches.target + ' ' + matches.action;
    console.log('[Talk2Windows] Reverse pattern - ' + userCommand);

    await api.runShell(PYTHON_EXE, ["-m", "src.agent.integration.serenade_bridge", userCommand], {
        shell: true,
        cwd: PROJECT_ROOT
    });
});

// Quick commands for common actions (bypass Gemini for speed)
serenade.global().command(WAKE_WORD + " hello", async (api) => {
    await api.runShell(PYTHON_EXE, ["-m", "src.agent.integration.serenade_bridge", "say hello"], {
        shell: true,
        cwd: PROJECT_ROOT
    });
});

serenade.global().command(WAKE_WORD + " goodbye", async (api) => {
    await api.runShell(PYTHON_EXE, ["-m", "src.agent.integration.serenade_bridge", "say goodbye"], {
        shell: true,
        cwd: PROJECT_ROOT
    });
});

serenade.global().command(WAKE_WORD + " help", async (api) => {
    await api.runShell(PYTHON_EXE, ["-m", "src.agent.integration.serenade_bridge", "list available commands"], {
        shell: true,
        cwd: PROJECT_ROOT
    });
});
"@
        
        $js | Set-Content -Path $targetFile -Encoding UTF8
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Error "ERROR: $($_.Exception.Message)"
        exit 1
    }
}

function Update-BackendCatalog {
    Write-Host "[4.5/6] Updating backend tool catalog and semantic index..." -NoNewline
    try {
        $projectRoot = Split-Path -Parent $PSScriptRoot
        $pythonExe = (Get-Command python).Source
        
        # Generate tool catalog
        $catalogResult = & $pythonExe -c "from src.agent.core.tool_catalog_manager import ToolCatalogManager; tcm = ToolCatalogManager(); tcm.generate_catalog(); print('Catalog generated')" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host " WARNING" -ForegroundColor Yellow
            Write-Host "  Catalog generation had issues: $catalogResult" -ForegroundColor Yellow
        }
        
        # Rebuild semantic index
        $indexResult = & $pythonExe -c "from src.agent.core.semantic_index import SemanticIndex; si = SemanticIndex(); si.rebuild_index(); print('Semantic index rebuilt')" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host " WARNING" -ForegroundColor Yellow
            Write-Host "  Index rebuild had issues: $indexResult" -ForegroundColor Yellow
        }
        
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " WARNING" -ForegroundColor Yellow
        Write-Host "  Could not update backend catalog. Continuing..." -ForegroundColor Yellow
    }
}

function Disable-OldConfig {
    Write-Host "[5/7] Ensuring only AI configuration is active..." -NoNewline
    try {
        $oldConfig = "$HOME\.serenade\scripts\Talk2Windows.js"
        if (Test-Path $oldConfig) {
            # Rename the old config to disable it
            Rename-Item -Path $oldConfig -NewName "Talk2Windows.js.bak" -Force | Out-Null
        }
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " WARNING" -ForegroundColor Yellow
        Write-Host "  Could not disable old configuration. Please manually remove Talk2Windows.js" -ForegroundColor Yellow
    }
}

function Start-Serenade {
    Write-Host "[6/7] Starting Serenade application..." -NoNewline
    try {
        # Try common installation paths
        $serenadePaths = @(
            "$env:LOCALAPPDATA\Programs\Serenade\Serenade.exe",
            "$env:ProgramFiles\Serenade\Serenade.exe",
            "$env:ProgramFiles(x86)\Serenade\Serenade.exe"
        )
        
        $serenadeExe = $null
        foreach ($path in $serenadePaths) {
            if (Test-Path $path) {
                $serenadeExe = $path
                break
            }
        }
        
        if ($serenadeExe -and (Test-Path $serenadeExe)) {
            Start-Process -FilePath $serenadeExe -WindowStyle Normal | Out-Null
            Write-Host " OK" -ForegroundColor Green
        } else {
            # Try to find via registry or shortcuts
            $shortcutPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Serenade.lnk"
            if (Test-Path $shortcutPath) {
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut($shortcutPath)
                if (Test-Path $shortcut.TargetPath) {
                    Start-Process -FilePath $shortcut.TargetPath -WindowStyle Normal | Out-Null
                    Write-Host " OK" -ForegroundColor Green
                } else {
                    Write-Host " PARTIAL" -ForegroundColor Yellow
                    Write-Host "  Serenade installed but path not found. Please start manually." -ForegroundColor Yellow
                }
            } else {
                Write-Host " PARTIAL" -ForegroundColor Yellow
                Write-Host "  Serenade installation not found. Please start manually." -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host " PARTIAL" -ForegroundColor Yellow
        Write-Host "  Could not start Serenade automatically. Please start manually." -ForegroundColor Yellow
    }
}

function Show-Completion {
    Write-Host ""
    Write-Host "[7/7] Setup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "                     Setup Complete!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "✅ Serenade is now configured to use Talk2Windows with Gemini AI!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  1. Put on your headset and check audio/microphone levels" -ForegroundColor White
    Write-Host "  2. In Serenade, click the slider to switch to Listening mode" -ForegroundColor White
    Write-Host "  3. Say your wake word followed by a command:" -ForegroundColor White
    Write-Host ""
    Write-Host "Try saying:" -ForegroundColor Cyan
    Write-Host "  - tell me the time" -ForegroundColor Gray
    Write-Host "  - open calculator" -ForegroundColor Gray
    Write-Host "  - what's the weather" -ForegroundColor Gray
    Write-Host "  - launch chrome browser" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💡 The Gemini AI will understand natural language commands!" -ForegroundColor Yellow
    Write-Host ""
}

# Main execution
try {
    Show-Banner
    Test-SerenadeInstallation
    $wakeWord = Get-WakeWord
    Stop-SerenadeProcesses
    Generate-GeminiConfig -wakeWord $wakeWord -targetFile $targetFile
    Update-BackendCatalog
    Disable-OldConfig
    Start-Serenade
    Show-Completion
    exit 0 # success
} catch {
    Write-Error "ERROR: $($Error[0])"
    exit 1
}
