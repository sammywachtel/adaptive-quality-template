#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🚀 Alternative PyCharm Template Setup"
echo "=================================="
echo ""

print_status "Since PyCharm 2025+ has changed template system, here are working alternatives:"
echo ""

echo -e "${BLUE}Option 1: File Template (Recommended)${NC}"
echo "1. Open PyCharm"
echo "2. Go to Preferences/Settings → Editor → File and Code Templates"
echo "3. Click + to add new template"
echo "4. Name: 'Standardized Project Setup'"
echo "5. Extension: 'sh'"
echo "6. Add this content to run our setup:"
echo ""
echo "#!/bin/bash"
echo "# Run standardized project setup"
echo "~/PycharmTemplates/fullstack/setup-new-project.sh"
echo ""

echo -e "${BLUE}Option 2: External Tools (Best for Workflow)${NC}"
echo "1. Go to PyCharm Preferences → Tools → External Tools"
echo "2. Click + to add new tool:"
echo "   - Name: 'Setup Standardized Project'"
echo "   - Description: 'Apply standardized CI/CD configuration'"
echo "   - Program: '$HOME/PycharmTemplates/fullstack/setup-new-project.sh'"
echo "   - Working Directory: '\$ProjectFileDir\$'"
echo "3. Now you can right-click any project → External Tools → Setup Standardized Project"
echo ""

echo -e "${BLUE}Option 3: Quick Command Line${NC}"
echo "Create an alias in your ~/.zshrc or ~/.bashrc:"
echo "alias pycharm-setup='~/PycharmTemplates/fullstack/setup-new-project.sh'"
echo ""
echo "Then from any project directory, just run: pycharm-setup"
echo ""

echo -e "${BLUE}Option 4: Use Command Line Project Creation${NC}"
echo "# Create new project"
echo "~/PycharmTemplates/fullstack/create-standardized-project.sh my-new-app"
echo "# Then open in PyCharm"
echo ""

print_success "Choose the option that works best for your workflow!"
print_status "Option 2 (External Tools) is recommended for seamless PyCharm integration"