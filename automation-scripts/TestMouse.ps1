# Test script to validate mouse functions
# Save as TestMouse.ps1

Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    
    public class TestMouse {
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

# Test getting mouse position
$pos = [TestMouse]::GetPosition()
Write-Host "Current mouse position: X = $($pos.X), Y = $($pos.Y)" -ForegroundColor Green
Write-Host "Mouse functions loaded successfully!" -ForegroundColor Yellow