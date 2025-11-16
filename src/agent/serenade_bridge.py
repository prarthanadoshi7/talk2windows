"""
Serenade Bridge - Routes Serenade voice commands to Gemini AI agent.

This script acts as a bridge between Serenade voice commands and the Gemini agent.
Instead of directly executing PowerShell scripts, voice commands are processed through
Gemini's natural language understanding for smarter execution.

Usage:
    python -m src.agent.serenade_bridge "user voice command"
"""
import asyncio
import logging
import sys
from src.agent.service import AgentService

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

async def process_voice_command(command: str):
    """Process a voice command through the Gemini agent."""
    service = AgentService(prompt_provider=lambda _: 'yes')
    
    # Set to auto-confirm for voice mode (no keyboard input needed)
    import os
    os.environ['TALK2WINDOWS_CONFIRM_POLICY'] = 'auto'
    os.environ['TALK2WINDOWS_DISCOVERY_MODE'] = 'auto'
    
    result = await service.handle_transcript(command)
    return result

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python -m src.agent.serenade_bridge 'voice command here'")
        sys.exit(1)
    
    command = ' '.join(sys.argv[1:])
    asyncio.run(process_voice_command(command))
