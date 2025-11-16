# Update all Python imports from agent. to src.agent.

$rootPath = "d:\Projects\project-exploration\interactive_pc\talk2windows"

Write-Host "Updating Python imports..." -ForegroundColor Cyan

# Find all Python files
$pyFiles = Get-ChildItem -Path $rootPath -Recurse -Filter "*.py" -File | Where-Object {
    $_.FullName -notlike "*__pycache__*" -and
    $_.FullName -like "*talk2windows*"
}

$count = 0
foreach ($file in $pyFiles) {
    $content = Get-Content -Path $file.FullName -Raw
    $originalContent = $content
    
    # Replace agent. imports with src.agent.
    $content = $content -replace 'from agent\.', 'from src.agent.'
    $content = $content -replace 'import agent\.', 'import src.agent.'
    $content = $content -replace '"agent\.', '"src.agent.'
    $content = $content -replace "'agent\.", "'src.agent."
    $content = $content -replace 'python -m agent\.', 'python -m src.agent.'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "  Updated: $($file.Name)" -ForegroundColor Green
        $count++
    }
}

Write-Host ""
Write-Host "✅ Updated $count Python files" -ForegroundColor Green
