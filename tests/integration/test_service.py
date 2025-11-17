import asyncio
import unittest
import sys
import os
from unittest.mock import MagicMock, patch

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))


class AgentServiceTests(unittest.TestCase):
    @patch('src.agent.utils.tts.TTS')
    @patch('src.agent.execution.powershell_executor.PowerShellExecutor')
    @patch('src.agent.core.tool_catalog_manager.ToolCatalogManager')
    @patch('src.agent.core.service.genai.GenerativeModel')
    def test_execute_plan_uses_tool_id(
        self,
        mock_model,
        mock_catalog_manager,
        mock_executor,
        mock_tts,
    ):
        mock_catalog_manager.return_value.load_catalog.return_value = {
            'tools': [],
            'risk_levels': {'open-calculator': 'low'},
        }
        mock_executor_instance = mock_executor.return_value
        mock_executor_instance.run.return_value = (0, 'ok', '')

        from src.agent.core.service import AgentService

        service = AgentService(api_key='test', prompt_provider=lambda _: 'yes')

        plan = [{'tool': 'open-calculator', 'args': {}}]
        asyncio.run(service.execute_plan(plan))

        mock_executor_instance.run.assert_called_with('open-calculator', {})

    @patch('src.agent.utils.tts.TTS')
    @patch('src.agent.execution.powershell_executor.PowerShellExecutor')
    @patch('src.agent.core.tool_catalog_manager.ToolCatalogManager')
    @patch('src.agent.core.service.genai.GenerativeModel')
    def test_confirm_medium_uses_prompt_provider(
        self,
        mock_model,
        mock_catalog_manager,
        mock_executor,
        mock_tts,
    ):
        mock_catalog_manager.return_value.load_catalog.return_value = {
            'tools': [],
            'risk_levels': {'open-calculator': 'medium'},
        }

        responses = iter(['yes'])

        def prompt(_):
            return next(responses)

        from src.agent.core.service import AgentService

        service = AgentService(api_key='test', prompt_provider=prompt)

        is_confirmed = asyncio.run(service.confirm('Execute open-calculator', 'medium'))
        self.assertTrue(is_confirmed)
    
    def test_confirm_medium_auto(self):
        from src.agent.core.service import AgentService
        service = AgentService(api_key='test', prompt_provider=lambda _: 'no')
        service.confirm_policy = 'auto'
        is_confirmed = asyncio.run(service.confirm('Execute open-calculator', 'medium'))
        self.assertTrue(is_confirmed)


if __name__ == '__main__':
    unittest.main()
