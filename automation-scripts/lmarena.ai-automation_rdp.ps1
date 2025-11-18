# lmarena.ai-automation.ps1
# Automated cookie clearing for lmarena.ai

Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Threading;
    
    public class Mouse {
        [DllImport("user32.dll")]
        public static extern bool SetCursorPos(int X, int Y);
        
        [DllImport("user32.dll")]
        public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, int dwExtraInfo);
        
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        public static void Click(int x, int y) {
            SetCursorPos(x, y);
            Thread.Sleep(200);
            mouse_event(0x0002, x, y, 0, 0); // Left button down
            Thread.Sleep(100);
            mouse_event(0x0004, x, y, 0, 0); // Left button up
        }
    }
"@

Write-Host "================================" -ForegroundColor Cyan
Write-Host "  lmarena.ai Cookie Automation  " -ForegroundColor Yellow
Write-Host "================================" -ForegroundColor Cyan

# Close all Chrome instances before starting
Write-Host "`n[0] Closing all Chrome instances..." -ForegroundColor Yellow
$chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
if ($chromeProcesses) {
    $chromeProcesses | Stop-Process -Force
    Write-Host "  -> Closed $($chromeProcesses.Count) Chrome instance(s)" -ForegroundColor Green
    Start-Sleep -Seconds 2
} else {
    Write-Host "  -> No Chrome instances found" -ForegroundColor Gray
}

# Open Chrome with the website
$url = "https://lmarena.ai/?mode=direct&chat-modality=search"

# Find Chrome executable path
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chromePath)) {
    $chromePath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
}
if (-not (Test-Path $chromePath)) {
    Write-Host "Google Chrome not found. Please install Google Chrome." -ForegroundColor Red
    exit
}

Write-Host "`n[1] Opening Chrome..." -ForegroundColor Green
$chrome = Start-Process -FilePath $chromePath -ArgumentList $url, "--new-window" -PassThru

Start-Sleep -Seconds 5

# Step x: Checking verification a
Write-Host "`n[x] Checking verification a..." -ForegroundColor Yellow
[Mouse]::Click(338, 370)
Start-Sleep -Seconds 5

# Step y: Checking verification b
Write-Host "`n[y] Checking verification b..." -ForegroundColor Yellow
[Mouse]::Click(646, 592)
Start-Sleep -Seconds 5

# Wait for page to load
Write-Host "[2] Waiting for page to load..." -ForegroundColor Yellow
Start-Sleep -Seconds 6

# Make Chrome active window
if ($chrome.MainWindowHandle -ne [System.IntPtr]::Zero) {
    [Mouse]::SetForegroundWindow($chrome.MainWindowHandle)
}

Start-Sleep -Seconds 10

# Click sequence to clear cookies
Write-Host "`n[3] Starting cookie clear process..." -ForegroundColor Green

# Click 1: Starting clear cookies position
Write-Host "  -> Clicking settings menu (168, 64)..." -ForegroundColor Cyan
[Mouse]::Click(136, 60)
Start-Sleep -Seconds 5

# Click 2: Site settings click
Write-Host "  -> Clicking site settings (220, 329)..." -ForegroundColor Cyan
[Mouse]::Click(185, 236)
Start-Sleep -Seconds 5

# Click 3: Delete cookies button
Write-Host "  -> Clicking delete cookies (1026, 274)..." -ForegroundColor Cyan
[Mouse]::Click(1028, 268)
Start-Sleep -Seconds 5

# Click 4: Confirm deletion
Write-Host "  -> Confirming deletion (969, 594)..." -ForegroundColor Cyan
[Mouse]::Click(976, 602)
Start-Sleep -Seconds 5

Write-Host "`n================================" -ForegroundColor Green
Write-Host "  Cookies Cleared Successfully!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Navigate to URL again in the same window
Write-Host "`n[4] Navigating to URL again..." -ForegroundColor Yellow
Add-Type -AssemblyName System.Windows.Forms

# Focus on address bar (Ctrl+L)
[System.Windows.Forms.SendKeys]::SendWait("^l")
Start-Sleep -Seconds 5

# Clear address bar and type new URL
[System.Windows.Forms.SendKeys]::SendWait("^a")
Start-Sleep -Milliseconds 500
[System.Windows.Forms.SendKeys]::SendWait($url)
Start-Sleep -Milliseconds 500
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

# Wait for page to load
Start-Sleep -Seconds 5

# Refresh the page
Write-Host "`n[5] Refreshing page..." -ForegroundColor Yellow
[System.Windows.Forms.SendKeys]::SendWait("{F5}")

# Wait for page to reload
Start-Sleep -Seconds 5

# Step x: Checking verification a
Write-Host "`n[x] Checking verification a..." -ForegroundColor Yellow
[Mouse]::Click(338, 370)
Start-Sleep -Seconds 5

# Step y: Checking verification b
Write-Host "`n[y] Checking verification b..." -ForegroundColor Yellow
[Mouse]::Click(646, 592)
Start-Sleep -Seconds 5

# Step 6: Click on input field and type "hi"
Write-Host "`n[6] Clicking input field and typing 'hi'..." -ForegroundColor Yellow
[Mouse]::Click(481, 608)
Start-Sleep -Seconds 5
[System.Windows.Forms.SendKeys]::SendWait("hi")
Start-Sleep -Seconds 5


# Step y: Checking verification b
Write-Host "`n[y] Checking verification b..." -ForegroundColor Yellow
[Mouse]::Click(646, 592)
Start-Sleep -Seconds 5

# Step 7: Click send button
Write-Host "`n[7] Clicking send button..." -ForegroundColor Yellow
[Mouse]::Click(1166, 655)
Start-Sleep -Seconds 5

# Step y: Checking verification b
Write-Host "`n[y] Checking verification b..." -ForegroundColor Yellow
[Mouse]::Click(646, 592)
Start-Sleep -Seconds 5

# Step 8: Click agreement
Write-Host "`n[8] Clicking agreement..." -ForegroundColor Yellow
[Mouse]::Click(1009, 664)
Start-Sleep -Seconds 5

# Step 9: Click agreement
Write-Host "`n[9] Clicking cookies extension..." -ForegroundColor Yellow
[Mouse]::Click(1332, 61)
Start-Sleep -Seconds 5

# Step 10: Click agreement
Write-Host "`n[10] Copying cookies to clipboard..." -ForegroundColor Yellow
[Mouse]::Click(1268, 155)
Start-Sleep -Seconds 5

# Step 11: Save clipboard content to file
Write-Host "`n[11] Saving clipboard content to file..." -ForegroundColor Yellow

# Get clipboard content
$clipboardContent = Get-Clipboard -Raw

if ($clipboardContent) {
    # Define file path
    $filePath = "D:\Projects\project-exploration\interactive_pc\talk2windows\automation-scripts\lmarena_cookies.txt"
    
    # Create directory if it doesn't exist
    $directory = Split-Path -Path $filePath -Parent
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        Write-Host "  -> Created directory: $directory" -ForegroundColor Gray
    }
    
    # Add timestamp to the content for tracking
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $contentToAppend = "`n`n=== Cookie captured on $timestamp ===`n$clipboardContent"
    
    # Append to file (creates file if it doesn't exist)
    Add-Content -Path $filePath -Value $contentToAppend -Encoding UTF8
    
    Write-Host "  -> Clipboard content saved to: $filePath" -ForegroundColor Green
    Write-Host "  -> Content length: $($clipboardContent.Length) characters" -ForegroundColor Gray
} else {
    Write-Host "  -> Warning: Clipboard is empty!" -ForegroundColor Red
}

# Step 12: Close all Chrome instances
Write-Host "`n[12] Closing all Chrome instances..." -ForegroundColor Yellow
Start-Sleep -Seconds 2  # Give a moment before closing
$chromeProcesses = Get-Process chrome -ErrorAction SilentlyContinue
if ($chromeProcesses) {
    $chromeProcesses | Stop-Process -Force
    Write-Host "  -> Closed $($chromeProcesses.Count) Chrome instance(s)" -ForegroundColor Green
} else {
    Write-Host "  -> No Chrome instances to close" -ForegroundColor Gray
}

# Step 12: Close all Chrome instances
Write-Host "`n[13] Pushing changes to git..." -ForegroundColor Yellow
# Path to repo
$RepoPath = "C:\Users\RDP\Source\Repos\talk2windows"
# Go to repo
Set-Location $RepoPath
# Add everything
git add .
# Commit with timestamp message
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git commit -m "Auto update at $timestamp"

# Push to origin main
git push origin main

Write-Host "`n================================" -ForegroundColor Green
Write-Host "  Automation Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green