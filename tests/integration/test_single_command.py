"""
Simple test to verify one natural language command works.
"""
import asyncio
import logging
import sys
import os
import pytest

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.agent.core.service import AgentService

logging.basicConfig(level=logging.INFO)

@pytest.mark.asyncio
async def test_single_command():
    """Test a single natural language command."""
    os.environ['TALK2WINDOWS_CONFIRM_POLICY'] = 'auto'
    os.environ['TALK2WINDOWS_DISCOVERY_MODE'] = 'auto'  # Enable smart discovery
    
    user_input = "what time is it"  # Test with a simple command
    service = AgentService(prompt_provider=lambda _: 'yes')
    
    print(f"\n{'='*60}")
    print(f"User says: '{user_input}'")
    print(f"Discovery mode: {service.discovery_mode}")
    print(f"Indexed scripts: {len(service.semantic_index.index['scripts'])}")
    print(f"{'='*60}\n")
    
    try:
        # Use handle_transcript to test the full pipeline (including semantic search)
        result = await service.handle_transcript(user_input)
        print(f"\nResult: {result}")
            
    except Exception as e:
        print(f"✗ Error: {e}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        print("Usage: python -m src.agent.test_single_command 'your command here'")
        print("Example: python -m src.agent.test_single_command 'tell me time'")
        sys.exit(1)
    
    user_input = ' '.join(sys.argv[1:])
    asyncio.run(test_single_command(user_input))
