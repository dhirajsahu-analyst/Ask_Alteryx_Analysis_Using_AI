# Ask Alteryx Analysis using AI

This repository is the holistic, AI-powered command center for Ask Alteryx (Copilot) Data & Analytics. It houses the complete semantic layer definitions, executable Python connectors for Snowflake and Alteryx Server Gallery, automated metrics testing suites, and specialized AI Agents to interface with the data.

## 🧠 Core Philosophy
This repo is built for **AI-Native Interaction**. Ask the integrated `ask-alteryx-master` agent anything about Copilot usage, and it will autonomously use the Python skills and SQL queries stored here to provide validated, ground-truth analytics.

## 📂 Repository Structure
*   `agents/`: Contains the configuration for the "God Agent" (`ask-alteryx-master.md`).
*   `skills/`: Hybrid executable skills (Python + SQL) used by the AI to interact with the database.
*   `docs/`: Data dictionaries, legacy anti-patterns, and architectural decision records (ADRs).
*   `queries/`: Core SQL files defining the L1, L2, and L3 semantic views and Snowflake-hosted snapshots.
*   `scripts/`: Python connection scripts for Snowflake and the Alteryx Gallery API.
*   `tests/`: Automated validation suite ensuring 0% metric fan-out and 100% data integrity.
*   `visuals/`: ERDs and high-fidelity HTML/Mermaid lineage diagrams.

## 🚀 Quickstart
1. Clone the repository.
2. Copy `.env.example` to `.env` and fill in your Snowflake SSO credentials.
3. Install requirements: `pip install -r requirements.txt`.
4. Load the agent in Gemini CLI and ask any data question.