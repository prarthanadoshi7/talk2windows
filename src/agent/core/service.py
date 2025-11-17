import asyncio
import hashlib
import json
import logging
import os
from typing import Callable, Optional, List, Dict

import google.generativeai as genai

from ..config.config import get_gemini_api_key, setup_environment
from ..memory.store import MemoryStore
from ..execution.powershell_executor import PowerShellExecutor
from ..core.tool_catalog_manager import ToolCatalogManager
from ..core.semantic_index import SemanticIndex
from ..utils.tts import TTS

# Set up environment variables for consistent operation
setup_environment()

class AgentService:
    def __init__(
        self,
        api_key: Optional[str] = None,
        prompt_provider: Optional[Callable[[str], str]] = None,
    ):
        self.logger = logging.getLogger(__name__)
        self.catalog_manager = ToolCatalogManager()
        self.executor = PowerShellExecutor()
        self.semantic_index = SemanticIndex()  # Smart script discovery
        catalog = self.catalog_manager.load_catalog()
        self.tools = catalog.get('tools', [])
        self.risk_levels = catalog.get('risk_levels', {})
        self.tts = TTS()
        self.memory = MemoryStore()
        self.prompt_provider = prompt_provider or self._default_prompt
        # confirmation policy: 'prompt' (default), 'auto', 'voice'
        self.confirm_policy = os.getenv('TALK2WINDOWS_CONFIRM_POLICY', 'prompt')
        
        # Two-stage intelligence mode: 'auto' (search first) or 'direct' (use all 25 tools)
        self.discovery_mode = os.getenv('TALK2WINDOWS_DISCOVERY_MODE', 'auto')

        planner_path = os.path.join(
            os.path.dirname(__file__), "..", "..", "..", "prompts", "planner.txt"
        )
        with open(planner_path, 'r', encoding='utf-8') as file:
            self.system_instruction = file.read().strip()

        api_key_to_use = api_key or get_gemini_api_key()
        genai.configure(api_key=api_key_to_use)
        
        # Configure tool config to require function calling
        tool_config = {
            'function_calling_config': {
                'mode': 'ANY'  # Force function calling instead of natural language responses
            }
        }
        
        self.model = genai.GenerativeModel(
            model_name='gemini-2.5-flash',  # Using faster 2.5 flash model
            system_instruction=self.system_instruction,
            tools=self.tools,
        )
        self.tool_config = tool_config

    def _default_prompt(self, prompt_text: str) -> str:
        return input(prompt_text)

    async def _prompt_user(self, prompt_text: str) -> str:
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, self.prompt_provider, prompt_text)

    async def execute_plan(self, plan):
        """Execute a sequence of steps from the plan."""
        observations = []
        for step in plan:
            tool = step.get('tool') if isinstance(step, dict) else None
            if not tool:
                observations.append("Skipped step: missing tool identifier")
                continue
            raw_args = step.get('args', {}) if isinstance(step, dict) else {}
            args = raw_args if isinstance(raw_args, dict) else {}
            level = self.risk_levels.get(tool, 'low')
            if not await self.confirm(f"Execute {tool}", level):
                observation = f"Skipped {tool}: not confirmed"
                observations.append(observation)
                self.logger.info(observation)
                continue
            try:
                exit_code, stdout, stderr = await asyncio.get_event_loop().run_in_executor(
                    None, self.executor.run, tool, args
                )
                observation = self._format_execution_observation(
                    tool, exit_code, stdout, stderr
                )
                observations.append(observation)
                self.logger.info(observation)
                # Log to memory
                self.memory.recent_actions.append(
                    {'tool': tool, 'args': args, 'result': observation}
                )
                self.memory.save('recent_actions', self.memory.recent_actions)
            except Exception as e:
                observation = f"Failed {tool}: {e}"
                observations.append(observation)
                self.logger.error(observation)
        # Summarize
        summary = "Completed plan: " + "; ".join(observations)
        await asyncio.get_event_loop().run_in_executor(None, self.tts.say, summary)
        return summary

    def _format_execution_observation(
        self, tool: str, exit_code: int, stdout: str, stderr: str
    ) -> str:
        # Ensure stdout and stderr are strings
        stdout_str = str(stdout) if stdout else ""
        stderr_str = str(stderr) if stderr else ""
        
        if exit_code == 0:
            detail = stdout_str.strip() or "succeeded"
            return f"Executed {tool}: {detail}"
        error_detail = stderr_str.strip() or f"exit code {exit_code}"
        return f"Failed {tool}: {error_detail}"

    async def confirm(self, text: str, level: str):
        """Confirm action based on risk level."""
        if level == 'low':
            return True
        elif level == 'medium':
            # Ask "Proceed?"
            await asyncio.get_event_loop().run_in_executor(
                None, self.tts.say, f"{text}. Proceed?"
            )
            if self.confirm_policy == 'auto':
                return True
            if self.confirm_policy == 'voice':
                # In voice mode, we still use the prompt provider (can be a voice recog handler)
                response = (await self._prompt_user("Proceed? (yes/no): ")).lower().strip()
                return response == 'yes'
            response = (await self._prompt_user("Proceed? (yes/no): ")).lower().strip()
            return response == 'yes'
        elif level == 'high':
            # Ask for passphrase
            await asyncio.get_event_loop().run_in_executor(
                None, self.tts.say, f"{text}. Confirm with passphrase."
            )
            passphrase = await self._prompt_user("Enter passphrase (or 'setup' to create one): ")
            # If first-run 'setup', ask to set passphrase
            if passphrase.strip().lower() == 'setup':
                # Ask the user to provide a new passphrase twice
                first = await self._prompt_user('Enter new passphrase: ')
                second = await self._prompt_user('Confirm new passphrase: ')
                if first != second:
                    await asyncio.get_event_loop().run_in_executor(None, self.tts.say, 'Passphrases do not match')
                    return False
                # Save hashed passphrase
                self.memory.set_passphrase(first)
                await asyncio.get_event_loop().run_in_executor(None, self.tts.say, 'Passphrase stored')
                passphrase = first
            hashed = hashlib.sha256(passphrase.encode()).hexdigest()
            stored = self.memory.get_passphrase_hash()
            return hashed == stored
        return False

    async def handle_transcript(self, transcript: str):
        """Process a voice transcript and execute the appropriate tool or plan."""
        try:
            # Two-stage intelligence: First search semantic index, then ask Gemini
            relevant_tools = None
            if self.discovery_mode == 'auto':
                self.logger.info(f"Searching semantic index for: {transcript}")
                matches = self.semantic_index.search(transcript, max_results=5)  # Reduced from 10 to 5
                if matches:
                    self.logger.info(f"Found {len(matches)} relevant scripts: {[m['id'] for m in matches]}")
                    # Build focused tool list from matches
                    relevant_tools = self._build_focused_tool_list(matches)
            
            # Generate response with focused or full tool list
            if relevant_tools:
                # Create temporary model with focused tools
                focused_model = genai.GenerativeModel(
                    model_name='gemini-2.5-flash',  # Using faster 2.0 flash model
                    system_instruction=self.system_instruction,
                    tools=relevant_tools,
                )
                response = await asyncio.get_event_loop().run_in_executor(
                    None, 
                    lambda: focused_model.generate_content(transcript, tool_config=self.tool_config)
                )
            else:
                # Use full tool list (direct mode or no matches)
                response = await asyncio.get_event_loop().run_in_executor(
                    None, 
                    lambda: self.model.generate_content(transcript, tool_config=self.tool_config)
                )
            
            # Check for function calls FIRST (before accessing .text which may fail)
            if response.candidates and response.candidates[0].content.parts:
                for part in response.candidates[0].content.parts:
                    if hasattr(part, 'function_call') and part.function_call:
                        func_call = part.function_call
                        name = func_call.name
                        args = dict(func_call.args) if func_call.args else {}
                        level = self.risk_levels.get(name, 'low')
                        if not await self.confirm(f"Execute {name}", level):
                            result = f"Skipped {name}: not confirmed"
                            self.logger.info(result)
                            await asyncio.get_event_loop().run_in_executor(None, self.tts.say, result)
                            return result
                        # Execute the tool
                        exit_code, stdout, stderr = await asyncio.get_event_loop().run_in_executor(
                            None, self.executor.run, name, args
                        )
                        observation = self._format_execution_observation(
                            name, exit_code, stdout, stderr
                        )
                        self.logger.info(observation)
                        # Speak the result - ensure it's a string
                        result_text = str(stdout or stderr or exit_code)
                        await asyncio.get_event_loop().run_in_executor(
                            None, self.tts.say, result_text
                        )
                        # Log to memory
                        self.memory.recent_actions.append(
                            {'tool': name, 'args': args, 'result': observation}
                        )
                        self.memory.save('recent_actions', self.memory.recent_actions)
                        return observation
            
            # Check for plan in text (only if no function call was made)
            try:
                if response.text:
                    stripped = response.text.strip()
                    # Check for JSON plan
                    if stripped.startswith('{'):
                        try:
                            data = json.loads(stripped)
                            if 'plan' in data and isinstance(data['plan'], list):
                                self.logger.info(f"Executing plan: {data['plan']}")
                                return await self.execute_plan(data['plan'])
                        except json.JSONDecodeError:
                            self.logger.debug("Response text not valid JSON plan")
                    # Otherwise just speak the text response
                    self.logger.info(f"Gemini response: {response.text}")
                    await asyncio.get_event_loop().run_in_executor(None, self.tts.say, response.text)
                    return response.text
            except ValueError:
                # Response may not have .text when function calling is used
                pass
                
            self.logger.warning("No function call, plan, or text response from Gemini")
            return None
        except Exception as e:
            self.logger.error(f"Error handling transcript: {e}", exc_info=True)
            return None

    def _build_focused_tool_list(self, matches: List[Dict]) -> List[Dict]:
        """Build a focused tool list from semantic index matches."""
        focused_tools = []
        for match in matches:
            # Find the tool definition from our full catalog
            tool = next((t for t in self.tools if t['name'] == match['id']), None)
            if tool:
                focused_tools.append(tool)
            else:
                # Generate tool definition on-the-fly for undocumented scripts
                focused_tools.append({
                    'name': match['id'],
                    'description': f"{match['description']} | User might say: {', '.join(match['keywords'][:3])}",
                    'parameters': {
                        'type': 'OBJECT',
                        'properties': {},
                        'required': []
                    }
                })
        return focused_tools
    
    async def run(self):
        """Main asyncio loop."""
        self.logger.info("Agent Service starting...")
        self.logger.info(f"Discovery mode: {self.discovery_mode}")
        self.logger.info(f"Semantic index: {len(self.semantic_index.index['scripts'])} scripts indexed")
        # Placeholder for voice input loop
        while True:
            transcript = input("Enter transcript (or 'quit' to exit): ")
            if transcript.lower() == 'quit':
                break
            await self.handle_transcript(transcript)
        self.logger.info("Agent service stopped.")

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    service = AgentService()
    asyncio.run(service.run())