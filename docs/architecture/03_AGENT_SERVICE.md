# 03: Agent Service

The Agent Service is the central nervous system of the autonomous Talk2Windows agent. It is a persistent Python application responsible for listening to user input, orchestrating the agentic loop, and managing data.

## 1. Core Responsibilities

- **Listen for User Input:** Connect to the Serenade WebSocket server to receive transcripts of user voice commands.
- **Manage Tool Catalog:** On startup, generate the `tools.json` file from script metadata for Gemini.
- **Orchestrate Agent Loop:**
    1.  Receive a transcript from Serenade.
    2.  Enrich the transcript with context from the Memory Store.
    3.  Send the request to the **Gemini Planner**.
    4.  Receive a plan (a single or multi-step tool execution).
    5.  For each step, invoke the **PowerShell Executor**.
    6.  Receive the result (stdout, stderr, exit code).
    7.  Send the result to the **Gemini Observer/Reflector** for summarization or error analysis.
    8.  Relay the final summary or next steps to the user via the TTS Engine.
- **Maintain State:** Manage the short-term conversational memory and long-term user preferences.
- **Enforce Safety:** Intercept high-risk actions from the planner and trigger the user confirmation flow before execution.

## 2. Technology Stack

- **Language:** Python 3.10+
- **Core Library:** `google-generativeai` (the official Google GenAI SDK for Python).
- **WebSockets:** `websockets` library to connect to Serenade.
- **YAML Parsing:** `PyYAML` to parse the metadata from script headers.
- **Process Management:** `subprocess` module to call the PowerShell Executor.

A lightweight web framework like **FastAPI** could be used to expose a status endpoint or a web UI for configuration in the future, but is not required for the initial implementation. A simple `asyncio`-based main loop will suffice.

## 3. Serenade Integration

- **Connection:** The service will connect to `ws://localhost:17373` on startup.
- **Protocol:** It will follow the Serenade protocol:
    1.  Send an `active` message to register itself as a client.
    2.  Periodically send `heartbeat` messages to keep the connection alive.
    3.  Listen for `callback` messages containing the command transcripts.
- **Command Routing:** A single, generic custom command will be created in Serenade (e.g., `command {words...}`). This will capture any phrase starting with the wake word and send the entire content of `{words...}` to the Agent Service. This replaces the need for hundreds of specific command definitions in Serenade.

## 4. Main Application Flow (Simplified)

```python
import asyncio
import websockets
import google.generativeai as genai
from tool_catalog_manager import ToolCatalogManager
from powershell_executor import PowerShellExecutor

class AgentService:
    def __init__(self):
        self.serenade_uri = "ws://localhost:17373"
        self.gemini_model = genai.GenerativeModel(
            model_name='gemini-2.5-flash',
            tools=ToolCatalogManager.load_tools()
        )
        self.executor = PowerShellExecutor()
        # ... other initializations

    async def listen_to_serenade(self):
        async with websockets.connect(self.serenade_uri) as websocket:
            # Send 'active' and start heartbeat task
            await self.register_with_serenade(websocket)

            async for message in websocket:
                transcript = self.parse_transcript(message)
                if transcript:
                    asyncio.create_task(self.handle_command(transcript))

    async def handle_command(self, transcript):
        # 1. Send to Gemini Planner
        response = await self.gemini_model.generate_content_async(transcript)
        
        # 2. Check for function calls in the response
        if response.candidates[0].content.parts[0].function_call:
            function_call = response.candidates[0].content.parts[0].function_call
            tool_name = function_call.name
            args = function_call.args

            # 3. (Safety Check would go here)

            # 4. Execute the tool
            exit_code, stdout, stderr = self.executor.run(tool_name, args)

            # 5. Send result to Gemini Reflector/Summarizer
            # ... and speak the result
        else:
            # Handle cases where no tool was called (e.g., chit-chat)
            # ...
            
# Main entry point
async def main():
    service = AgentService()
    await service.listen_to_serenade()

if __name__ == "__main__":
    asyncio.run(main())
```

This service acts as the central hub, connecting all other components into a cohesive, functioning agent.
