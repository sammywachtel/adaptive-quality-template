#!/usr/bin/env python3
"""
Fix duplicate TOML sections by merging them automatically.
Specifically handles common duplicates like [tool.pytest.ini_options].
"""

import sys
import re
from pathlib import Path


def fix_duplicate_sections(file_path, backup=True):
    """
    Fix duplicate TOML sections by merging them.
    """
    if backup:
        backup_path = f"{file_path}.backup"
        with open(file_path, 'r') as src, open(backup_path, 'w') as dst:
            dst.write(src.read())
        print(f"✓ Created backup: {backup_path}")
    
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Find all instances of [tool.pytest.ini_options]
    pytest_sections = []
    pytest_pattern = r'\[tool\.pytest\.ini_options\](.*?)(?=\[|\Z)'
    
    matches = list(re.finditer(pytest_pattern, content, re.DOTALL))
    
    if len(matches) <= 1:
        print("✓ No duplicate [tool.pytest.ini_options] sections found")
        return False
    
    print(f"Found {len(matches)} [tool.pytest.ini_options] sections")
    
    # Extract and merge all pytest.ini_options content
    all_settings = {}
    all_content_lines = []
    
    for i, match in enumerate(matches):
        section_content = match.group(1).strip()
        print(f"  Section {i+1} at position {match.start()}")
        
        # Parse the section content
        for line in section_content.split('\n'):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip()
                
                # Handle array values
                if key in all_settings:
                    print(f"    Merging duplicate key: {key}")
                    # For arrays, merge them
                    if value.startswith('[') and all_settings[key].startswith('['):
                        # Extract array items
                        old_items = re.findall(r'"([^"]*)"', all_settings[key])
                        new_items = re.findall(r'"([^"]*)"', value)
                        combined = list(dict.fromkeys(old_items + new_items))  # Remove duplicates, preserve order
                        all_settings[key] = '[\n    ' + ',\n    '.join(f'"{item}"' for item in combined) + ',\n]'
                    else:
                        # For non-arrays, keep the first one (or could ask user)
                        print(f"      Keeping first value: {all_settings[key]}")
                else:
                    all_settings[key] = value
    
    # Generate the merged section
    merged_content = "[tool.pytest.ini_options]\n"
    for key, value in all_settings.items():
        if value.startswith('['):
            merged_content += f"{key} = {value}\n"
        else:
            merged_content += f"{key} = {value}\n"
    
    # Remove all existing pytest sections and insert the merged one
    # Find the position of the first section
    first_match = matches[0]
    
    # Remove all pytest sections
    new_content = content
    for match in reversed(matches):  # Remove from end to preserve positions
        new_content = new_content[:match.start()] + new_content[match.end():]
    
    # Insert merged section at the position of the first one
    insertion_point = first_match.start()
    new_content = new_content[:insertion_point] + merged_content + "\n" + new_content[insertion_point:]
    
    # Write the fixed content
    with open(file_path, 'w') as f:
        f.write(new_content)
    
    print(f"✓ Fixed duplicate sections in {file_path}")
    print(f"✓ Merged {len(matches)} sections into one")
    return True


def main():
    if len(sys.argv) != 2:
        print("Usage: fix-duplicate-toml-sections.py <pyproject.toml>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    if not Path(file_path).exists():
        print(f"Error: File {file_path} does not exist")
        sys.exit(1)
    
    try:
        fixed = fix_duplicate_sections(file_path)
        if fixed:
            print("\n🎉 File has been fixed! You can now run the merge script.")
        else:
            print("\n✅ No fixes needed.")
    except Exception as e:
        print(f"Error fixing file: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()