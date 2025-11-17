import subprocess
import os

class TTS:
    def say(self, text: str):
        """Speak the given text using PowerShell TTS script."""
        # Check if TTS is disabled (for Serenade integration)
        if os.getenv('TALK2WINDOWS_DISABLE_TTS') == '1':
            print(f"[TTS DISABLED] Would say: {text}")
            return
            
        script_path = os.path.join(os.path.dirname(__file__), "..", "..", "scripts", "say.ps1")
        # Escape double quotes for PowerShell
        escaped_text = text.replace('"', '`"')
        command = f'powershell.exe -File "{script_path}" -Text "{escaped_text}"'
        subprocess.run(command, shell=True)