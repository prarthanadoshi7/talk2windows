import unittest
import tempfile
import os
import json
from unittest.mock import patch, MagicMock
import sys

sys.path.insert(0, os.path.dirname(__file__))

import pytest
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.agent.core.tool_catalog_manager import ToolCatalogManager

class TestToolCatalogManager(unittest.TestCase):
    def setUp(self):
        self.manager = ToolCatalogManager()

    def test_extract_yaml_header(self):
        content = """
<#
id: test-script
name: Test Script
description: A test script
category: test
risk_level: low
side_effects: none
parameters: []
examples:
- description: Test
  args: {}
#>
param()
"""
        yaml_content = self.manager.extract_yaml_header(content)
        self.assertIsNotNone(yaml_content)
        self.assertIn('id: test-script', yaml_content)

    def test_parse_yaml_metadata_valid(self):
        yaml_content = """
id: test-script
name: Test Script
description: A test script
category: test
risk_level: low
side_effects: none
parameters: []
examples:
- description: Test
  args: {}
"""
        metadata = self.manager.parse_yaml_metadata(yaml_content)
        self.assertIsNotNone(metadata)
        self.assertEqual(metadata['id'], 'test-script')

    def test_parse_yaml_metadata_missing_field(self):
        yaml_content = """
id: test-script
name: Test Script
description: A test script
category: test
# missing risk_level
side_effects: none
parameters: []
examples:
- description: Test
  args: {}
"""
        metadata = self.manager.parse_yaml_metadata(yaml_content)
        self.assertIsNone(metadata)

    def test_transform_to_gemini_schema(self):
        metadata = {
            'id': 'close-program',
            'name': 'Close Program',
            'description': 'Closes a program\'s processes gracefully',
            'category': 'system',
            'risk_level': 'low',
            'side_effects': 'Terminates running processes',
            'parameters': [
                {'name': 'ProgramName', 'type': 'string', 'description': 'The process name', 'required': True},
                {'name': 'FullProgramName', 'type': 'string', 'description': 'The full name', 'required': False}
            ],
            'examples': []
        }
        schema = self.manager.transform_to_gemini_schema(metadata)
        self.assertEqual(schema['name'], 'close-program')
        self.assertIn('ProgramName', schema['parameters']['required'])
        self.assertNotIn('FullProgramName', schema['parameters']['required'])
        self.assertEqual(schema['parameters']['properties']['ProgramName']['type'], 'STRING')

    @patch('builtins.open', new_callable=unittest.mock.mock_open)
    def test_generate_catalog(self, mock_open):
        # Mock file reading
        mock_open.return_value.read.return_value = """
<#
id: test-script
name: Test Script
description: A test script
category: test
risk_level: low
side_effects: none
parameters: []
examples:
- description: Test
  args: {}
#>
"""
        with patch.object(self.manager, 'scan_scripts', return_value=['fake_path.ps1']):
            self.manager.generate_catalog()
            # Check that json.dump was called
            self.assertTrue(mock_open.called)

if __name__ == '__main__':
    unittest.main()