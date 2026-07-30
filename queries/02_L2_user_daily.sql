-- Layer 2: User Daily Aggregated View
-- Grain: 1 Row per User × Day
-- Purpose: Deduplicates active metrics using COUNT(DISTINCT) over the granular L1 View.
-- Column Comments: Strictly compiled inside Snowflake using native metadata comments.

CREATE OR REPLACE VIEW DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_DAILY(
    ACTIVITY_DATE COMMENT 'The specific calendar day when the active Copilot telemetry log occurred.',
    MONTH_START_DATE COMMENT 'First day of the calendar month corresponding to the activity date.',
    USER_EMAIL COMMENT 'The standardized, lowercase email address of the active user.',
    USER_ID_RAW COMMENT 'The primary unique numeric identifier of the user.',
    FINAL_ACCOUNT_CID COMMENT 'Unified account match key waterfall used to join Salesforce dimensions.',
    BILLING_ACCOUNT_ID_RAW COMMENT 'The raw, decoded billing account ID representing AlteryxOne on-premise accounts.',
    BILLING_ACCOUNT_ID COMMENT 'The base64-encoded AlteryxOne billing account ID.',
    ACCOUNT_EDITION COMMENT 'The contract edition assigned to the user account (e.g., Professional, Enterprise).',
    SFDC_ACCOUNT_ID COMMENT 'The 15-character master Salesforce Account ID.',
    ACCOUNT_CID COMMENT 'The Customer ID (CID) hash matching the Salesforce Account.',
    BILLING_ACCOUNT_NAME COMMENT 'The master Billing Customer Name associated with the user profile.',
    LICENSE_TYPE COMMENT 'The normalized license type (e.g., Purchase, Trial, Evaluation) with synonyms resolved.',
    PRICING_AND_PACKAGING COMMENT 'The contract pricing model and packaging tier assigned to the profile.',
    MAX_USER_VERSION_OBSERVED COMMENT 'The highest observed software version of the active user mapped from PRODUCT_VERSION_ADOPTION.',
    PIPELINE_REGION COMMENT 'The endpoint pipeline execution deployment region (e.g., US, EU, AU).',
    STATUS COMMENT 'The activation state of the user profile inside the daily users snapshot database.',
    COPILOT_ENABLED COMMENT 'Boolean flag indicating whether the Copilot feature is actively enabled on the user account.',
    CONVERSATIONS COMMENT 'The count of distinct successful conversation session threads created by the user on this day.',
    CHAT_CONVERSATIONS COMMENT 'The count of distinct conversation threads that contain at least 1 successful prompt.',
    CHATS COMMENT 'The total number of successful queries/prompts typed by the user on this day.',
    METRICS COMMENT 'The total count of distinct metric interactions compiled on this day.',
    WORKFLOWS_TOUCHED COMMENT 'The total count of distinct Alteryx workflows created or modified by the user using Copilot on this day.',
    HAD_CONVERSATION COMMENT 'Integer flag indicating whether the user initiated a valid conversation thread on this day (1 = Yes, 0 = No).',
    HAD_CHAT COMMENT 'Integer flag indicating whether the user successfully executed a prompt on this day.',
    HAD_METRIC COMMENT 'Integer flag indicating whether the user generated metrics logs on this day.',
    HAD_WORKFLOW COMMENT 'Integer flag indicating whether the user successfully generated/touched a workflow on this day.',
    CHATS_PER_CONVERSATION COMMENT 'The average number of successful prompts typed per conversation session thread on this day.'
) AS
WITH daily AS (
    SELECT
        ACTIVITY_DATE,
        MONTH_START_DATE,
        USER_EMAIL,
        MAX(USER_ID_RAW) AS USER_ID_RAW,
        MAX(FINAL_ACCOUNT_CID) AS FINAL_ACCOUNT_CID,
        MAX(BILLING_ACCOUNT_ID_RAW) AS BILLING_ACCOUNT_ID_RAW,
        MAX(BILLING_ACCOUNT_ID) AS BILLING_ACCOUNT_ID,
        MAX(ACCOUNT_EDITION) AS ACCOUNT_EDITION,
        MAX(SFDC_ACCOUNT_ID) AS SFDC_ACCOUNT_ID,
        MAX(ACCOUNT_CID) AS ACCOUNT_CID,
        MAX(BILLING_ACCOUNT_NAME) AS BILLING_ACCOUNT_NAME,
        MAX(LICENSE_TYPE) AS LICENSE_TYPE,
        MAX(PRICING_AND_PACKAGING) AS PRICING_AND_PACKAGING,
        MAX(MAX_USER_VERSION_OBSERVED) AS MAX_USER_VERSION_OBSERVED,
        MAX(PIPELINE_REGION) AS PIPELINE_REGION,
        MAX(STATUS) AS STATUS,
        MAX(COPILOT_ENABLED) AS COPILOT_ENABLED,
        
        -- Deduplicated metric aggregations
        COUNT(DISTINCT CONVERSATION_ID) AS CONVERSATIONS,
        COUNT(DISTINCT CASE WHEN CHAT_ID IS NOT NULL THEN CONVERSATION_ID END) AS CHAT_CONVERSATIONS,
        COUNT(DISTINCT CHAT_ID) AS CHATS,
        COUNT(DISTINCT METRIC_ID) AS METRICS,
        COUNT(DISTINCT WORKFLOW_ID) AS WORKFLOWS_TOUCHED,
        
        -- Boolean indicators
        MAX(IFF(USER_WITH_CONVERSATION, 1, 0)) AS HAD_CONVERSATION,
        MAX(IFF(USER_WITH_CHAT, 1, 0)) AS HAD_CHAT,
        MAX(IFF(USER_WITH_METRIC, 1, 0)) AS HAD_METRIC,
        MAX(IFF(USER_WITH_WORKFLOW, 1, 0)) AS HAD_WORKFLOW
    FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
    GROUP BY 1, 2, 3
)
SELECT
    daily.*,
    ROUND(CHATS / NULLIF(CONVERSATIONS, 0), 2)
FROM daily;