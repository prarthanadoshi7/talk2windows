"""
Semantic Index Manager - Creates a searchable index of all scripts.
Instead of sending 1000+ tools to Gemini, we:
1. Build a semantic index of all scripts (keywords, descriptions, categories)
2. When user makes a request, first search the index
3. Only send the top 5-10 relevant tools to Gemini for final selection
"""
import json
import logging
import os
from pathlib import Path
from typing import Dict, List, Optional
import yaml


class SemanticIndex:
    """Manages a semantic index of all PowerShell scripts."""
    
    def __init__(self, scripts_dir: Optional[str] = None):
        self.logger = logging.getLogger(__name__)
        self.scripts_dir = scripts_dir or os.path.join(
            os.path.dirname(__file__), "..", "..", "..", "scripts"
        )
        self.index_file = os.path.join(
            os.path.dirname(__file__), "..", "config", "semantic_index.json"
        )
        self.index = self._load_or_build_index()
    
    def _load_or_build_index(self) -> Dict:
        """Load existing index or build a new one."""
        if os.path.exists(self.index_file):
            with open(self.index_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return self._build_index()
    
    def _build_index(self) -> Dict:
        """Build semantic index from all scripts."""
        self.logger.info("Building semantic index from all scripts...")
        index = {
            'scripts': {},
            'categories': {},
            'keywords': {},
            'version': '1.0'
        }
        
        scripts_path = Path(self.scripts_dir)
        if not scripts_path.exists():
            self.logger.warning(f"Scripts directory not found: {self.scripts_dir}")
            return index
        
        # Use recursive glob to find all .ps1 files in subdirectories
        for script_file in scripts_path.rglob("*.ps1"):
            if script_file.name.startswith('_'):
                continue  # Skip internal scripts
            
            script_id = script_file.stem
            script_info = self._extract_script_info(script_file)
            
            if script_info:
                index['scripts'][script_id] = script_info
                
                # Index by category
                category = script_info.get('category', 'general')
                if category not in index['categories']:
                    index['categories'][category] = []
                index['categories'][category].append(script_id)
                
                # Index by keywords
                for keyword in script_info.get('keywords', []):
                    keyword_lower = keyword.lower()
                    if keyword_lower not in index['keywords']:
                        index['keywords'][keyword_lower] = []
                    index['keywords'][keyword_lower].append(script_id)
        
        # Save index
        with open(self.index_file, 'w', encoding='utf-8') as f:
            json.dump(index, f, indent=2)
        
        self.logger.info(f"Built index with {len(index['scripts'])} scripts")
        return index
    
    def _extract_script_info(self, script_file: Path) -> Optional[Dict]:
        """Extract metadata and generate smart summary from script."""
        try:
            with open(script_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Try to extract YAML metadata first
            metadata = self._extract_yaml_metadata(content)
            if metadata:
                return {
                    'id': script_file.stem,
                    'name': metadata.get('name', script_file.stem),
                    'description': metadata.get('description', ''),
                    'category': metadata.get('category', 'general'),
                    'keywords': metadata.get('keywords', []) + 
                                metadata.get('examples', []) +
                                [script_file.stem.replace('-', ' ')],
                    'risk_level': metadata.get('risk_level', 'low'),
                    'has_metadata': True
                }
            
            # Fallback: generate from script name and comments
            return self._generate_from_script_name(script_file, content)
            
        except Exception as e:
            self.logger.warning(f"Error extracting info from {script_file.name}: {e}")
            return None
    
    def _extract_yaml_metadata(self, content: str) -> Optional[Dict]:
        """Extract YAML metadata from script comments."""
        try:
            if '<#' in content and '#>' in content:
                start = content.index('<#') + 2
                end = content.index('#>', start)
                comment_block = content[start:end]
                
                # Try to parse as YAML
                metadata = yaml.safe_load(comment_block)
                if isinstance(metadata, dict):
                    return metadata
        except:
            pass
        return None
    
    def _generate_from_script_name(self, script_file: Path, content: str) -> Dict:
        """Generate metadata from script name and content analysis."""
        script_id = script_file.stem
        
        # Generate natural language description from script name
        words = script_id.replace('-', ' ')
        
        # Infer category from name patterns
        category = 'general'
        if any(word in script_id for word in ['open', 'launch', 'start']):
            category = 'application'
        elif any(word in script_id for word in ['close', 'kill', 'stop']):
            category = 'application'
        elif any(word in script_id for word in ['check', 'get', 'show', 'list', 'what']):
            category = 'system-info'
        elif any(word in script_id for word in ['set', 'change', 'adjust']):
            category = 'system-control'
        elif any(word in script_id for word in ['file', 'folder', 'directory']):
            category = 'file-management'
        elif any(word in script_id for word in ['say', 'speak', 'tell']):
            category = 'voice'
        
        # Extract keywords from script name
        keywords = [
            words,
            script_id,
            *script_id.split('-')
        ]
        
        # Try to extract .SYNOPSIS from PowerShell comment-based help
        description = words
        if '.SYNOPSIS' in content:
            try:
                start = content.index('.SYNOPSIS') + 9
                end = content.index('.', start + 1)
                synopsis = content[start:end].strip()
                if synopsis:
                    description = synopsis
            except:
                pass
        
        return {
            'id': script_id,
            'name': words,
            'description': description,
            'category': category,
            'keywords': keywords,
            'risk_level': 'low',
            'has_metadata': False
        }
    
    def search(self, query: str, max_results: int = 10) -> List[Dict]:
        """
        Search the index for scripts matching the query.
        Returns top N most relevant scripts.
        """
        query_lower = query.lower()
        query_words = query_lower.split()
        
        # Score each script
        scores = {}
        
        for script_id, script_info in self.index['scripts'].items():
            score = 0
            
            # Exact match in ID (highest score)
            if query_lower in script_id.lower():
                score += 100
            
            # Match in keywords
            for keyword in script_info.get('keywords', []):
                keyword_lower = keyword.lower()
                if query_lower == keyword_lower:
                    score += 50
                elif query_lower in keyword_lower:
                    score += 30
                # Partial word matches
                for word in query_words:
                    if word in keyword_lower:
                        score += 10
            
            # Match in description
            description = script_info.get('description', '').lower()
            if query_lower in description:
                score += 40
            for word in query_words:
                if word in description:
                    score += 5
            
            # Match in name
            name = script_info.get('name', '').lower()
            if query_lower in name:
                score += 60
            
            if score > 0:
                scores[script_id] = score
        
        # Sort by score and return top N
        sorted_scripts = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        results = []
        
        for script_id, score in sorted_scripts[:max_results]:
            result = self.index['scripts'][script_id].copy()
            result['relevance_score'] = score
            results.append(result)
        
        return results
    
    def get_category_scripts(self, category: str) -> List[str]:
        """Get all scripts in a category."""
        return self.index['categories'].get(category, [])
    
    def get_all_categories(self) -> List[str]:
        """Get all available categories."""
        return list(self.index['categories'].keys())
    
    def rebuild_index(self):
        """Force rebuild the index."""
        self.index = self._build_index()
        return len(self.index['scripts'])


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    
    # Build and test the index
    index = SemanticIndex()
    
    print(f"\nBuilt index with {len(index.index['scripts'])} scripts")
    print(f"Categories: {', '.join(index.get_all_categories())}")
    
    # Test searches
    test_queries = [
        "time",
        "calculator",
        "weather",
        "open chrome",
        "close notepad",
        "battery",
        "minimize windows"
    ]
    
    for query in test_queries:
        print(f"\n{'='*60}")
        print(f"Query: '{query}'")
        print(f"{'='*60}")
        results = index.search(query, max_results=5)
        for i, result in enumerate(results, 1):
            print(f"{i}. {result['id']} (score: {result['relevance_score']})")
            print(f"   {result['description']}")
