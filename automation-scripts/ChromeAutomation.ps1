# Simple Browser Automation with Windows Mouse Clicks
# Save as ChromeAutomation.ps1

# Load Windows mouse control functions
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Threading;
    
    public class MouseControl {
        [DllImport("user32.dll")]
        public static extern bool SetCursorPos(int X, int Y);
        
        [DllImport("user32.dll")]
        public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, int dwExtraInfo);
        
        [DllImport("user32.dll")]
        public static extern bool GetCursorPos(out POINT lpPoint);
        
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        
        public struct POINT {
            public int X;
            public int Y;
        }
        
        // Mouse event constants
        public const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        public const uint MOUSEEVENTF_LEFTUP = 0x0004;
        public const uint MOUSEEVENTF_RIGHTDOWN = 0x0008;
        public const uint MOUSEEVENTF_RIGHTUP = 0x0010;
        public const uint MOUSEEVENTF_MIDDLEDOWN = 0x0020;
        public const uint MOUSEEVENTF_MIDDLEUP = 0x0040;
        public const uint MOUSEEVENTF_WHEEL = 0x0800;
        
        // Click at specific position
        public static void ClickAt(int x, int y) {
            SetCursorPos(x, y);
            Thread.Sleep(100);
            mouse_event(MOUSEEVENTF_LEFTDOWN, x, y, 0, 0);
            Thread.Sleep(50);
            mouse_event(MOUSEEVENTF_LEFTUP, x, y, 0, 0);
        }
        
        // Double click at position
        public static void DoubleClickAt(int x, int y) {
            SetCursorPos(x, y);
            Thread.Sleep(100);
            mouse_event(MOUSEEVENTF_LEFTDOWN, x, y, 0, 0);
            mouse_event(MOUSEEVENTF_LEFTUP, x, y, 0, 0);
            Thread.Sleep(50);
            mouse_event(MOUSEEVENTF_LEFTDOWN, x, y, 0, 0);
            mouse_event(MOUSEEVENTF_LEFTUP, x, y, 0, 0);
        }
        
        // Right click at position
        public static void RightClickAt(int x, int y) {
            SetCursorPos(x, y);
            Thread.Sleep(100);
            mouse_event(MOUSEEVENTF_RIGHTDOWN, x, y, 0, 0);
            Thread.Sleep(50);
            mouse_event(MOUSEEVENTF_RIGHTUP, x, y, 0, 0);
        }
        
        // Get current mouse position
        public static POINT GetMousePosition() {
            POINT point;
            GetCursorPos(out point);
            return point;
        }
        
        // Scroll wheel
        public static void ScrollWheel(int scrollAmount) {
            mouse_event(MOUSEEVENTF_WHEEL, 0, 0, (uint)scrollAmount, 0);
        }
    }
"@

# Load keyboard functions for shortcuts
Add-Type -AssemblyName System.Windows.Forms

# =====================================
# MAIN AUTOMATION SCRIPT
# =====================================

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "    CHROME AUTOMATION WITH WINDOWS MOUSE CLICKS" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Cyan

# Configuration - MODIFY THESE VALUES FOR YOUR NEEDS
$websiteURL = "https://lmarena.ai/?mode=direct&chat-modality=search"
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# Alternative Chrome paths
if (-not (Test-Path $chromePath)) {
    $chromePath = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
}

# Define click positions (X, Y coordinates)
# You can modify these coordinates based on your screen resolution
$clickPositions = @(
    @{X = 500; Y = 400; Description = "Center area"; Wait = 2},
    @{X = 300; Y = 200; Description = "Top left area"; Wait = 1},
    @{X = 800; Y = 500; Description = "Right side"; Wait = 1},
    @{X = 150; Y = 350; Description = "Left menu"; Wait = 2}
)

# Step 1: Open Chrome with the website
Write-Host "`n[1] Opening Chrome browser..." -ForegroundColor Green
$chromeProcess = Start-Process -FilePath $chromePath -ArgumentList $websiteURL, "--new-window", "--start-maximized" -PassThru

# Wait for Chrome to load
Write-Host "[2] Waiting for page to load..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Make sure Chrome window is active
$chromeHandle = $chromeProcess.MainWindowHandle
if ($chromeHandle -ne [System.IntPtr]::Zero) {
    [MouseControl]::SetForegroundWindow($chromeHandle)
    [MouseControl]::ShowWindow($chromeHandle, 3) # Maximize window
}

# Step 2: Perform mouse clicks at specified positions
Write-Host "`n[3] Starting automated clicks..." -ForegroundColor Green

foreach ($position in $clickPositions) {
    Write-Host "`n  → Clicking at: $($position.Description) (X:$($position.X), Y:$($position.Y))" -ForegroundColor Cyan
    
    # Move mouse to position and click
    [MouseControl]::ClickAt($position.X, $position.Y)
    
    Write-Host "    ✓ Clicked!" -ForegroundColor Green
    
    # Wait before next click
    Start-Sleep -Seconds $position.Wait
}

# Step 3: Open Developer Tools (Ctrl+Shift+I)
Write-Host "`n[4] Opening Developer Tools..." -ForegroundColor Yellow
[System.Windows.Forms.SendKeys]::SendWait("^+{i}")
Start-Sleep -Seconds 3

# Step 4: Additional automated actions
Write-Host "`n[5] Performing additional actions..." -ForegroundColor Yellow

# Example: Scroll down
Write-Host "  → Scrolling down..." -ForegroundColor Cyan
[MouseControl]::ScrollWheel(-500)
Start-Sleep -Seconds 1

# Example: Right-click to open context menu
Write-Host "  → Right-clicking at position (600, 400)..." -ForegroundColor Cyan
[MouseControl]::RightClickAt(600, 400)
Start-Sleep -Seconds 1

# Press Escape to close context menu
[System.Windows.Forms.SendKeys]::SendWait("{ESC}")

# Step 5: Extract page content
Write-Host "`n[6] Extracting page elements..." -ForegroundColor Yellow

# Select all content (Ctrl+A)
[System.Windows.Forms.SendKeys]::SendWait("^a")
Start-Sleep -Milliseconds 500

# Copy to clipboard (Ctrl+C)
[System.Windows.Forms.SendKeys]::SendWait("^c")
Start-Sleep -Milliseconds 500

# Get clipboard content and save to file
$content = Get-Clipboard -Raw
$outputFile = "$env:USERPROFILE\Desktop\webpage_content_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Save content with metadata
@"
=====================================
EXTRACTED WEBPAGE CONTENT
=====================================
URL: $websiteURL
Date: $(Get-Date)
=====================================

$content
"@ | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "`n[7] Content saved to: $outputFile" -ForegroundColor Green

# Display summary
Write-Host "`n" + "=" * 60 -ForegroundColor Cyan
Write-Host "AUTOMATION COMPLETE!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "✓ Chrome opened successfully" -ForegroundColor Green
Write-Host "✓ Navigated to: $websiteURL" -ForegroundColor Green
Write-Host "✓ Performed $($clickPositions.Count) clicks" -ForegroundColor Green
Write-Host "✓ Extracted content saved to desktop" -ForegroundColor Green

# Optional: Keep Chrome open or close it
$closeChoice = Read-Host "`nDo you want to close Chrome? (Y/N)"
if ($closeChoice -eq 'Y') {
    Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
    Write-Host "Chrome closed." -ForegroundColor Yellow
}