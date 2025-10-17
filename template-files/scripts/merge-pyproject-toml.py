#!/usr/bin/env python3
"""
Merge pyproject.toml files intelligently.
Preserves existing [build-system] and [project] sections while adding tool configurations.
"""

import sys
import os
from pathlib import Path

try:
    import tomli
except ImportError:
    print("Installing tomli for TOML parsing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "tomli"])
    import tomli

try:
    import tomli_w
except ImportError:
    print("Installing tomli_w for TOML writing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "tomli_w"])
    import tomli_w


def _merge_dict_recursive(existing_dict, template_dict):
    """
    Recursively merge dictionaries, preserving existing keys and only adding missing ones.
    """
    merged = existing_dict.copy()
    
    for key, value in template_dict.items():
        if key not in merged:
            # Key doesn't exist, add it
            merged[key] = value
        elif isinstance(value, dict) and isinstance(merged[key], dict):
            # Both are dicts, merge recursively
            merged[key] = _merge_dict_recursive(merged[key], value)
        # If key exists and not both dicts, keep existing value (user's preference)
    
    return merged


def _extract_coverage_settings(addopts_value):
    """
    Extract coverage-related settings from addopts string or list.
    Returns (coverage_args, other_args).
    """
    coverage_args = []
    other_args = []
    
    # Convert to list if it's a string
    if isinstance(addopts_value, str):
        args = addopts_value.split()
    else:
        # If it's a list, join and split to normalize
        args = ' '.join(addopts_value).split()
    
    i = 0
    while i < len(args):
        arg = args[i]
        if arg.startswith('--cov'):
            coverage_args.append(arg)
            # Check if next arg is the value for --cov (when not using = format)
            if arg == '--cov' and i + 1 < len(args) and not args[i + 1].startswith('-'):
                i += 1
                coverage_args.append(args[i])
        elif arg.startswith('--cov-'):
            coverage_args.append(arg)
        else:
            other_args.append(arg)
        i += 1
    
    return coverage_args, other_args


def _merge_pytest_selectively(existing_pytest, template_pytest):
    """
    Selectively merge pytest configuration in overwrite mode:
    - Preserve user's project-specific settings (testpaths, python_*, coverage target)
    - Standardize format and add missing template settings
    - Merge markers intelligently
    """
    if 'ini_options' not in existing_pytest and 'ini_options' not in template_pytest:
        return template_pytest
        
    existing_ini = existing_pytest.get('ini_options', {})
    template_ini = template_pytest.get('ini_options', {})
    
    merged_ini = {}
    
    # 1. Always use template standards for these
    if 'minversion' in template_ini:
        merged_ini['minversion'] = template_ini['minversion']
    
    # 2. Preserve user's project structure settings
    for key in ['testpaths', 'python_files', 'python_classes', 'python_functions']:
        if key in existing_ini:
            merged_ini[key] = existing_ini[key]
        elif key in template_ini:
            merged_ini[key] = template_ini[key]
    
    # 3. Smart merge for addopts - preserve coverage settings, standardize the rest
    template_addopts = template_ini.get('addopts', '')
    existing_addopts = existing_ini.get('addopts', [])
    
    if existing_addopts:
        # Extract user's coverage settings
        user_coverage_args, user_other_args = _extract_coverage_settings(existing_addopts)
        
        # Start with template's standard args
        if isinstance(template_addopts, str):
            standard_args = template_addopts.split()
        else:
            standard_args = ' '.join(template_addopts).split()
        
        # Combine: template standards + user's coverage settings
        all_args = standard_args + user_coverage_args
        
        # Remove duplicates while preserving order
        seen = set()
        unique_args = []
        for arg in all_args:
            if arg not in seen:
                unique_args.append(arg)
                seen.add(arg)
        
        merged_ini['addopts'] = ' '.join(unique_args)
    else:
        # No existing addopts, use template
        merged_ini['addopts'] = template_addopts
    
    # 4. Smart merge for markers - combine user's custom markers with template standards
    existing_markers = existing_ini.get('markers', [])
    template_markers = template_ini.get('markers', [])
    
    # Create a set to track marker names (before the colon) to avoid duplicates
    marker_names = set()
    merged_markers = []
    
    # Add template markers first (standards)
    for marker in template_markers:
        marker_name = marker.split(':')[0].strip()
        if marker_name not in marker_names:
            merged_markers.append(marker)
            marker_names.add(marker_name)
    
    # Add user's custom markers (preserve domain-specific ones)
    for marker in existing_markers:
        marker_name = marker.split(':')[0].strip()
        if marker_name not in marker_names:
            merged_markers.append(marker)
            marker_names.add(marker_name)
    
    if merged_markers:
        merged_ini['markers'] = merged_markers
    
    # 5. Copy any other settings from existing that we haven't handled
    for key, value in existing_ini.items():
        if key not in merged_ini:
            merged_ini[key] = value
    
    # 6. Add any other template settings we haven't handled
    for key, value in template_ini.items():
        if key not in merged_ini:
            merged_ini[key] = value
    
    return {'ini_options': merged_ini}


def _validate_toml_file(file_path):
    """
    Validate TOML file and provide helpful error messages for common issues.
    """
    try:
        with open(file_path, 'rb') as f:
            tomli.load(f)
        return True
    except tomli.TOMLDecodeError as e:
        error_msg = str(e)
        if "Cannot declare" in error_msg and "twice" in error_msg:
            # Extract section name from error message
            import re
            match = re.search(r"Cannot declare \('([^']+)'(?:, '([^']+)')?(?:, '([^']+)')?\) twice", error_msg)
            if match:
                sections = [s for s in match.groups() if s]
                section_path = ".".join(sections)
                raise ValueError(f"""
❌ Duplicate TOML section detected in {file_path}

The file contains multiple [{section_path}] sections, which is invalid TOML.

SOLUTION: Fix the duplicate sections manually:

1. Open {file_path} in a text editor
2. Search for "[{section_path}]" (you'll find multiple instances)
3. Manually merge the duplicate sections:
   - Combine all unique settings from both sections
   - Keep only ONE [{section_path}] header
   - Remove the duplicate section headers

4. Re-run the merge script

Example for [tool.pytest.ini_options] duplicates:
   BEFORE (invalid):
   [tool.pytest.ini_options]
   testpaths = ["tests"]
   addopts = "--cov"
   
   [tool.pytest.ini_options]  ← DUPLICATE! 
   markers = ["slow"]
   
   AFTER (valid):
   [tool.pytest.ini_options]
   testpaths = ["tests"]
   addopts = "--cov"
   markers = ["slow"]
""")
        raise ValueError(f"Invalid TOML file {file_path}: {error_msg}")


def merge_pyproject_toml(existing_path, template_path, output_path=None, overwrite_tools=False):
    """
    Merge template pyproject.toml into existing one, preserving critical sections.
    
    Args:
        existing_path: Path to existing pyproject.toml
        template_path: Path to template pyproject.toml with tool configurations
        output_path: Optional output path (defaults to existing_path)
        overwrite_tools: If True, completely replace tool configs (black, mypy, etc.) with template versions
    """
    if output_path is None:
        output_path = existing_path
    
    # Validate input files first
    if Path(existing_path).exists():
        _validate_toml_file(existing_path)
    _validate_toml_file(template_path)
    
    # Read existing file
    existing_data = {}
    if Path(existing_path).exists():
        with open(existing_path, 'rb') as f:
            existing_data = tomli.load(f)
    
    # Read template file
    with open(template_path, 'rb') as f:
        template_data = tomli.load(f)
    
    # Merge strategy: Keep existing [build-system] and [project], merge/overwrite [tool] sections
    merged_data = {}
    
    # ALWAYS preserve critical sections from existing file
    if 'build-system' in existing_data:
        merged_data['build-system'] = existing_data['build-system']
    
    if 'project' in existing_data:
        merged_data['project'] = existing_data['project']
    
    # Handle tool configurations based on overwrite_tools flag
    if overwrite_tools:
        # Start with existing tools
        merged_data['tool'] = existing_data.get('tool', {})
        
        # List of tools we want to standardize from template
        tools_to_overwrite = ['black', 'isort', 'mypy', 'coverage', 'flake8', 'ruff']
        tools_to_merge_selectively = ['pytest']
        
        # Overwrite specified tools with template versions
        if 'tool' in template_data:
            for tool_name, tool_config in template_data['tool'].items():
                if tool_name in tools_to_merge_selectively:
                    # Special selective merge for pytest
                    if tool_name == 'pytest':
                        merged_data['tool'][tool_name] = _merge_pytest_selectively(
                            merged_data['tool'].get(tool_name, {}),
                            tool_config
                        )
                elif any(tool_name.startswith(t) for t in tools_to_overwrite):
                    # Completely replace with template version
                    merged_data['tool'][tool_name] = tool_config
                elif tool_name not in merged_data['tool']:
                    # Tool doesn't exist, add it
                    merged_data['tool'][tool_name] = tool_config
    else:
        # Original merge behavior: preserve existing, add missing
        merged_data['tool'] = existing_data.get('tool', {})
        
        # Add template tool configurations without overwriting existing ones
        if 'tool' in template_data:
            for tool_name, tool_config in template_data['tool'].items():
                if tool_name not in merged_data['tool']:
                    # Tool doesn't exist, add it completely
                    merged_data['tool'][tool_name] = tool_config
                else:
                    # Tool exists, merge configurations intelligently
                    if isinstance(tool_config, dict) and isinstance(merged_data['tool'][tool_name], dict):
                        # For dict configs, recursively merge without overwriting existing keys
                        merged_data['tool'][tool_name] = _merge_dict_recursive(
                            merged_data['tool'][tool_name], 
                            tool_config
                        )
                    # If not both dicts, keep existing (user's) configuration
    
    # Copy any other top-level sections from existing file (but not 'tool' since we handled that)
    for key in existing_data:
        if key not in merged_data and key != 'tool':
            merged_data[key] = existing_data[key]
    
    # Write merged configuration
    with open(output_path, 'wb') as f:
        tomli_w.dump(merged_data, f)
    
    # Post-process to fix multi-line string formatting
    _fix_multiline_strings(output_path)
    
    return overwrite_tools


def _fix_multiline_strings(file_path):
    """
    Fix multi-line string formatting that tomli_w escapes incorrectly.
    Specifically handles Black's extend-exclude pattern.
    """
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Fix Black extend-exclude pattern - match the exact escaped format from file
    escaped_pattern = 'extend-exclude = "/(\\n  # directories\\n  \\\\.eggs\\n  | \\\\.git\\n  | \\\\.hg\\n  | \\\\.mypy_cache\\n  | \\\\.tox\\n  | \\\\.venv\\n  | build\\n  | dist\\n)/\\n"'
    
    fixed_pattern = """extend-exclude = '''
/(
  # directories
  \.eggs
  | \.git
  | \.hg
  | \.mypy_cache
  | \.tox
  | \.venv
  | build
  | dist
)/
'''"""
    
    if escaped_pattern in content:
        content = content.replace(escaped_pattern, fixed_pattern)
        print("  - Fixed Black extend-exclude formatting to use triple quotes")
    
    with open(file_path, 'w') as f:
        f.write(content)


def main():
    if len(sys.argv) < 3:
        print("Usage: merge-pyproject-toml.py <existing-file> <template-file> [output-file] [--overwrite-tools]")
        print("  --overwrite-tools: Replace tool configs (black, mypy, etc.) with template versions")
        sys.exit(1)
    
    existing_file = sys.argv[1]
    template_file = sys.argv[2]
    
    # Check for --overwrite-tools flag
    overwrite_tools = '--overwrite-tools' in sys.argv
    
    # Get output file (skip if it's the flag)
    output_file = None
    if len(sys.argv) > 3 and sys.argv[3] != '--overwrite-tools':
        output_file = sys.argv[3]
    
    try:
        was_overwritten = merge_pyproject_toml(existing_file, template_file, output_file, overwrite_tools)
        print(f"✓ Successfully merged pyproject.toml configurations")
        if Path(existing_file).exists():
            print(f"  - Preserved existing [build-system] and [project] sections")
        if was_overwritten:
            print(f"  - Replaced tool configurations (black, mypy, etc.) with template versions")
            print(f"  - Selectively merged pytest: preserved project-specific settings, standardized format")
            print(f"  - Preserved other custom tools (hatch, poetry, etc.)")
        else:
            print(f"  - Preserved existing tool configurations")
            print(f"  - Added missing tool configurations from template")
    except Exception as e:
        print(f"✗ Error merging pyproject.toml: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()