# Copilot Metrics Dictionary

This document defines the official logic for all Ask Alteryx (Copilot) product metrics, acting as the single source of truth for downstream Tableau dashboards and Python scripts.

## 👥 User Level Metrics
*   **Active User:** A user who has successfully executed at least 1 prompt (Chat) inside Copilot. Users whose chats all resulted in `STATUS = 'failed'` are strictly excluded.
*   **Engaged User:** A power user who has successfully participated in `>= 5` distinct conversation sessions.
*   **Workflow Developer:** A user who has successfully created or touched at least 1 workflow using the Copilot panel.
*   **DAU (Daily Active User):** The distinct count of Active Users on a specific calendar day.
*   **MAU (Monthly Active User):** The distinct count of Active Users within a calendar month boundary.
*   **Stickiness:** The ratio of `Average DAU / MAU` for a given month.

## 🏢 Account Level Metrics
*   **Active Account:** A Salesforce Account that contains at least 1 Active User during the reporting month.
*   **ACV Match Rate:** The percentage of active telemetry sessions that can be successfully joined to a positive Salesforce Cloud ACV value.

## 🧮 Symmetrical Funnel Definitions
*   **Stage 1 - Onboarded:** All activated, Copilot-enabled profiles on the platform.
*   **Stage 2 - Active:** Profiles with `CHATS > 0`.
*   **Stage 3 - Workflow Dev:** Profiles with `WORKFLOWS_TOUCHED > 0`.
*   **Stage 4 - Engaged:** Profiles with `CONVERSATIONS > 0` (or `> 5` for power-user funnels).