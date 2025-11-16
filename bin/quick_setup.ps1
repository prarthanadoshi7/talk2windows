# Talk2Windows + Gemini AI - Quick Setup

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "          Talk2Windows + Gemini AI Integration" -ForegroundColor Cyan  
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Check API key
Write-Host "[1/3] Checking Gemini API key..." -NoNewline
if ($env:TALK2WINDOWS_GEMINI_API_KEY) {
    Write-Host " OK" -ForegroundColor Green
} else {
    Write-Host " MISSING" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Get API key from: https://makersuite.google.com/app/apikey" -ForegroundColor Yellow
    Write-Host "  Then run:" -ForegroundColor Yellow
    Write-Host "  [Environment]::SetEnvironmentVariable('TALK2WINDOWS_GEMINI_API_KEY', 'your-key', 'User')" -ForegroundColor Yellow
    exit 1
}

# Install Python packages
Write-Host "[2/3] Installing Python packages..." -NoNewline
try {
    pip install -q google-generativeai pyyaml keyring | Out-Null
    Write-Host " OK" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    exit 1
}

# Build semantic index
Write-Host "[3/3] Building semantic index..." -NoNewline
try {
    $output = python -m src.agent.semantic_index 2>&1 | Out-String
    if ($output -match "Built index with (\d+) scripts") {
        $count = $Matches[1]
        Write-Host " OK ($count scripts)" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "                     Setup Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Usage:" -ForegroundColor Cyan
Write-Host "  python -m src.agent.service" -ForegroundColor White
Write-Host ""
Write-Host "Try saying:" -ForegroundColor Cyan
Write-Host "  - tell me the time" -ForegroundColor Gray
Write-Host "  - open calculator" -ForegroundColor Gray
Write-Host "  - what's the weather" -ForegroundColor Gray
Write-Host "  - launch chrome browser" -ForegroundColor Gray
Write-Host ""
