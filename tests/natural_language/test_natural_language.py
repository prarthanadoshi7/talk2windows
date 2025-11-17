"""
Test natural language understanding with Gemini.
This script tests if Gemini can map natural user phrases to the correct tools.
"""
import asyncio
import logging
import sys
import os
import pytest

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.agent.core.service import AgentService

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

@pytest.mark.asyncio
async def test_natural_language_commands():
    """Test various natural language commands."""
    
    # Initialize service with auto-confirm for testing
    import os
    os.environ['TALK2WINDOWS_CONFIRM_POLICY'] = 'auto'
    
    service = AgentService(prompt_provider=lambda _: 'yes')
    
    test_cases = [
        # Format: (user_input, expected_tool_id)
        ("tell me time", "what-is-the-time"),
        ("what time is it", "what-is-the-time"),
        ("Windows tell me the time", "what-is-the-time"),
        ("calculator open", "open-calculator"),
        ("open calculator", "open-calculator"),
        ("launch calc", "open-calculator"),
        ("open the calculator", "open-calculator"),
        ("check weather", "check-weather"),
        ("what's the weather", "check-weather"),
        ("how's the weather", "check-weather"),
    ]
    
    results = []
    for user_input, expected_tool in test_cases:
        print(f"\n{'='*60}")
        print(f"Testing: '{user_input}'")
        print(f"Expected tool: {expected_tool}")
        print(f"{'='*60}")
        
        try:
            # Get Gemini response
            response = await asyncio.get_event_loop().run_in_executor(
                None, 
                lambda: service.model.generate_content(user_input, tool_config=service.tool_config)
            )
            
            # Check if function call was made
            function_called = None
            if response.candidates and response.candidates[0].content.parts:
                for part in response.candidates[0].content.parts:
                    if hasattr(part, 'function_call') and part.function_call:
                        function_called = part.function_call.name
                        break
            
            # Also check for plan in text
            if not function_called and response.text:
                import json
                try:
                    data = json.loads(response.text.strip())
                    if 'plan' in data and data['plan']:
                        function_called = data['plan'][0].get('tool')
                except:
                    pass
            
            success = (function_called == expected_tool)
            status = "✅ PASS" if success else "❌ FAIL"
            
            print(f"Result: {status}")
            print(f"Gemini called: {function_called}")
            if not success:
                print(f"Full response: {response.text if response.text else 'No text'}")
            
            results.append({
                'input': user_input,
                'expected': expected_tool,
                'actual': function_called,
                'success': success
            })
            
        except Exception as e:
            print(f"❌ ERROR: {e}")
            results.append({
                'input': user_input,
                'expected': expected_tool,
                'actual': None,
                'success': False,
                'error': str(e)
            })
    
    # Print summary
    print(f"\n{'='*60}")
    print("SUMMARY")
    print(f"{'='*60}")
    passed = sum(1 for r in results if r['success'])
    total = len(results)
    print(f"Passed: {passed}/{total} ({100*passed//total}%)")
    
    for result in results:
        if not result['success']:
            print(f"  ❌ '{result['input']}' -> expected {result['expected']}, got {result['actual']}")
    
    return results

if __name__ == "__main__":
    print("Testing Natural Language Understanding with Gemini...")
    print("="*60)
    asyncio.run(test_natural_language_commands())
