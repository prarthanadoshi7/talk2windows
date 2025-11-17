"""
Comprehensive system test for Talk2Windows + Gemini integration.
Tests all major components and verifies proper functionality.
"""
import asyncio
import logging
import sys
import os
import pytest

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.agent.core.service import AgentService
from src.agent.core.semantic_index import SemanticIndex
from src.agent.execution.powershell_executor import PowerShellExecutor
from src.agent.core.tool_catalog_manager import ToolCatalogManager

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def test_1_semantic_index():
    """Test semantic index is built and searchable."""
    print("\n" + "="*60)
    print("TEST 1: Semantic Index")
    print("="*60)
    
    index = SemanticIndex()
    scripts_count = len(index.index['scripts'])
    
    assert scripts_count > 700, f"Expected 700+ scripts, got {scripts_count}"
    print(f"✅ Indexed {scripts_count} scripts")
    
    # Test search functionality
    results = index.search("time", max_results=5)
    assert len(results) > 0, "Search returned no results"
    assert any('time' in r['id'].lower() for r in results), "Search results don't match query"
    print(f"✅ Search working: found {len(results)} results for 'time'")
    
    print("✅ TEST 1 PASSED\n")


def test_2_powershell_executor():
    """Test PowerShell executor can find and run scripts."""
    print("\n" + "="*60)
    print("TEST 2: PowerShell Executor")
    print("="*60)
    
    executor = PowerShellExecutor()
    
    # Check executor path exists
    assert os.path.exists(executor.executor_path), f"Executor not found: {executor.executor_path}"
    print(f"✅ Executor path exists: {executor.executor_path}")
    
    # Test validation
    try:
        executor._validate_tool_name("../invalid")
        assert False, "Should have rejected invalid tool name"
    except ValueError:
        print("✅ Tool name validation working")
    
    print("✅ TEST 2 PASSED\n")


def test_3_tool_catalog():
    """Test tool catalog is generated properly."""
    print("\n" + "="*60)
    print("TEST 3: Tool Catalog")
    print("="*60)
    
    manager = ToolCatalogManager()
    catalog = manager.load_catalog()
    
    assert 'tools' in catalog, "Catalog missing 'tools' key"
    assert 'risk_levels' in catalog, "Catalog missing 'risk_levels' key"
    
    tools = catalog['tools']
    assert len(tools) > 0, "No tools in catalog"
    print(f"✅ Catalog loaded: {len(tools)} tools")
    
    # Check tool schema
    sample_tool = tools[0]
    assert 'name' in sample_tool, "Tool missing 'name'"
    assert 'description' in sample_tool, "Tool missing 'description'"
    assert 'parameters' in sample_tool, "Tool missing 'parameters'"
    print(f"✅ Tool schema valid: {sample_tool['name']}")
    
    print("✅ TEST 3 PASSED\n")


@pytest.mark.asyncio
async def test_4_service_initialization():
    """Test agent service initializes properly."""
    print("\n" + "="*60)
    print("TEST 4: Service Initialization")
    print("="*60)
    
    os.environ['TALK2WINDOWS_CONFIRM_POLICY'] = 'auto'
    os.environ['TALK2WINDOWS_DISCOVERY_MODE'] = 'auto'
    
    service = AgentService(prompt_provider=lambda _: 'yes')
    
    assert service.tools is not None, "Service tools not loaded"
    assert service.semantic_index is not None, "Semantic index not initialized"
    assert service.executor is not None, "Executor not initialized"
    
    print(f"✅ Service initialized")
    print(f"   - Tools: {len(service.tools)}")
    print(f"   - Indexed scripts: {len(service.semantic_index.index['scripts'])}")
    print(f"   - Discovery mode: {service.discovery_mode}")
    
    print("✅ TEST 4 PASSED\n")


def test_5_project_structure():
    """Test project structure is organized correctly."""
    print("\n" + "="*60)
    print("TEST 5: Project Structure")
    print("="*60)
    
    # Get to project root: tests/system/test_system.py -> tests/system -> tests -> project_root
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    
    # Check required directories
    required_dirs = [
        'src/agent',
        'scripts',
        'tests',
        'prompts',
        'docs',
        'bin',
        'data'
    ]
    
    for dir_name in required_dirs:
        dir_path = os.path.join(base_dir, dir_name)
        assert os.path.isdir(dir_path), f"Missing directory: {dir_name}"
        print(f"✅ Directory exists: {dir_name}")
    
    # Check required files
    required_files = [
        'src/agent/service.py',
        'src/agent/semantic_index.py',
        'src/agent/powershell_executor.py',
        'src/agent/tool_catalog_manager.py',
        'src/agent/run-script.ps1',
        'prompts/planner.txt',
        'bin/quick_setup.ps1',
        'docs/references/GEMINI_INTEGRATION.md',
        'docs/references/IMPLEMENTATION_SUMMARY.md'
    ]
    
    for file_path in required_files:
        full_path = os.path.join(base_dir, file_path)
        assert os.path.isfile(full_path), f"Missing file: {file_path}"
        print(f"✅ File exists: {file_path}")
    
    print("✅ TEST 5 PASSED\n")


async def run_all_tests():
    """Run all tests."""
    print("\n" + "#"*60)
    print("# Talk2Windows + Gemini Integration - System Test")
    print("#"*60)
    
    try:
        test_1_semantic_index()
        test_2_powershell_executor()
        test_3_tool_catalog()
        await test_4_service_initialization()
        test_5_project_structure()
        
        print("\n" + "="*60)
        print("✅ ALL TESTS PASSED!")
        print("="*60)
        print("\nSystem is ready to use!")
        print("Run: python -m tests.test_single_command 'your command here'")
        print("Or:  python -m src.agent.service (for interactive mode)")
        print()
        
        return True
        
    except AssertionError as e:
        print(f"\n❌ TEST FAILED: {e}\n")
        return False
    except Exception as e:
        print(f"\n❌ ERROR: {e}\n")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    success = asyncio.run(run_all_tests())
    sys.exit(0 if success else 1)
