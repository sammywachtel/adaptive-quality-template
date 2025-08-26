#!/usr/bin/env python3
"""
Simple template processor for GitHub Actions workflows.
Removes Handlebars-style conditional blocks based on current phase and project structure.
"""

import sys
import re
import yaml
from pathlib import Path

def read_quality_config():
    """Read the current phase and project settings from .quality-config.yaml"""
    config_file = Path('.quality-config.yaml')
    if not config_file.exists():
        return {'current_phase': 0, 'has_frontend': False, 'has_backend': True}
    
    try:
        with open(config_file) as f:
            config = yaml.safe_load(f)
        current_phase = config.get('quality_gates', {}).get('current_phase', 0)
        
        # Determine frontend/backend based on project structure
        has_frontend = Path('frontend').exists() or Path('src').exists()
        has_backend = Path('backend').exists() or Path('requirements.txt').exists() or Path('pyproject.toml').exists()
        
        return {
            'current_phase': current_phase,
            'has_frontend': has_frontend,
            'has_backend': has_backend
        }
    except Exception:
        return {'current_phase': 0, 'has_frontend': False, 'has_backend': True}

def process_template(template_content, config):
    """Process template content by removing/keeping conditional blocks"""
    current_phase = config['current_phase']
    has_frontend = config['has_frontend']
    has_backend = config['has_backend']
    
    # Process frontend/backend conditionals
    if has_frontend:
        # Keep frontend blocks
        template_content = re.sub(r'{{#IF_HAS_FRONTEND}}\n?', '', template_content)
        template_content = re.sub(r'{{/IF_HAS_FRONTEND}}\n?', '', template_content)
        template_content = re.sub(r'{{#IF_HAS_FRONTEND}}', '', template_content)
        template_content = re.sub(r'{{/IF_HAS_FRONTEND}}', '', template_content)
    else:
        # Remove frontend blocks
        template_content = re.sub(r'{{#IF_HAS_FRONTEND}}.*?{{/IF_HAS_FRONTEND}}\n?', '', template_content, flags=re.DOTALL)
    
    if has_backend:
        # Keep backend blocks
        template_content = re.sub(r'{{#IF_HAS_BACKEND}}\n?', '', template_content)
        template_content = re.sub(r'{{/IF_HAS_BACKEND}}\n?', '', template_content)
        template_content = re.sub(r'{{#IF_HAS_BACKEND}}', '', template_content)
        template_content = re.sub(r'{{/IF_HAS_BACKEND}}', '', template_content)
    else:
        # Remove backend blocks
        template_content = re.sub(r'{{#IF_HAS_BACKEND}}.*?{{/IF_HAS_BACKEND}}\n?', '', template_content, flags=re.DOTALL)
    
    # Process phase conditionals
    phases_to_keep = []
    if current_phase == 0:
        phases_to_keep = ['PHASE_0']
    elif current_phase == 1:
        phases_to_keep = ['PHASE_1', 'PHASE_1_OR_HIGHER']
    elif current_phase == 2:
        phases_to_keep = ['PHASE_2', 'PHASE_1_OR_HIGHER', 'PHASE_2_OR_HIGHER']
    elif current_phase >= 3:
        phases_to_keep = ['PHASE_3', 'PHASE_1_OR_HIGHER', 'PHASE_2_OR_HIGHER']
    
    # Remove all phase blocks first
    all_phases = ['PHASE_0', 'PHASE_1', 'PHASE_2', 'PHASE_3', 'PHASE_1_OR_HIGHER', 'PHASE_2_OR_HIGHER']
    for phase in all_phases:
        if phase in phases_to_keep:
            # Keep these blocks by removing the conditional markers
            template_content = re.sub(f'{{{{#IF_{phase}}}}}\\n?', '', template_content)
            template_content = re.sub(f'{{{{/IF_{phase}}}}}\\n?', '', template_content)
            template_content = re.sub(f'{{{{#IF_{phase}}}}}', '', template_content)
            template_content = re.sub(f'{{{{/IF_{phase}}}}}', '', template_content)
        else:
            # Remove these blocks entirely
            template_content = re.sub(f'{{{{#IF_{phase}}}}}.*?{{{{/IF_{phase}}}}}\\n?', '', template_content, flags=re.DOTALL)
    
    return template_content

def main():
    if len(sys.argv) != 3:
        print("Usage: process-workflow-template.py <input_template> <output_file>")
        sys.exit(1)
    
    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2])
    
    if not input_file.exists():
        print(f"Error: Template file {input_file} not found")
        sys.exit(1)
    
    # Read configuration
    config = read_quality_config()
    
    # Read and process template
    with open(input_file) as f:
        template_content = f.read()
    
    processed_content = process_template(template_content, config)
    
    # Write output
    output_file.parent.mkdir(parents=True, exist_ok=True)
    with open(output_file, 'w') as f:
        f.write(processed_content)
    
    print(f"Processed template: {input_file} -> {output_file}")
    print(f"Phase: {config['current_phase']}, Frontend: {config['has_frontend']}, Backend: {config['has_backend']}")

if __name__ == '__main__':
    main()