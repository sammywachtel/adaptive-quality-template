#!/bin/bash
# detect-mypy-deps.sh
# Intelligently detects MyPy additional_dependencies from requirements files
# Usage: ./detect-mypy-deps.sh [requirements-file]

set -eo pipefail

# Opening move: find the requirements files
REQUIREMENTS_FILES=()

if [[ -n "${1:-}" && -f "$1" ]]; then
    # Explicit file provided
    REQUIREMENTS_FILES+=("$1")
    # Also check for -dev variant in same directory
    DEV_FILE="${1%.txt}-dev.txt"
    [[ -f "$DEV_FILE" ]] && REQUIREMENTS_FILES+=("$DEV_FILE")
else
    # Auto-detect common locations
    for base in requirements backend/requirements requirements/base; do
        [[ -f "${base}.txt" ]] && REQUIREMENTS_FILES+=("${base}.txt")
        [[ -f "${base}-dev.txt" ]] && REQUIREMENTS_FILES+=("${base}-dev.txt")
    done
fi

if [[ ${#REQUIREMENTS_FILES[@]} -eq 0 ]]; then
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
# MyPy needs these packages installed to properly type-check code that imports them
is_direct_dep() {
    local pkg="$1"
    case "$pkg" in
        # Scientific packages
        numpy|scikit-learn|pandas|scipy) echo "$pkg" ;;
        # Web frameworks (needed for type checking)
        pydantic|pydantic-settings) echo "$pkg" ;;
        fastapi|starlette|uvicorn) echo "$pkg" ;;
        # HTTP clients
        httpx) echo "$pkg" ;;
        # Configuration and environment
        python-dotenv) echo "$pkg" ;;
        # AI/ML SDKs
        openai) echo "$pkg" ;;
        # Testing frameworks
        pytest) echo "$pkg" ;;
        # NLP packages (commonly used, MyPy needs them for imports)
        spacy|g2p-en|pronouncing) echo "$pkg" ;;
        *) echo "" ;;
    esac
}

# Here's where we scan the requirements files for type stub candidates
for REQUIREMENTS_FILE in "${REQUIREMENTS_FILES[@]}"; do
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
done

# Victory lap: deduplicate and output JSON array format
if [[ ${#MYPY_DEPS[@]} -eq 0 ]]; then
    echo "[]"
else
    # Deduplicate using sort and uniq
    UNIQUE_DEPS=($(printf '%s\n' "${MYPY_DEPS[@]}" | sort -u))

    # Use jq if available, otherwise fallback to manual JSON construction
    if command -v jq >/dev/null 2>&1; then
        printf '%s\n' "${UNIQUE_DEPS[@]}" | jq -R . | jq -s .
    else
        # Manual JSON array construction
        echo -n "["
        for i in "${!UNIQUE_DEPS[@]}"; do
            echo -n "\"${UNIQUE_DEPS[$i]}\""
            if [[ $i -lt $((${#UNIQUE_DEPS[@]} - 1)) ]]; then
                echo -n ", "
            fi
        done
        echo "]"
    fi
fi
