# Talk2Windows + Gemini Integration - Project Structure

## Directory Organization

```
talk2windows/
├── agent/                      # Core agent components
│   ├── __init__.py
│   ├── service.py             # Main orchestrator (284 lines)
│   ├── semantic_index.py      # Script indexing & search (250 lines)
│   ├── powershell_executor.py # Script execution (66 lines)
│   ├── tool_catalog_manager.py# Gemini schema generator (150 lines)
│   ├── serenade_bridge.py     # Serenade voice integration (35 lines)
│   ├── serenade_listener.py   # Voice listener
│   ├── config.py              # Configuration management
│   ├── tts.py                 # Text-to-speech
│   ├── run-script.ps1         # PowerShell executor script
│   ├── tools.json             # Generated tool catalog (25 tools)
│   ├── semantic_index.json    # Full script index (797 scripts)
│   ├── config.json            # Runtime configuration
│   ├── memory/                # Memory store
│   │   └── store.py
│   └── tools/                 # Tool utilities
│
├── tests/                      # All test files
│   ├── __init__.py
│   ├── test_system.py         # Comprehensive system test
│   ├── test_single_command.py # Single command test
│   ├── test_natural_language.py # NLU test suite
│   ├── test_service.py        # Service unit tests
│   ├── test_powershell_executor.py # Executor tests
│   ├── test_tool_catalog_manager.py # Catalog tests
│   └── test_integration.py    # Integration tests
│
├── scripts/                    # PowerShell scripts (801 total)
│   ├── check-battery.ps1
│   ├── open-calculator.ps1
│   ├── what-is-the-time.ps1
│   ├── ... (797 indexed scripts)
│   └── _*.ps1                 # (4 internal scripts - not indexed)
│
├── prompts/                    # AI prompts
│   └── planner.txt            # Gemini system instruction
│
├── docs/                       # Documentation
│   └── plan/                  # Project planning docs
│
├── quick_setup.ps1             # Quick setup script
├── setup.ps1                  # Original Serenade setup
├── setup_gemini.ps1           # Gemini setup wizard
├── generate_serenade_gemini_config.ps1 # Serenade config generator
├── GEMINI_INTEGRATION.md      # Full integration guide
├── IMPLEMENTATION_SUMMARY.md  # Technical summary
├── PROJECT_STRUCTURE.md       # This file
├── README.md                  # Original README
└── LICENSE                    # CC0 License
```

## Import Paths

All test files now properly import from the parent directory:

```python
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from agent.service import AgentService
from agent.semantic_index import SemanticIndex
# etc.
```

## Running Tests

### All Tests
```bash
python -m tests.test_system
```

### Specific Tests
```bash
python -m tests.test_single_command "your command"
python -m tests.test_natural_language
python -m pytest tests/test_service.py
```

## Module Structure

### agent.service (Main Orchestrator)
- `AgentService` - Main class
  - `handle_transcript(text)` - Process user input
  - `execute_plan(plan)` - Execute multi-step plans
  - `confirm(text, level)` - Handle confirmations
  - `_build_focused_tool_list(matches)` - Build focused tool list from search

### agent.semantic_index (Intelligent Search)
- `SemanticIndex` - Search engine
  - `search(query, max_results)` - Find relevant scripts
  - `rebuild_index()` - Regenerate index
  - `get_category_scripts(category)` - Get scripts by category
  - Index file: `agent/semantic_index.json`

### agent.powershell_executor (Script Execution)
- `PowerShellExecutor` - Runs PowerShell scripts
  - `run(tool_name, args)` - Execute script
  - `_validate_tool_name(name)` - Security validation
  - Uses: `agent/run-script.ps1`

### agent.tool_catalog_manager (Gemini Integration)
- `ToolCatalogManager` - Generates Gemini schemas
  - `generate_catalog()` - Scan scripts and build catalog
  - `load_catalog()` - Load existing catalog
  - `transform_to_gemini_schema(metadata)` - Convert to Gemini format
  - Output: `agent/tools.json`

## Data Files

### agent/semantic_index.json
```json
{
  "scripts": {
    "script-id": {
      "id": "script-id",
      "name": "Human readable name",
      "description": "What it does",
      "category": "application|system-info|file-management|voice|system-control",
      "keywords": ["keyword1", "keyword2"],
      "risk_level": "low|medium|high",
      "has_metadata": true
    }
  },
  "categories": {
    "application": ["script1", "script2"],
    "system-info": ["script3"]
  },
  "keywords": {
    "calculator": ["open-calculator", "close-calculator"],
    "time": ["what-is-the-time", "check-time-zone"]
  },
  "version": "1.0"
}
```

### agent/tools.json
```json
{
  "tools": [
    {
      "name": "script-id",
      "description": "Description | User might say: example1, example2",
      "parameters": {
        "type": "OBJECT",
        "properties": {},
        "required": []
      }
    }
  ],
  "risk_levels": {
    "script-id": "low"
  }
}
```

## Configuration

### Environment Variables
```bash
TALK2WINDOWS_GEMINI_API_KEY=your-api-key
TALK2WINDOWS_CONFIRM_POLICY=auto|prompt|voice
TALK2WINDOWS_DISCOVERY_MODE=auto|direct
```

### agent/config.json
```json
{
  "gemini_api_key": "encrypted-or-from-keyring",
  "confirm_policy": "auto",
  "discovery_mode": "auto"
}
```

## Development Workflow

### 1. Add New Script
```bash
# Create script in scripts/
scripts/my-new-script.ps1

# Add YAML metadata
<#
name: My New Script
description: Does something useful
category: application
keywords:
  - keyword1
  - keyword2
examples:
  - open something
  - launch something
risk_level: low
#>

# Rebuild indexes
python -c "from agent.semantic_index import SemanticIndex; SemanticIndex().rebuild_index()"
python -c "from agent.tool_catalog_manager import ToolCatalogManager; ToolCatalogManager().generate_catalog()"
```

### 2. Test Script
```bash
python -m tests.test_single_command "your command"
```

### 3. Run Full Test Suite
```bash
python -m tests.test_system
python -m tests.test_natural_language
```

## Key Design Decisions

### 1. Two-Stage Intelligence
- **Stage 1**: Semantic search (fast, keyword-based)
- **Stage 2**: Gemini AI (smart, NLU-based)
- **Benefit**: Reduced API quota usage, faster responses

### 2. Test Organization
- All tests in `tests/` directory
- Proper import paths using `sys.path`
- Comprehensive system test for CI/CD

### 3. Script Indexing
- 797 scripts indexed (4 internal scripts excluded)
- Automatic metadata extraction
- Fallback generation from script names

### 4. Path Resolution
- Absolute paths using `os.path.abspath()`
- Consistent directory structure
- No relative path issues

## Maintenance

### Rebuild Indexes
```bash
python -m agent.semantic_index
python -c "from agent.tool_catalog_manager import ToolCatalogManager; ToolCatalogManager().generate_catalog()"
```

### Run Tests
```bash
python -m tests.test_system  # Full system test
python -m pytest tests/      # All unit tests
```

### Clean Up
```bash
# Remove generated files
rm agent/semantic_index.json
rm agent/tools.json
rm agent/*.pyc
rm -r agent/__pycache__

# Rebuild
python -m agent.semantic_index
```

## Troubleshooting

### "Module not found" errors
- Ensure `sys.path.insert()` at top of test files
- Check `__init__.py` exists in `agent/` and `tests/`

### "Path not found" errors
- Use `os.path.abspath()` for all paths
- Check `executor_path` in `PowerShellExecutor`

### "Script not indexed" errors
- Rebuild semantic index
- Check script doesn't start with `_`

### Gemini quota errors
- Wait 60 seconds between requests
- Use `TALK2WINDOWS_DISCOVERY_MODE=auto` to reduce tokens
