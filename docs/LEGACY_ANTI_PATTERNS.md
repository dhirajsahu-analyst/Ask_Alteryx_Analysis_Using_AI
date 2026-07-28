# Legacy Anti-Patterns & Architecture Decisions

This document explains the historical flaws of the legacy `COPILOT_ACTIVITY_USAGE_AT` pipeline and why the new 3-tier semantic view-stack was built.

## 🚨 The 32.6M Row Cartesian Fan-out
**The Flaw:** The legacy pipeline placed the 21M-row daily user spine on the *left side* of a `LEFT JOIN` against the 178K-row active telemetry table.
**The Impact:** Inflated physical database storage to 32,600,000 rows by writing inactive users every single day.
**The Fix:** **Inverted Joins.** We now use the active event logs (`COPILOT_USAGE_ALL_REGIONS_VW`) as the driving left table, guaranteeing the view stays lean (currently ~180K rows).

## 🚨 The 35.79% Metrics Duplication Leak
**The Flaw:** The upstream identity graph generated duplicate rows for the same user on the same day if they occupied multiple Postgres seats or held concurrent licenses (e.g., Trial and Purchase).
**The Impact:** Joining active logs to this duplicated spine multiplied telemetry records, artificially inflating active metrics by 35.79% (over 117,000 double-counted rows).
**The Fix:** **Spine Deduplication.** We injected `QUALIFY ROW_NUMBER() OVER (PARTITION BY USER_ID_RAW, DATE ORDER BY STATUS DESC, LICENSE_TYPE DESC) = 1` into the L1 CTE.

## 🚨 The 0% Salesforce ACV Match Rate
**The Flaw:** The legacy telemetry keys (`EXTERNAL_ID`) could not join to standard Salesforce IDs, causing the legacy table to drop all CRM tracking.
**The Fix:** **CID-First Waterfall.** The L3 Monthly view now standardizes joins on `COALESCE(ACCOUNT_CID, SFDC_ACCOUNT_ID)`, restoring a 96%+ match rate for Sales Regions and ACV.

## 🚨 Failed Prompt Leakage
**The Flaw:** The legacy system counted any `CHAT_ID` as active engagement, even if the API timed out and the status was `failed`.
**The Fix:** Left-joining `COPILOT_CHAT` and forcing `STATUS <> 'failed'`, cleanly purging over 2,400 failed logs.