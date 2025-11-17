import json
import os
from pathlib import Path
from typing import Any, Dict

_CONFIG_PATH = Path(__file__).resolve().parent / "config.json"
_ENV_API_KEY = "TALK2WINDOWS_GEMINI_API_KEY"

# Default environment variables for proper Serenade integration
DEFAULT_ENV_VARS = {
    'TALK2WINDOWS_DISABLE_TTS': '1',
    'TALK2WINDOWS_CONFIRM_POLICY': 'auto',
    'TALK2WINDOWS_DISCOVERY_MODE': 'auto'
}

def setup_environment():
    """Set up default environment variables for proper operation."""
    for key, value in DEFAULT_ENV_VARS.items():
        if not os.getenv(key):
            os.environ[key] = value

def _load_file_config() -> Dict[str, Any]:
    if not _CONFIG_PATH.exists():
        return {}
    with _CONFIG_PATH.open("r", encoding="utf-8") as handle:
        try:
            return json.load(handle)
        except json.JSONDecodeError as exc:
            raise RuntimeError(f"Invalid JSON in {_CONFIG_PATH}: {exc}") from exc

def get_gemini_api_key() -> str:
    """Return the Gemini API key from env or optional config file."""
    env_key = os.getenv(_ENV_API_KEY)
    if env_key:
        return env_key
    # If keyring is available, try retrieving the key
    try:
        import keyring  # type: ignore
        keyring_key = keyring.get_password('talk2windows', 'gemini_api_key')
        if keyring_key:
            return keyring_key
    except Exception:
        # Keyring not installed or failed; fall back to config file
        pass
    file_config = _load_file_config()
    key = file_config.get("gemini_api_key")
    if key:
        return key
    raise RuntimeError(
        "Gemini API key not configured. Set TALK2WINDOWS_GEMINI_API_KEY or provide "
        f"gemini_api_key in {_CONFIG_PATH}."
    )