#!/bin/bash
# ==============================================================================
# Ask Alteryx Self-Serve One-Click Setup & Run Script
# Platform: macOS / Linux (bash/zsh)
# Purpose: Automatically initializes environments, configures .env credentials,
#          installs dependencies, and launches the web analytics portal.
# ==============================================================================

# Text formatting colors
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

clear
echo -e "${ORANGE}================================================================================"
echo -e "🧠 ASK ALTERYX (COPILOT) SELF-SERVE ANALYTICS PORTAL INITIALIZER"
echo -e "================================================================================${NC}"

# Step 1: Check Python 3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Critical Error: Python 3 is not installed on this machine.${NC}"
    echo "Please install Python 3 from https://www.python.org/downloads/ and try again."
    exit 1
fi

# Step 2: Set up Virtual Environment
echo -e "\n${BLUE}📦 Step 1: Configuring local Python Virtual Environment...${NC}"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
    echo -e "   ${GREEN}✓ Virtual environment (.venv) successfully created.${NC}"
else
    echo -e "   ${GREEN}✓ Virtual environment (.venv) already exists.${NC}"
fi

# Activate Virtual Environment
source .venv/bin/activate

# Step 3: Upgrade pip and Install Dependencies
echo -e "\n${BLUE}📦 Step 2: Upgrading pip and installing required packages...${NC}"
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
echo -e "   ${GREEN}✓ All package dependencies successfully installed.${NC}"

# Step 4: Configure Credentials (.env) Interactively
echo -e "\n${BLUE}🔐 Step 3: Auditing Snowflake SSO Credentials...${NC}"
if [ ! -f ".env" ]; then
    echo -e "   ${ORANGE}⚠️ Notice: No local .env configuration file found.${NC}"
    echo -e "   Copying template from .env.example..."
    cp .env.example .env
    
    echo -e "\n   👉 Please enter your Snowflake SSO Email Address (e.g., chirag.s@alteryx.com):"
    read -r sfdc_email
    
    echo -e "   👉 Please enter your Snowflake Account Identifier (e.g., alteryx_partner):"
    read -r sfdc_account
    
    # Write to .env dynamically
    sed -i '' "s/firstname.lastname@alteryx.com/$sfdc_email/g" .env 2>/dev/null || sed -i "s/firstname.lastname@alteryx.com/$sfdc_email/g" .env
    sed -i '' "s/your_account_identifier/$sfdc_account/g" .env 2>/dev/null || sed -i "s/your_account_identifier/$sfdc_account/g" .env
    
    echo -e "\n   ${GREEN}✓ .env configuration successfully written and secured!${NC}"
else
    echo -e "   ${GREEN}✓ .env credentials already configured and active.${NC}"
fi

# Step 5: Launch the Server & Open Browser
echo -e "\n${ORANGE}================================================================================"
echo -e "🚀 LAUNCHING SELF-SERVE ANALYTICS PORTAL"
echo -e "================================================================================${NC}"
echo "Press CTRL+C inside the terminal at any time to shut down the portal."

# Automatically open browser window based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    (sleep 2 && open "http://127.0.0.1:8080") &
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    (sleep 2 && xdg-open "http://127.0.0.1:8080") &
fi

# Execute HTTP Server
python3 scripts/serve_app.py