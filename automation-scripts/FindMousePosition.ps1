# Mouse Position Finder - Run this to find coordinates for clicking
# Save as FindMousePosition.ps1

Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    
    public class MousePos {
        [DllImport("user32.dll")]
        public static extern bool GetCursorPos(out POINT lpPoint);
        
        public struct POINT {
            public int X;
            public int Y;
        }
        
        public static POINT GetPosition() {
            POINT point;
            GetCursorPos(out point);
            return point;
        }
    }
"@

Write-Host "MOUSE POSITION FINDER" -ForegroundColor Yellow
Write-Host "Move your mouse to desired position and press Enter to record" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to exit`n" -ForegroundColor Gray

$positions = @()
$counter = 1

while ($true) {
    Write-Host "Position $counter - Move mouse and press Enter: " -NoNewline -ForegroundColor Green
    $null = Read-Host
    
    $pos = [MousePos]::GetPosition()
    $positions += @{Number = $counter; X = $pos.X; Y = $pos.Y}
    
    Write-Host "  Recorded: X = $($pos.X), Y = $($pos.Y)" -ForegroundColor Yellow
    $counter++
}