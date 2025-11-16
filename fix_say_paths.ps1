# Fix all references to say.ps1 in scripts
# After reorganization, scripts are in subdirectories, so relative paths need updating

$scriptRoot = $PSScriptRoot
$scriptsDir = Join-Path $scriptRoot "scripts"

Write-Host "Fixing say.ps1 references in all scripts..." -ForegroundColor Cyan

# Get all .ps1 files in subdirectories (not root level)
$scriptFiles = Get-ChildItem -Path $scriptsDir -Recurse -Filter "*.ps1" | Where-Object {
    $_.FullName -notmatch "\\scripts\\[^\\]+\.ps1$"  # Exclude root-level scripts
}

$fixedCount = 0
$totalCount = 0

foreach ($file in $scriptFiles) {
    $content = Get-Content $file.FullName -Raw
    $modified = $false
    
    # Check if file contains say.ps1 references
    if ($content -match '\$PSScriptRoot/say\.ps1') {
        $totalCount++
        
        # Calculate relative depth (how many levels deep)
        $relativePath = $file.FullName.Substring($scriptsDir.Length + 1)
        $depth = ($relativePath.Split('\') | Measure-Object).Count - 1
        
        # Build the correct relative path
        $correctPath = ("../" * $depth) + "say.ps1"
        
        # Replace all instances
        $newContent = $content -replace '\$PSScriptRoot/say\.ps1', "`$PSScriptRoot/$correctPath"
        
        if ($newContent -ne $content) {
            Set-Content $file.FullName -Value $newContent -NoNewline
            $fixedCount++
            Write-Host "✅ Fixed: $($file.FullName.Substring($scriptRoot.Length + 1))" -ForegroundColor Green
        }
    }
}

Write-Host "`n" -NoNewline
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total scripts with say.ps1 references: $totalCount"
Write-Host "  Fixed: $fixedCount" -ForegroundColor Green
Write-Host "  Done!" -ForegroundColor Yellow
