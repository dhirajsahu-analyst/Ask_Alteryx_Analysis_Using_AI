# Principal Product Analyst Playbook: Ask Alteryx (Copilot)

This document provides specialized, executive-ready diagnostic playbooks to analyze user behavior, retention funnels, and performance bottlenecks inside Ask Alteryx (Copilot).

---

## 🎯 1. The Onboarding Activation Funnel (Moving 1-to-5)
Your core growth lever is the **"Move 1-to-5"** strategy. 

*   **The Problem (85% Churn):** Analysis proves that 85% of active users are "One-Session Wonders"—they type exactly 1 prompt and bounce.
*   **The Opportunity:** Once a user crosses the **5-conversation threshold**, their workflow creation activation rate shoots up to **91%**.
*   **The Diagnostic:**
    *   Query the daily aggregations (`SEM_COPILOT_USER_DAILY`) and isolate users with `conversations BETWEEN 1 AND 4`.
    *   Analyze their prompt topics (using prompt text logs) to identify where they hit friction or unhelpful responses.
*   **The Recommendation:** Deliver guided next-step prompts inside the UI when the user is on their 2nd or 3rd conversation to bridge them into the high-value 5-conversation "Power User" cohort.

---

## 💻 2. Version-Level Friction Analysis (UX Audits)
A major friction point was discovered in the transition from **Version 2025.2** to **Version 2026.1**:

*   **Version 2025.2:** Engagement depth was high (**8.7 prompts/user**).
*   **Version 2026.1:** Engagement depth collapsed by 61% down to **3.4 prompts/user**.
*   **The Diagnostic:**
    *   This is a classic **UX Friction Event**. When a major release significantly drops engagement density, it indicates that the interface was either hidden, disabled, or made slow.
*   **The Recommendation:** Convene an immediate UX/UI audit for the 2026.1 desktop release. Check panel docking default states, hotkey binds, and API response latencies.

---

## ⚡ 3. Feature Stickiness (DAU / MAU) Benchmark
Feature stickiness for Ask Alteryx stands at **11.07%** (`621.8` average daily users / `5,615` monthly users).

*   **The Benchmark:** For a developer or analyst companion utility, standard IDE copilots target a stickiness of **25% to 35%**. An 11% stickiness means users treat Copilot as an occasional, passive reference search rather than a daily habit-forming companion.
*   **The Action:** Focus product efforts on "re-engagement hooks" inside Alteryx Designer—such as showing small Copilot helper badges next to failed tool executions or configuration errors, prompting them to click and ask Copilot for instant repair.

---

## 💳 4. Trial-to-Paid Subscription Acceleration
*   **The Finding:** Evaluation Trial users are your most highly-engaged segment, averaging **9.9 prompts per user** (nearly double the 5.5 prompts of paid corporate users).
*   **The Action:** Trial users are actively seeking guidance to learn the product. Sales and product teams should highlight Ask Alteryx as a primary enablement feature during pre-sales trials to shorten the sales cycle and accelerate trial-to-paid conversions.