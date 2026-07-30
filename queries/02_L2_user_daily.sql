-- Layer 2: User Daily Aggregated View
-- Grain: 1 Row per User × Day
-- Purpose: Deduplicates active metrics using COUNT(DISTINCT) over the granular L1 View.

CREATE OR REPLACE VIEW DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_DAILY AS
WITH daily AS (
    SELECT
        ACTIVITY_DATE, -- The specific calendar day when the active Copilot telemetry log occurred.
        MONTH_START_DATE, -- First day of the calendar month corresponding to the activity date.
        USER_EMAIL, -- The standardized, lowercase email address of the active user.
        MAX(USER_ID_RAW) AS USER_ID_RAW, -- The primary unique numeric identifier of the user.
        MAX(FINAL_ACCOUNT_CID) AS FINAL_ACCOUNT_CID, -- Unified account match key waterfall used to join Salesforce dimensions.
        MAX(BILLING_ACCOUNT_ID_RAW) AS BILLING_ACCOUNT_ID_RAW, -- The raw, decoded billing account ID representing AlteryxOne on-premise accounts.
        MAX(BILLING_ACCOUNT_ID) AS BILLING_ACCOUNT_ID, -- The base64-encoded AlteryxOne billing account ID.
        MAX(ACCOUNT_EDITION) AS ACCOUNT_EDITION, -- The contract edition assigned to the user's account (e.g., Professional, Enterprise).
        MAX(SFDC_ACCOUNT_ID) AS SFDC_ACCOUNT_ID, -- The 15-character master Salesforce Account ID.
        MAX(ACCOUNT_CID) AS ACCOUNT_CID, -- The Customer ID (CID) hash matching the Salesforce Account.
        MAX(BILLING_ACCOUNT_NAME) AS BILLING_ACCOUNT_NAME, -- The master Billing Customer Name associated with the user's profile.
        MAX(LICENSE_TYPE) AS LICENSE_TYPE, -- The normalized license type (e.g., Purchase, Trial, Evaluation) with synonyms resolved.
        MAX(PRICING_AND_PACKAGING) AS PRICING_AND_PACKAGING, -- The contract pricing model and packaging tier assigned to the profile.
        MAX(MAX_USER_VERSION_OBSERVED) AS MAX_USER_VERSION_OBSERVED, -- The highest observed software version of the active user mapped from PRODUCT_VERSION_ADOPTION.
        MAX(PIPELINE_REGION) AS PIPELINE_REGION, -- The endpoint pipeline execution deployment region (e.g., US, EU, AU).
        MAX(STATUS) AS STATUS, -- The activation state of the user's profile inside the daily users snapshot database.
        MAX(COPILOT_ENABLED) AS COPILOT_ENABLED, -- Boolean flag indicating whether the Copilot feature is actively enabled on the user's account.
        
        -- Deduplicated metric aggregations
        COUNT(DISTINCT CONVERSATION_ID) AS CONVERSATIONS, -- The count of distinct successful conversation session threads created by the user on this day.
        COUNT(DISTINCT CASE WHEN CHAT_ID IS NOT NULL THEN CONVERSATION_ID END) AS CHAT_CONVERSATIONS, -- The count of distinct conversation threads that contain at least 1 successful prompt.
        COUNT(DISTINCT CHAT_ID) AS CHATS, -- The total number of successful queries/prompts typed by the user on this day.
        COUNT(DISTINCT METRIC_ID) AS METRICS, -- The total count of distinct metric interactions compiled on this day.
        COUNT(DISTINCT WORKFLOW_ID) AS WORKFLOWS_TOUCHED, -- The total count of distinct Alteryx workflows created or modified by the user using Copilot on this day.
        
        -- Boolean indicators
        MAX(IFF(USER_WITH_CONVERSATION, 1, 0)) AS HAD_CONVERSATION, -- Integer flag indicating whether the user initiated a valid conversation thread on this day (1 = Yes, 0 = No).
        MAX(IFF(USER_WITH_CHAT, 1, 0)) AS HAD_CHAT, -- Integer flag indicating whether the user successfully executed a prompt on this day.
        MAX(IFF(USER_WITH_METRIC, 1, 0)) AS HAD_METRIC, -- Integer flag indicating whether the user generated metrics logs on this day.
        MAX(IFF(USER_WITH_WORKFLOW, 1, 0)) AS HAD_WORKFLOW -- Integer flag indicating whether the user successfully generated/touched a workflow on this day.
    FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
    GROUP BY 1, 2, 3
)
SELECT
    daily.*,
    ROUND(CHATS / NULLIF(CONVERSATIONS, 0), 2) AS CHATS_PER_CONVERSATION -- The average number of successful prompts typed per conversation session thread on this day.
FROM daily;