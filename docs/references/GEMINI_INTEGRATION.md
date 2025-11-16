# 🤖 Talk2Windows + Gemini AI Integration

## Overview

This enhanced version of Talk2Windows integrates Google Gemini AI for **smart natural language understanding**. Instead of requiring exact voice commands, users can speak naturally and Gemini will understand their intent.

## Features

### 🧠 Two-Stage Intelligence
1. **Semantic Index Search**: Fast keyword-based search across all 797+ scripts
2. **Gemini AI Selection**: Smart understanding of natural language to pick the right script

### 💬 Natural Language Understanding
- **Before**: "Windows, open-calculator" (exact script name)
- **After**: "tell me the time", "calculator open", "launch chrome" (natural phrases)

### 🎯 Smart Discovery
- Indexes all PowerShell scripts automatically
- Builds semantic mappings (keywords, categories, descriptions)
- Only sends top 10 relevant tools to Gemini (saves API quota)
- Falls back to full 25-tool catalog if no matches

## Architecture

```
Voice Input (Serenade)
    ↓
Serenade Bridge (Python)
    ↓
Semantic Index Search (797 scripts)
    ↓
Top 10 Relevant Scripts
    ↓
Gemini AI (Function Calling)
    ↓
PowerShell Executor
    ↓
Result (TTS Output)
```

## Setup

### 1. Get Gemini API Key

1. Visit: https://makersuite.google.com/app/apikey
2. Create a free API key
3. Set environment variable:
   ```powershell
   [Environment]::SetEnvironmentVariable('TALK2WINDOWS_GEMINI_API_KEY', 'your-key-here', 'User')
   ```

### 2. Install Dependencies

```powershell
pip install google-generativeai pyyaml keyring
```

### 3. Build Semantic Index

```powershell
python -m agent.semantic_index
```

This will scan all scripts and build an index in `agent/semantic_index.json`.

### 4. Choose Integration Mode

#### Option A: Gemini Only (Text Input)
```powershell
python -m agent.service
```

Then type commands like:
- "tell me the time"
- "open calculator"
- "what's the weather"

#### Option B: Serenade + Gemini (Voice Input)

1. Install Serenade from https://serenade.ai
2. Generate Serenade configuration:
   ```powershell
   .\generate_serenade_gemini_config.ps1
   ```
3. Launch Serenade and switch to Listening mode
4. Say: "Windows tell me the time"

#### Option C: Full Setup (Both)

```powershell
.\setup_gemini.ps1
```

Follow the interactive prompts.

## Usage Examples

### Natural Language Queries

| You Say | Gemini Understands | Script Executed |
|---------|-------------------|-----------------|
| "tell me time" | User wants current time | `what-is-the-time` |
| "calculator open" | Open calculator app | `open-calculator` |
| "launch calc" | Open calculator app | `open-calculator` |
| "what's the weather" | Check weather | `check-weather` |
| "open chrome" | Launch Chrome browser | `open-google-chrome` |
| "minimize everything" | Minimize all windows | `minimize-all-windows` |
| "empty trash" | Empty recycle bin | `empty-recycle-bin` |

### Configuration Options

Set environment variables to customize behavior:

```powershell
# Confirmation policy
$env:TALK2WINDOWS_CONFIRM_POLICY = 'auto'  # auto, prompt, or voice

# Discovery mode  
$env:TALK2WINDOWS_DISCOVERY_MODE = 'auto'  # auto (semantic search) or direct (all 25 tools)
```

## How It Works

### 1. Semantic Index (`agent/semantic_index.py`)

- Scans all `.ps1` scripts in `scripts/` folder
- Extracts metadata (YAML in comments) or generates from filename
- Builds searchable index with:
  - Keywords (from metadata or script name)
  - Category (application, system-info, file-management, etc.)
  - Description (from YAML or .SYNOPSIS)
  - Risk level (low, medium, high)

### 2. Smart Search

When you say "open chrome":
1. Search index for "open chrome"
2. Find top 10 matches: `open-google-chrome`, `open-google-alerts`, etc.
3. Build focused tool list with just those 10 scripts

### 3. Gemini Function Calling

- Send focused tool list + user query to Gemini
- Gemini picks best matching function
- Return: `function_call(name="open-google-chrome")`

### 4. Execution

- Validate script exists
- Check risk level (confirm if needed)
- Execute via PowerShell
- Speak result via TTS

## Components

### Core Files

| File | Purpose |
|------|---------|
| `agent/service.py` | Main agent orchestrator |
| `agent/semantic_index.py` | Script indexing and search |
| `agent/tool_catalog_manager.py` | Gemini schema generation |
| `agent/powershell_executor.py` | Script execution |
| `agent/serenade_bridge.py` | Serenade voice integration |

### Configuration Files

| File | Purpose |
|------|---------|
| `prompts/planner.txt` | System instruction for Gemini |
| `agent/tools.json` | Generated tool catalog (25 documented scripts) |
| `agent/semantic_index.json` | Full script index (797 scripts) |

### Setup Scripts

| File | Purpose |
|------|---------|
| `setup_gemini.ps1` | Interactive setup wizard |
| `generate_serenade_gemini_config.ps1` | Generate Serenade config |

## Testing

### Test Natural Language Understanding

```powershell
python -m agent.test_natural_language
```

Runs 10 test cases with various phrasings.

### Test Single Command

```powershell
python -m agent.test_single_command "your command here"
```

### Test Semantic Search

```powershell
python -m agent.semantic_index
```

Shows search results for common queries.

## API Quota Management

Free tier limits:
- 250,000 tokens per minute
- 15 requests per minute

Our optimizations:
- ✅ Only send top 10 relevant tools (not all 797)
- ✅ Focused system prompt (not verbose)
- ✅ Function calling mode (forces structured output)
- ✅ Semantic search pre-filtering (reduces Gemini calls)

## Troubleshooting

### "Quota exceeded" error
Wait 60 seconds or upgrade to paid tier.

### "Could not convert part.function_call to text"
This is normal - means Gemini returned function call (good!).

### "Script not found"
Run `python -m agent.semantic_index` to rebuild index.

### Gemini not understanding commands
1. Check `prompts/planner.txt` system instruction
2. Verify tool descriptions in `agent/tools.json`
3. Test with `TALK2WINDOWS_DISCOVERY_MODE=direct` to use all 25 tools

## Future Enhancements

- [ ] Voice input directly (without Serenade)
- [ ] Multi-step plans (e.g., "check weather and open calendar")
- [ ] Context awareness (remember previous commands)
- [ ] Learning from corrections (user feedback loop)
- [ ] Custom script creation via voice
- [ ] Scheduler integration (e.g., "remind me in 5 minutes")

## Credits

- Original Talk2Windows: Markus Fleschutz
- Gemini Integration: AI Enhancement
- Serenade: https://serenade.ai
- Google Gemini: https://ai.google.dev

## License

CC0 (same as original Talk2Windows)
