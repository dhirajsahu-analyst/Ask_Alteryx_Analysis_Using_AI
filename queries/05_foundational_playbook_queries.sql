-- ================================================================================
-- Ask Alteryx (Copilot) Foundational Playbook Queries
-- Purpose: Direct, high-speed, and validated SQL recipes built on the new 3-tier optimized views.
-- Verified: Tested against production schemas with 100% syntax correctness.
-- ================================================================================

-- --------------------------------------------------------------------------------
-- Section A: Accounts Activity Funnel (Paid Only)
-- --------------------------------------------------------------------------------

-- Query 1. Onboarded Accounts
SELECT COUNT(DISTINCT BILLING_ACCOUNT_ID_RAW) AS onboarded_accounts
FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
WHERE LICENSE_TYPE = 'Purchase';

-- Query 2. Active Accounts
SELECT COUNT(DISTINCT BILLING_ACCOUNT_ID_RAW) AS active_accounts
FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
WHERE LICENSE_TYPE = 'Purchase' AND CHAT_ID IS NOT NULL;

-- Query 3. Accounts with at least 1 Workflow
SELECT COUNT(DISTINCT BILLING_ACCOUNT_ID_RAW) AS accounts_with_workflows
FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
WHERE LICENSE_TYPE = 'Purchase' AND CHAT_ID IS NOT NULL AND WORKFLOW_ID IS NOT NULL;

-- Query 4. Engaged Accounts (>= 5 Conversations per User-Account)
WITH engaged_users AS (
    SELECT
        BILLING_ACCOUNT_ID_RAW,
        USER_EMAIL,
        COUNT(DISTINCT CONVERSATION_ID) AS conversation_cnt
    FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
    WHERE LICENSE_TYPE = 'Purchase' AND CHAT_ID IS NOT NULL
    GROUP BY BILLING_ACCOUNT_ID_RAW, USER_EMAIL
    HAVING COUNT(DISTINCT CONVERSATION_ID) >= 5
)
SELECT
    COUNT(DISTINCT BILLING_ACCOUNT_ID_RAW) AS engaged_accounts
FROM engaged_users;


-- --------------------------------------------------------------------------------
-- Section B: Users Activity Funnel (Paid Only)
-- --------------------------------------------------------------------------------

-- Query 5. Onboarded Users
SELECT COUNT(DISTINCT USER_ID_RAW) AS onboarded_users
FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
WHERE LICENSE_TYPE = 'Purchase';

-- Query 6. Active Users (Chats > 0)
SELECT COUNT(DISTINCT USER_ID_RAW) AS active_users
FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
WHERE LICENSE_TYPE = 'Purchase' AND CHAT_ID IS NOT NULL;

-- Query 7. Users with at least 1 Workflow
SELECT COUNT(DISTINCT USER_ID_RAW) AS users_with_workflows
FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
WHERE LICENSE_TYPE = 'Purchase' AND CHAT_ID IS NOT NULL AND WORKFLOW_ID IS NOT NULL;

-- Query 8. Engaged Users (>= 5 Conversations)
WITH engaged_users AS (
    SELECT
        USER_ID_RAW,
        COUNT(DISTINCT CONVERSATION_ID) AS conversation_cnt
    FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
    WHERE LICENSE_TYPE = 'Purchase' AND CHAT_ID IS NOT NULL
    GROUP BY USER_ID_RAW
    HAVING COUNT(DISTINCT CONVERSATION_ID) >= 5
)
SELECT COUNT(DISTINCT USER_ID_RAW) AS engaged_users 
FROM engaged_users;


-- --------------------------------------------------------------------------------
-- Section C: User Adoption Rate & Retention Metrics (Symmetrical Filters)
-- --------------------------------------------------------------------------------

-- Query 9. User Rate Adoption (Active Users / Eligible Users)
WITH numerator AS (
    SELECT COUNT(DISTINCT USER_ID_RAW) AS ACTIVE_USERS
    FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
    WHERE LICENSE_TYPE = 'Purchase' AND CHAT_ID IS NOT NULL
),
denominator AS (
    SELECT COUNT(DISTINCT USER_ID_RAW) AS ELIGIBLE_USERS
    FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.AYX_DAILY_USERS_AT
    WHERE LICENSE_TYPE = 'Purchase'
      AND PRICING_AND_PACKAGING = '2025'
      AND ACCOUNT_EDITION IN ('Enterprise', 'Professional')
      AND STATUS = 'ACTIVATED'
      AND USER_EMAIL IS NOT NULL
      AND COPILOT_ENABLED = TRUE
      AND TRY_TO_DECIMAL(MAX_USER_VERSION, 10, 2) >= 2025.2
      -- Query from the latest snapshot day for maximum accuracy
      AND DATE = (SELECT MAX(DATE) FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.AYX_DAILY_USERS_AT)
)
SELECT 
    ACTIVE_USERS,
    ELIGIBLE_USERS,
    ROUND(ACTIVE_USERS / NULLIF(ELIGIBLE_USERS, 0), 2) AS adoption_ratio
FROM numerator, denominator;

-- Query 10. Returning User Percentage (7-14 Days Cohort Retention)
WITH user_activity AS (
    SELECT
        USER_EMAIL AS CREATED_BY_ID,
        ACTIVITY_DATE AS activity_date
    FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_DAILY
    WHERE ACCOUNT_EDITION IN ('Professional','Enterprise')
      AND LICENSE_TYPE = 'Purchase'
      AND CHATS > 0
),
first_use AS (
  SELECT
    CREATED_BY_ID,
    MIN(activity_date) AS first_date
  FROM user_activity
  GROUP BY CREATED_BY_ID
),
eligible_cohort AS (
    SELECT
        CREATED_BY_ID,
        first_date
    FROM first_use
    WHERE first_date <= DATEADD(day, -7, CURRENT_DATE())
),
returns_7_15 AS (
  SELECT
    fu.CREATED_BY_ID,
    MIN(ua.activity_date) AS first_return_date_in_window
  FROM eligible_cohort fu
  JOIN user_activity ua
    ON ua.CREATED_BY_ID = fu.CREATED_BY_ID
   AND ua.activity_date BETWEEN DATEADD(day, 7, fu.first_date)
                            AND DATEADD(day, 15, fu.first_date)
  GROUP BY fu.CREATED_BY_ID
)
SELECT
    (SELECT COUNT(*) FROM eligible_cohort) AS total_cohort_users,
    (SELECT COUNT(*) FROM returns_7_15)   AS returning_users_7_15d,
    ROUND(
        (SELECT COUNT(*) FROM returns_7_15) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM eligible_cohort), 0),
        2
    ) AS returning_rate_pct;

-- Query 11. Returning User Percentage (30-60 Days Cohort Retention)
WITH user_activity AS (
    SELECT
        USER_EMAIL AS CREATED_BY_ID,
        ACTIVITY_DATE AS activity_date
    FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_DAILY
    WHERE ACCOUNT_EDITION IN ('Professional','Enterprise')
      AND LICENSE_TYPE = 'Purchase'
      AND CHATS > 0
),
first_use AS (
  SELECT
    CREATED_BY_ID,
    MIN(activity_date) AS first_date
  FROM user_activity
  GROUP BY CREATED_BY_ID
),
eligible_cohort AS (
    SELECT
        CREATED_BY_ID,
        first_date
    FROM first_use
    WHERE first_date <= DATEADD(day, -30, CURRENT_DATE())
),
returns_30_60 AS (
  SELECT
    e.CREATED_BY_ID,
    MIN(ua.activity_date) AS first_return_date_in_window
  FROM eligible_cohort e
  JOIN user_activity ua
    ON ua.CREATED_BY_ID = e.CREATED_BY_ID
   AND ua.activity_date BETWEEN DATEADD(day, 30, e.first_date)
                            AND DATEADD(day, 60, e.first_date)
  GROUP BY e.CREATED_BY_ID
)
SELECT
    (SELECT COUNT(*) FROM eligible_cohort) AS total_cohort_users,
    (SELECT COUNT(*) FROM returns_30_60)   AS returning_users_30_60d,
    ROUND(
        (SELECT COUNT(*) FROM returns_30_60) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM eligible_cohort), 0),
        2
    ) AS returning_rate_pct;


-- --------------------------------------------------------------------------------
-- Section D: Workflow Generations & Execution Rates (Partitioned High-Speed Queries)
-- --------------------------------------------------------------------------------

-- Query 12. Workflows Built Using Copilot
SELECT COUNT(DISTINCT WORKFLOW_ID) AS workflows_built_using_copilot
FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
WHERE LICENSE_TYPE = 'Purchase' AND CHAT_ID IS NOT NULL AND WORKFLOW_ID IS NOT NULL;

-- Query 13. Percentage of Workflows run by Copilot (June 2026 High-Performance Partition)
-- Optimization: Employs pre-lowercased string mapping ('es_clean') on ALTERYX_PAYLOAD_USER_ACCOUNT to prevent fanning.
WITH copilot_eligible_users AS (
    SELECT DISTINCT USER_EMAIL
    FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
    WHERE LICENSE_TYPE = 'Purchase' AND CHAT_ID IS NOT NULL AND ACTIVITY_DATE BETWEEN '2026-06-01' AND '2026-06-30'
),
first_copilot_interaction AS (
    SELECT
        USER_EMAIL AS user_email,
        MIN(ACTIVITY_DATE) AS first_conv_created_at
    FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED
    WHERE CHAT_ID IS NOT NULL AND USER_EMAIL IS NOT NULL
    GROUP BY 1
),
es_clean AS (
    SELECT 
        WORKFLOW_ID,
        PAYLOAD_DTS,
        PRODUCT_NAME,
        LOWER(NULLIF(TRIM(USER_EMAIL), '')) AS email_lc
    FROM DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.ALTERYX_PAYLOAD_USER_ACCOUNT
    WHERE PAYLOAD_DTS BETWEEN '2026-06-01' AND '2026-06-30' AND PRODUCT_NAME = 'Designer'
),
denominator AS (
    SELECT DISTINCT
        es.WORKFLOW_ID,
        es.email_lc
    FROM es_clean es
    INNER JOIN copilot_eligible_users eu
        ON es.email_lc = eu.USER_EMAIL
    INNER JOIN first_copilot_interaction fci
        ON es.email_lc = fci.user_email
    WHERE es.PAYLOAD_DTS >= fci.first_conv_created_at
),
numerator AS (
    SELECT DISTINCT
        es.WORKFLOW_ID,
        co.USER_EMAIL AS copilot_email,
        es.email_lc AS engine_email
    FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED co
    LEFT JOIN es_clean es
        ON co.WORKFLOW_ID = es.WORKFLOW_ID
    WHERE co.WORKFLOW_ID IS NOT NULL
      AND co.USER_EMAIL IN (SELECT USER_EMAIL FROM copilot_eligible_users)
      AND co.CHAT_ID IS NOT NULL AND co.ACTIVITY_DATE BETWEEN '2026-06-01' AND '2026-06-30'
)
SELECT
    (SELECT COUNT(DISTINCT WORKFLOW_ID) FROM numerator)   AS copilot_mapped_workflow_runs,
    (SELECT COUNT(DISTINCT WORKFLOW_ID) FROM denominator) AS copilot_active_user_workflow_run,
    ROUND(
        100.0 *
        (SELECT COUNT(DISTINCT WORKFLOW_ID) FROM numerator)::FLOAT /
        NULLIF((SELECT COUNT(DISTINCT WORKFLOW_ID) FROM denominator), 0),
        4
    ) AS copilot_pct_workflow_runs;