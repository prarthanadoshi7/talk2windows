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
from ..core.service import AgentService
from ..config.config import setup_environment

# Set up environment variables for consistent operation
setup_environment()

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

async def process_voice_command(command: str):
    """Process a voice command through the Gemini agent."""
    service = AgentService(prompt_provider=lambda _: 'yes')
    
    result = await service.handle_transcript(command)
    return result

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python -m src.agent.serenade_bridge 'voice command here'")
        sys.exit(1)
    
    command = ' '.join(sys.argv[1:])
    logging.info(f"Serenade Bridge - Received command: '{command}'")
    logging.info(f"Command arguments: {sys.argv}")
    
    try:
        result = asyncio.run(process_voice_command(command))
        if result is None:
            logging.error("Command processing failed - no result returned")
            sys.exit(1)
        else:
            logging.info(f"Command completed successfully: {result}")
            sys.exit(0)
    except Exception as e:
        logging.error(f"Command processing failed with exception: {e}")
        sys.exit(1)