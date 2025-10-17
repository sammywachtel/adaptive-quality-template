#!/bin/bash
# detect-mypy-deps.sh
# Intelligently detects MyPy additional_dependencies from requirements files
# Usage: ./detect-mypy-deps.sh [requirements-file]

set -eo pipefail

# Opening move: find the requirements file
REQUIREMENTS_FILE="${1:-}"
if [[ -z "$REQUIREMENTS_FILE" ]]; then
    # Check common locations
    for file in requirements.txt backend/requirements.txt requirements/base.txt; do
        if [[ -f "$file" ]]; then
            REQUIREMENTS_FILE="$file"
            break
        fi
    done
fi

if [[ -z "$REQUIREMENTS_FILE" || ! -f "$REQUIREMENTS_FILE" ]]; then
    echo "[]"  # No dependencies found
    exit 0
fi

# Main play: extract packages that need type stubs or are direct dependencies
declare -a MYPY_DEPS=()

# Function to check if package needs type stub
needs_type_stub() {
    local pkg="$1"
    case "$pkg" in
        requests) echo "types-requests" ;;
        redis) echo "types-redis" ;;
        pyyaml) echo "types-pyyaml" ;;
        jsonschema) echo "types-jsonschema" ;;
        setuptools) echo "types-setuptools" ;;
        *) echo "" ;;
    esac
}

# Function to check if package is a direct MyPy dependency
is_direct_dep() {
    local pkg="$1"
    case "$pkg" in
        numpy|scikit-learn|pandas|scipy) echo "$pkg" ;;
        *) echo "" ;;
    esac
}

# Here's where we scan the requirements file for type stub candidates
while IFS= read -r line; do
    # Strip comments and whitespace
    line=$(echo "$line" | sed 's/#.*//' | tr -d ' \t')

    # Skip empty lines
    [[ -z "$line" ]] && continue

    # Extract package name (before ==, >=, etc.) and normalize to lowercase
    pkg=$(echo "$line" | sed -E 's/([a-zA-Z0-9_-]+).*/\1/' | tr '[:upper:]' '[:lower:]')

    # Check if it needs a type stub
    stub=$(needs_type_stub "$pkg")
    if [[ -n "$stub" ]]; then
        MYPY_DEPS+=("$stub")
    fi

    # Check if it's a direct dependency MyPy needs
    direct=$(is_direct_dep "$pkg")
    if [[ -n "$direct" ]]; then
        MYPY_DEPS+=("$direct")
    fi
done < "$REQUIREMENTS_FILE"

# Victory lap: output JSON array format for easy parsing
if [[ ${#MYPY_DEPS[@]} -eq 0 ]]; then
    echo "[]"
else
    # Use jq if available, otherwise fallback to manual JSON construction
    if command -v jq >/dev/null 2>&1; then
        printf '%s\n' "${MYPY_DEPS[@]}" | jq -R . | jq -s .
    else
        # Manual JSON array construction
        echo -n "["
        for i in "${!MYPY_DEPS[@]}"; do
            echo -n "\"${MYPY_DEPS[$i]}\""
            if [[ $i -lt $((${#MYPY_DEPS[@]} - 1)) ]]; then
                echo -n ", "
            fi
        done
        echo "]"
    fi
fi
