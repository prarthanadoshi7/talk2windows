import json
import os
import subprocess
from typing import Dict, Tuple


class PowerShellExecutor:
    """Launches PowerShell scripts through run-script.ps1."""

    def __init__(self, timeout_seconds: int = 60):
        self.timeout_seconds = timeout_seconds
        # run-script.ps1 is in the agent directory
        self.executor_path = os.path.abspath(
            os.path.join(os.path.dirname(__file__), "run-script.ps1")
        )

    def _validate_tool_name(self, tool_name: str) -> None:
        # Prevent path traversal or accidental extension injection
        if any(sep in tool_name for sep in ("/", "\\")) or ".." in tool_name:
            raise ValueError(f"Invalid tool name: {tool_name}")

    def run(self, tool_name: str, args: Dict[str, object]) -> Tuple[int, str, str]:
        """Execute a script by ID and return (exit_code, stdout, stderr)."""
        self._validate_tool_name(tool_name)
        # Change to simple key=value format
        params_str = ','.join(f'{k}={v}' for k, v in args.items())
        command = [
            "powershell.exe",
            "-NoProfile",
            "-File",
            self.executor_path,
            "-ScriptID",
            tool_name,
            "-ParamsStr",
            params_str,
        ]

        try:
            result = subprocess.run(
                command,
                text=True,
                capture_output=True,
                check=False,
                timeout=self.timeout_seconds,
            )
        except subprocess.TimeoutExpired:
            return -1, "", "Executor timed out"

        if not result.stdout:
            return result.returncode, "", result.stderr.strip()

        try:
            output = json.loads(result.stdout)
        except json.JSONDecodeError:
            stderr = result.stderr.strip()
            if stderr:
                return -1, "", f"Executor failed: {stderr}"
            return -1, "", "Executor returned invalid JSON"

        exit_code = output.get("exit_code", -1)
        stdout = output.get("stdout", "")
        stderr = output.get("stderr", "")
        return exit_code, stdout, stderr