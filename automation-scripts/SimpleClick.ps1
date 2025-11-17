# Minimal Chrome Automation Script
# Save as SimpleClick.ps1

Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Threading;
    
    public class Mouse {
        [DllImport("user32.dll")]
        public static extern bool SetCursorPos(int X, int Y);
        
        [DllImport("user32.dll")]
        public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, int dwExtraInfo);
        
        public static void Click(int x, int y) {
            SetCursorPos(x, y);
            Thread.Sleep(100);
            mouse_event(0x0002, x, y, 0, 0); // Left button down
            Thread.Sleep(50);
            mouse_event(0x0004, x, y, 0, 0); // Left button up
        }
    }
"@

# Open Chrome
$url = "https://lmarena.ai/?mode=direct&chat-modality=search"
Start-Process chrome.exe -ArgumentList $url

# Wait for page to load
Start-Sleep -Seconds 5

# Click at specific positions
[Mouse]::Click(500, 400)  # Click 1
Start-Sleep -Seconds 2

[Mouse]::Click(700, 300)  # Click 2
Start-Sleep -Seconds 2

[Mouse]::Click(400, 600)  # Click 3

Write-Host "Clicks completed!" -ForegroundColor Green