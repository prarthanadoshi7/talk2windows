import subprocess
import unittest
from unittest.mock import patch, MagicMock
import sys
import os

# Add the agent directory to the path
sys.path.insert(0, os.path.dirname(__file__))

import pytest
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.agent.powershell_executor import PowerShellExecutor

class TestPowerShellExecutor(unittest.TestCase):
    def setUp(self):
        self.executor = PowerShellExecutor()

    @patch('subprocess.run')
    def test_run_open_calculator(self, mock_subprocess):
        # Mock the subprocess.run return value
        mock_result = MagicMock()
        mock_result.stdout = '{"exit_code": 0, "stdout": "Calculator opened", "stderr": ""}'
        mock_result.stderr = ''
        mock_result.returncode = 0
        mock_subprocess.return_value = mock_result

        # Call the run method
        exit_code, stdout, stderr = self.executor.run("open-calculator", {})

        # Assert the command was built correctly
        expected_command = [
            "powershell.exe",
            "-NoProfile",
            "-File",
            self.executor.executor_path,
            "-ScriptID",
            "open-calculator",
            "-ParamsJson",
            "{}"
        ]
        mock_subprocess.assert_called_once_with(
            expected_command,
            text=True,
            capture_output=True,
            check=False,
            timeout=self.executor.timeout_seconds,
        )

        # Assert the return values
        self.assertEqual(exit_code, 0)
        self.assertEqual(stdout, "Calculator opened")
        self.assertEqual(stderr, "")

    @patch('subprocess.run')
    def test_run_invalid_script(self, mock_subprocess):
        # Mock the subprocess.run return value with invalid JSON
        mock_result = MagicMock()
        mock_result.stdout = 'invalid json'
        mock_result.stderr = 'Some error'
        mock_result.returncode = 1
        mock_subprocess.return_value = mock_result

        # Call the run method
        exit_code, stdout, stderr = self.executor.run("invalid-script", {})

        # Assert error handling
        self.assertEqual(exit_code, -1)
        self.assertEqual(stdout, "")
        self.assertEqual(stderr, "Executor failed: Some error")

    def test_invalid_tool_name_raises(self):
        with self.assertRaises(ValueError):
            self.executor.run("../bad", {})

    @patch('subprocess.run', side_effect=subprocess.TimeoutExpired(cmd='cmd', timeout=60))
    def test_timeout(self, mock_subprocess):
        exit_code, stdout, stderr = self.executor.run("open-calculator", {})
        self.assertEqual(exit_code, -1)
        self.assertEqual(stdout, "")
        self.assertEqual(stderr, "Executor timed out")

if __name__ == '__main__':
    unittest.main()