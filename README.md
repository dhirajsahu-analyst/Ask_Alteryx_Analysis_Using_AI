# Ask Alteryx Analysis using AI

This repository is the holistic, AI-powered command center for Ask Alteryx (Copilot) Data & Analytics. It houses the complete semantic layer definitions, executable Python connectors for Snowflake and Alteryx Server Gallery, automated metrics testing suites, and specialized AI Agents to interface with the data.

## 🧠 Core Philosophy
This repo is built for **AI-Native Interaction & Zero-Setup Self-Serve Analytics**. Ask the integrated `ask-alteryx-master` agent or the interactive Python console anything about Copilot usage, and it will autonomously use the Python skills and SQL queries stored here to provide validated, ground-truth analytics.

## 🚀 Cloning & Instant Setup Guide

### 1. Clone the Repository Natively
To get started, clone this repository directly to your local desktop:
```bash
git clone https://github.com/dhirajsahu-analyst/Ask_Alteryx_Analysis_Using_AI.git
cd Ask_Alteryx_Analysis_Using_AI
```

### 2. Configure Your Snowflake Connection
Copy the `.env.example` file to `.env` and fill in your Snowflake credentials:
```bash
cp .env.example .env
```
Open the `.env` file in your favorite text editor and input your PROD credentials:
```bash
SNOWFLAKE_USER="your_email@alteryx.com"
SNOWFLAKE_ACCOUNT="your_account_identifier"
SNOWFLAKE_WAREHOUSE="DISCOVERY_PRODUCT_MANAGEMENT_WH"
SNOWFLAKE_DATABASE="DISCOVERY_PRODUCT_MANAGEMENT"
SNOWFLAKE_SCHEMA="METRIC_STORE"
SNOWFLAKE_ROLE="PROD_DATA_SCIENTIST_RL"
SNOWFLAKE_AUTHENTICATOR="externalbrowser"
```

### 3. Install Package Dependencies
Install the standard required libraries using pip:
```bash
pip3 install -r requirements.txt
```

---

## 💬 How to Query the System (The AI Console)

Once connected, anyone can ask natural language questions directly inside their terminal. The AI console automatically routes, executes, secures, and QAs the metrics in sub-seconds:

### Example 1: Querying Monthly Active Users (MAU)
```bash
python3 scripts/ai_analytics_console.py "What is our monthly active users trend?"
```
*Output:*
```
🟢 Verified Metrics (0% Fan-out & Clean Domain Isolation)
MONTH      | MONTHLY_ACTIVE_USERS | TOTAL_PROMPTS
2026-07-01 | 5194                 | 23739
2026-06-01 | 4866                 | 25715
```

### Example 2: Querying Product Stickiness (DAU/MAU)
```bash
python3 scripts/ai_analytics_console.py "What is our stickiness ratio?"
```

### Example 3: Querying the Metric Onboarding Funnel
```bash
python3 scripts/ai_analytics_console.py "Show me the user onboarding funnel"
```

---

## 📂 Repository Structure
*   `agents/`: Contains the configuration for the "God Agent" (`ask-alteryx-master.md`).
*   `skills/`: Hybrid executable skills (Python + SQL) used by the AI to interact with the database.
*   `docs/`: Data dictionaries, legacy anti-patterns, and architectural playbooks.
*   `queries/`: Core SQL files defining the L1, L2, L3 semantic views and Snowflake-hosted snapshots.
*   `scripts/`: Python connection scripts and the interactive CLI console.
*   `tests/`: Automated validation suite ensuring 0% metric fan-out and 100% data integrity.
*   `visuals/`: ERDs and high-fidelity HTML/Mermaid lineage diagrams.

## 🛡️ Governance & Security Built-In
*   **Strict Read-Only:** The SQL compiler blocks any queries containing `DROP`, `DELETE`, `INSERT`, `UPDATE`, `ALTER`, or `TRUNCATE` before they are even sent to Snowflake.
*   **Active QA Scans:** The data output is automatically scanned for internal test domains (`@alteryx.com` or `@aleeas.com`) or null-value key drops. If a leak is found, the system attaches a high-visibility `⚠️ Unverified Metrics` warning, ensuring total metric safety.
