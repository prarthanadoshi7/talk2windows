import os
import yaml
import json
import logging

class ToolCatalogManager:
    def __init__(self, scripts_dir=None):
        if scripts_dir is None:
            scripts_dir = os.path.join(os.path.dirname(__file__), "../../..", "scripts")
        self.scripts_dir = scripts_dir
        self.logger = logging.getLogger(__name__)

    def scan_scripts(self, directory):
        """List all .ps1 files in the given directory recursively."""
        ps1_files = []
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.endswith('.ps1') and not file.startswith('_'):
                    ps1_files.append(os.path.join(root, file))
        return ps1_files

    def extract_yaml_header(self, content):
        """Extract YAML metadata from <# ... #> block that contains 'id:'."""
        import re
        # Find all <# ... #> blocks
        blocks = re.findall(r'<#(.*?)#>', content, re.DOTALL)
        for block in blocks:
            if 'id:' in block:
                return block.strip()
        return None

    def parse_yaml_metadata(self, yaml_content):
        """Parse YAML content and validate required fields."""
        try:
            metadata = yaml.safe_load(yaml_content)
            required_fields = ['id', 'name', 'description', 'category', 'risk_level', 'side_effects', 'parameters', 'examples']
            for field in required_fields:
                if field not in metadata:
                    self.logger.warning(f"Missing required field: {field}")
                    return None
            return metadata
        except yaml.YAMLError as e:
            self.logger.error(f"YAML parsing error: {e}")
            return None

    def transform_to_gemini_schema(self, metadata):
        """Transform metadata to Gemini function schema with enriched descriptions."""
        # Build enriched description with examples
        description = metadata['description']
        
        # Add example phrases from metadata to help Gemini understand natural language
        examples = metadata.get('examples', [])
        if examples:
            example_phrases = []
            for ex in examples:
                if 'description' in ex:
                    example_phrases.append(ex['description'])
            if example_phrases:
                description += f" | User might say: {', '.join(example_phrases)}"
        
        # Also include the friendly name if different from ID
        name = metadata.get('name', '')
        if name and name.lower() != metadata['id'].replace('-', ' ').lower():
            description = f"{name}. {description}"
        
        # Build the parameters schema
        params = metadata.get('parameters', [])
        if params:
            # If there are parameters, use OBJECT type with properties
            parameters_schema = {
                "type": "OBJECT",
                "properties": {},
                "required": []
            }
            for param in params:
                parameters_schema['properties'][param['name']] = {
                    "type": param['type'].upper(),
                    "description": param['description']
                }
                if param.get('required', False):
                    parameters_schema['required'].append(param['name'])
        else:
            # If no parameters, use empty OBJECT
            parameters_schema = {
                "type": "OBJECT",
                "properties": {}
            }
        
        function = {
            "name": metadata['id'],
            "description": description,
            "parameters": parameters_schema
        }
        return function

    def generate_catalog(self):
        """Generate the tools catalog and write to tools.json."""
        scripts = self.scan_scripts(self.scripts_dir)
        tools = []
        risk_levels = {}
        for script_path in scripts:
            try:
                with open(script_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                yaml_content = self.extract_yaml_header(content)
                if yaml_content:
                    metadata = self.parse_yaml_metadata(yaml_content)
                    if metadata:
                        function_schema = self.transform_to_gemini_schema(metadata)
                        tools.append(function_schema)
                        risk_levels[metadata['id']] = metadata.get('risk_level', 'low')
                    else:
                        self.logger.warning(f"Skipping {script_path}: invalid metadata")
                else:
                    # Skip scripts without proper metadata - don't send to Gemini
                    self.logger.debug(f"No metadata found in {script_path}, skipping")
            except Exception as e:
                self.logger.error(f"Error processing {script_path}: {e}")
        
        catalog = {"tools": tools, "risk_levels": risk_levels}
        output_path = os.path.join(os.path.dirname(__file__), "tools.json")
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(catalog, f, indent=2)
        self.logger.info(f"Catalog generated with {len(tools)} tools")

    def load_catalog(self):
        """Load the tools catalog from tools.json."""
        output_path = os.path.join(os.path.dirname(__file__), "tools.json")
        if os.path.exists(output_path):
            with open(output_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {"tools": []}

    def load_tools(self):
        """Load and return the list of tools."""
        return self.load_catalog()['tools']