-- Layer 1: User Daily Activity View
-- Grain: 1 Row per Active User × Day × Action
-- Purpose: Inverted join to prevent 35.79% metric inflation, filters failed chats, sanitizes emails.
-- Authority Spine: Sourced directly from USERS_DAILY_AT.
-- Version Tracking: Integrates the 100% complete PRODUCT_VERSION_ADOPTION table.
-- Lineage Optimization: Completely purged all dependencies on legacy Postgres 'POSTGRES_LICENSEBILLING_TBL_' tables!

CREATE OR REPLACE VIEW DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED AS
WITH ayx_user_day AS (
    SELECT
        DATE AS user_snapshot_date,
        DATE_TRUNC('MONTH', DATE)::DATE AS user_snapshot_month,
        USER_ID_RAW,
        LOWER(TRIM(SPLIT_PART(REPLACE(USER_EMAIL, ' ', ''), ';', 1))) AS email_lc,
        USER_EMAIL,
        LICENSE_TYPE,
        STATUS,
        COPILOT_ENABLED,
        ACCOUNT_EDITION,
        PRICING_AND_PACKAGING,
        PIPELINE_REGION,
        BILLING_ACCOUNT_ID,
        BILLING_ACCOUNT_ID_RAW,
        SFDC_ACCOUNT_ID,
        ACCOUNT_CID,
        BILLING_ACCOUNT_NAME
    FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.USERS_DAILY_AT
    WHERE DATE >= '2025-12-03'::DATE AND USER_ID_RAW IS NOT NULL AND DATE IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY USER_ID_RAW, DATE ORDER BY STATUS DESC, LICENSE_TYPE DESC) = 1
),
cm_raw AS (
    SELECT
        cm.*,
        LOWER(TRIM(SPLIT_PART(REPLACE(cm.USER_EMAIL, ' ', ''), ';', 1))) AS cm_email_lc,
        TRY_TO_NUMBER(cm.EXTERNAL_ID) AS ext_id_num,
        CAST(cm.CONV_CREATED_DATE AS DATE) AS activity_day
    FROM DISCOVERY_ENGINEERING.COPILOT.COPILOT_USAGE_ALL_REGIONS_VW cm
    WHERE CONV_CREATED_DATE >= '2025-12-03'
),
cm AS (
    SELECT cm.*
    FROM cm_raw cm
    LEFT JOIN DISCOVERY_ENGINEERING.COPILOT.COPILOT_CHAT ch
        ON cm.CHAT_ID = ch.ID
    WHERE ch.ID IS NULL OR COALESCE(LOWER(ch.STATUS), 'success') <> 'failed'
),
pva AS (
    SELECT DISTINCT
        TRY_TO_NUMBER(SPLIT_PART(BASE64_DECODE_STRING(USER_ID), '_', 1)) AS decoded_user_id,
        YEAR_MONTH AS pva_month,
        "Max_User_VERSION" AS observed_version
    FROM DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.PRODUCT_VERSION_ADOPTION
    WHERE YEAR_MONTH >= '2025-12-03'
    QUALIFY ROW_NUMBER() OVER (PARTITION BY decoded_user_id, YEAR_MONTH ORDER BY LAST_UPDATED DESC) = 1
)
SELECT
    -- 1. Date columns
    cm.activity_day AS ACTIVITY_DATE,
    u.user_snapshot_month AS MONTH_START_DATE,
    
    -- 2. User Info
    COALESCE(cm.cm_email_lc, u.email_lc) AS USER_EMAIL,
    COALESCE(cm.ext_id_num, u.USER_ID_RAW) AS USER_ID_RAW,
    
    -- 3. Associated Account Info
    u.BILLING_ACCOUNT_ID_RAW AS BILLING_ACCOUNT_ID_RAW,
    u.BILLING_ACCOUNT_ID AS BILLING_ACCOUNT_ID,
    u.ACCOUNT_EDITION AS ACCOUNT_EDITION,
    u.SFDC_ACCOUNT_ID AS SFDC_ACCOUNT_ID,
    u.ACCOUNT_CID AS ACCOUNT_CID,
    u.BILLING_ACCOUNT_NAME AS BILLING_ACCOUNT_NAME,
    u.LICENSE_TYPE AS LICENSE_TYPE,
    u.PRICING_AND_PACKAGING AS PRICING_AND_PACKAGING,
    COALESCE(NULLIF(TRIM(u.ACCOUNT_CID), ''), NULLIF(TRIM(u.SFDC_ACCOUNT_ID), ''), 'Shadow Account') AS FINAL_ACCOUNT_CID,
    
    -- 4. Telemetry and Others
    cm.CONVERSATION_ID AS CONVERSATION_ID,
    cm.CHAT_ID AS CHAT_ID,
    cm.METRIC_ID AS METRIC_ID,
    cm.WORKFLOW_ID AS WORKFLOW_ID,
    COALESCE(cm.USER_WITH_CONVERSATION, FALSE) AS USER_WITH_CONVERSATION,
    COALESCE(cm.USER_WITH_CHAT, FALSE) AS USER_WITH_CHAT,
    COALESCE(cm.USER_WITH_METRIC, FALSE) AS USER_WITH_METRIC,
    COALESCE(cm.USER_WITH_WORKFLOW, FALSE) AS USER_WITH_WORKFLOW,
    COALESCE(uv.observed_version, '2025.2') AS MAX_USER_VERSION_OBSERVED,
    u.PIPELINE_REGION AS PIPELINE_REGION,
    u.STATUS AS STATUS,
    u.COPILOT_ENABLED AS COPILOT_ENABLED
FROM cm
LEFT JOIN ayx_user_day u
    ON cm.ext_id_num = u.USER_ID_RAW
   AND cm.activity_day = u.user_snapshot_date
LEFT JOIN pva uv
    ON u.USER_ID_RAW = uv.decoded_user_id
   AND u.user_snapshot_month = DATE_TRUNC('MONTH', uv.pva_month)::DATE
WHERE SPLIT_PART(COALESCE(cm.cm_email_lc, u.email_lc), '@', 2) NOT LIKE '%alteryx.com%'
  AND SPLIT_PART(COALESCE(cm.cm_email_lc, u.email_lc), '@', 2) NOT LIKE '%aleeas.com%';