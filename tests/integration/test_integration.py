import asyncio
import json
import unittest
import sys
import os
from unittest.mock import MagicMock, patch

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.agent.service import AgentService


class TestIntegrationAgent(unittest.TestCase):
    @patch('src.agent.service.genai.GenerativeModel')
    @patch('src.agent.service.TTS')
    @patch('src.agent.service.PowerShellExecutor')
    @patch('src.agent.service.ToolCatalogManager')
    def test_end_to_end_single_tool_call(
        self, mock_catalog_manager, mock_executor, mock_tts, mock_model
    ):
        # Setup catalog
        mock_catalog_manager.return_value.load_catalog.return_value = {
            'tools': [],
            'risk_levels': {'open-calculator': 'low'}
        }

        # Mock model to return a function call structure
        candidate = MagicMock()
        part = MagicMock()
        part.function_call = MagicMock(name='open-calculator')
        part.function_call.name = 'open-calculator'
        part.function_call.args = None
        candidate.content.parts = [part]
        mock_model().generate_content.return_value = MagicMock(
            candidates=[candidate], text=''
        )

        mock_executor.return_value.run.return_value = (0, 'Calculator opened', '')
        service = AgentService(api_key='test', prompt_provider=lambda _: 'yes')

        res = asyncio.run(service.handle_transcript('Open calculator'))
        self.assertIn('Executed open-calculator', res)


if __name__ == '__main__':
    unittest.main()
