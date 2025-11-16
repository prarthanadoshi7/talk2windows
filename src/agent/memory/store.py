import hashlib
import json
import os
from typing import Any


class MemoryStore:
    def __init__(self):
        self.memory_dir = os.path.join(os.path.dirname(__file__), "memory")
        os.makedirs(self.memory_dir, exist_ok=True)
        self.recent_actions = self.load('recent_actions') or []
        self._prune_actions_if_needed()

    def _path_for(self, key: str) -> str:
        return os.path.join(self.memory_dir, f"{key}.json")

    def _write_json(self, key: str, value: Any) -> None:
        path = self._path_for(key)
        with open(path, 'w', encoding='utf-8') as file:
            json.dump(value, file)

    def save(self, key: str, value: Any) -> None:
        """Persist a key-value pair to disk."""
        if key == 'recent_actions':
            self.recent_actions = list(value)
            self._prune_actions_if_needed(persist=True)
            return
        self._write_json(key, value)

    def load(self, key: str):
        """Load a value by key."""
        path = self._path_for(key)
        if os.path.exists(path):
            with open(path, 'r', encoding='utf-8') as file:
                return json.load(file)
        return None

    def _prune_actions_if_needed(self, persist: bool = False) -> None:
        """Ensure recent_actions keeps only the last 100 entries."""
        if len(self.recent_actions) > 100:
            self.recent_actions = self.recent_actions[-100:]
            persist = True
        if persist:
            self._write_json('recent_actions', self.recent_actions)

    def get_passphrase_hash(self):
        """Get stored passphrase hash."""
        config = self.load('config') or {}
        return config.get('passphrase_hash')

    def set_passphrase(self, passphrase: str) -> None:
        """Set passphrase hash."""
        config = self.load('config') or {}
        config['passphrase_hash'] = hashlib.sha256(passphrase.encode()).hexdigest()
        self._write_json('config', config)