-- ================================================================================
-- Ask Alteryx (Copilot) Sandbox Playbook SQL Views
-- Schema: DISCOVERY_PRODUCT_MANAGEMENT.PI_SANDBOX
-- Purpose: Direct, highly optimized, and live-tested database view definitions for:
--          1. INTELLIGENCE_SUITE_INSIGHTS_VW (Financial and MAU/MAA scorecard analytics)
--          2. ERROR_BY_TOOL_VW (Cleansed tool run success and error analysis)
-- ================================================================================

-- --------------------------------------------------------------------------------
-- 1. View: INTELLIGENCE_SUITE_INSIGHTS_VW
-- --------------------------------------------------------------------------------

CREATE OR REPLACE VIEW DISCOVERY_PRODUCT_MANAGEMENT.PI_SANDBOX.INTELLIGENCE_SUITE_INSIGHTS_VW(
    PRODUCT,
    KPI,
    OWNER,
    VALUE
) AS
SELECT
  'Alteryx Intelligence Suite' AS PRODUCT,
  'New Customer' AS KPI,
  'Chirag' AS OWNER,
  SUM(new_logos) AS VALUE
FROM
  DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.SCORECARD_FLAGSHIP_FINANCIALS
WHERE
  PRODUCT_GROUP = 'Alteryx Intelligence Suite'
  AND DATE >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
  AND DATE < DATE_TRUNC('month', CURRENT_DATE)
UNION ALL
SELECT
  'Alteryx Intelligence Suite' AS PRODUCT,
  'Total Accounts' AS KPI,
  'Chirag' AS OWNER,
  SUM(total_logos) AS VALUE
FROM
  DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.SCORECARD_FLAGSHIP_FINANCIALS
WHERE
  PRODUCT_GROUP = 'Alteryx Intelligence Suite'
  AND DATE >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
  AND DATE < DATE_TRUNC('month', CURRENT_DATE)
UNION ALL
SELECT
  'Alteryx Intelligence Suite' AS PRODUCT,
  'Active ACV' AS KPI,
  'Chirag' AS OWNER,
  SUM(active_acv) AS VALUE
FROM
  DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.SCORECARD_FLAGSHIP_FINANCIALS
WHERE
  PRODUCT_GROUP = 'Alteryx Intelligence Suite'
  AND DATE >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
  AND DATE < DATE_TRUNC('month', CURRENT_DATE)
UNION ALL
SELECT
  'Alteryx Intelligence Suite' AS PRODUCT,
  'Sum Seats' AS KPI,
  'Chirag' AS OWNER,
  SUM("Sum_SEATS") AS VALUE
FROM
  DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.SCORECARD_FLAGSHIP_FINANCIALS
WHERE
  PRODUCT_GROUP = 'Alteryx Intelligence Suite'
  AND DATE >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
  AND DATE < DATE_TRUNC('month', CURRENT_DATE)
UNION ALL
SELECT
  'Alteryx Intelligence Suite' AS PRODUCT,
  'Sum Adjusted Seats' AS KPI,
  'Chirag' AS OWNER,
  SUM("Sum_ADJUSTED_SEATS") AS VALUE
FROM
  DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.SCORECARD_FLAGSHIP_FINANCIALS
WHERE
  PRODUCT_GROUP = 'Alteryx Intelligence Suite'
  AND DATE >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
  AND DATE < DATE_TRUNC('month', CURRENT_DATE)
UNION ALL
SELECT
  'Alteryx Intelligence Suite' AS PRODUCT,
  'Activated Seats' AS KPI,
  'Chirag' AS OWNER,
  SUM(activated_seats) AS VALUE
FROM
  DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.SCORECARD_FLAGSHIP_FINANCIALS
WHERE
  PRODUCT_GROUP = 'Alteryx Intelligence Suite'
  AND DATE >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
  AND DATE < DATE_TRUNC('month', CURRENT_DATE)
UNION ALL
SELECT
  'Alteryx Intelligence Suite' AS PRODUCT,
  'Adjusted Activated Seats' AS KPI,
  'Chirag' AS OWNER,
  SUM(adjusted_activated_seats) AS VALUE
FROM
  DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.SCORECARD_FLAGSHIP_FINANCIALS
WHERE
  PRODUCT_GROUP = 'Alteryx Intelligence Suite'
  AND DATE >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
  AND DATE < DATE_TRUNC('month', CURRENT_DATE)
UNION ALL
SELECT
  'Alteryx Intelligence Suite' AS PRODUCT,
  'Contract Duration' AS KPI,
  'Chirag' AS OWNER,
  SUM(contract_duration) AS VALUE
FROM
  DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.SCORECARD_FLAGSHIP_FINANCIALS
WHERE
  PRODUCT_GROUP = 'Alteryx Intelligence Suite'
  AND DATE >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
  AND DATE < DATE_TRUNC('month', CURRENT_DATE)
UNION ALL
SELECT
  'Alteryx Intelligence Suite' AS PRODUCT,
  'Activation' AS KPI,
  'Chirag' AS OWNER,
  SUM(activation) AS VALUE
FROM
  DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.SCORECARD_FLAGSHIP_FINANCIALS
WHERE
  PRODUCT_GROUP = 'Alteryx Intelligence Suite'
  AND DATE >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month'
  AND DATE < DATE_TRUNC('month', CURRENT_DATE)
UNION ALL
SELECT
  'Intelligence Suite' AS Product,
  'MAU' AS KPI,
  'Chirag' AS Owner,
  SUM(MAU) AS VALUE
FROM
  DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.SCORECARD_FLAGSHIP_MAU
WHERE
  PRODUCT = 'Intelligence Suite'
  AND MONTH >= DATE_TRUNC ('MONTH', CURRENT_DATE) - INTERVAL '1 MONTH'
  AND MONTH < DATE_TRUNC ('MONTH', CURRENT_DATE)
UNION ALL
SELECT
  'Intelligence Suite' AS Product,
  'MAA' AS KPI,
  'Chirag' AS Owner,
  SUM(MAA) AS VALUE
FROM
  DISCOVERY_PRODUCT_MANAGEMENT.TEL_STRAT.SCORECARD_FLAGSHIP_MAU
WHERE
  PRODUCT = 'Intelligence Suite'
  AND MONTH >= DATE_TRUNC ('MONTH', CURRENT_DATE) - INTERVAL '1 MONTH'
  AND MONTH < DATE_TRUNC ('MONTH', CURRENT_DATE);


-- --------------------------------------------------------------------------------
-- 2. View: ERROR_BY_TOOL_VW
-- --------------------------------------------------------------------------------

CREATE OR REPLACE VIEW DISCOVERY_PRODUCT_MANAGEMENT.PI_SANDBOX.ERROR_BY_TOOL_VW(
    CLEANSED_TOOL_NAME,
    TOOL_GROUP,
    MESSAGE,
    COUNTDISTINCT_PAYLOAD_ID,
    COUNTDISTINCT_USER_ID,
    TOTAL_PAYLOADS,
    TOTAL_USERS
) AS
WITH clickstream_base AS (
    SELECT 
        t.PAYLOAD_ID,
        t.PAYLOAD_DTS,
        LOWER(t.USER_ID) AS USER_ID,
        t.TOOL_ID,
        c.CLEANSED_TOOL_NAME,
        c.TOOL_GROUP
    FROM "DISCOVERY_PRODUCT_MANAGEMENT"."TEL_STRAT"."API_NODES_TOOL_NAMES" t
    JOIN "DISCOVERY_PRODUCT_MANAGEMENT"."TEL_STRAT"."ENGINE_TOOL_NAMES_CLEAN" c 
      ON t.TOOL_NAME = c.ENGINE_TOOL_NAME
    WHERE 
      LAST_DAY(t.PAYLOAD_DTS, 'quarter') >= DATEADD(day, -90, CURRENT_DATE()) 
      AND t.PAYLOAD_DTS <= CURRENT_DATE()
      AND LEFT(t.PRODUCT_VERSION, 4) >= '2020' 
      AND t.PRODUCT_VERSION NOT LIKE '%20.1%' 
      AND LOWER(t.USER_ID) NOT LIKE '%@alteryx.com%'
),
click_summaries AS (
    SELECT 
        CLEANSED_TOOL_NAME,
        TOOL_GROUP,
        COUNT(DISTINCT PAYLOAD_ID) AS Total_Payloads,
        COUNT(DISTINCT USER_ID)    AS Total_Users
    FROM clickstream_base
    GROUP BY 1, 2
),
error_logs AS (
    SELECT 
        PAYLOAD_ID,
        ERROR_TOOL_ID,
        MESSAGE,
        LOWER(USER_EMAIL) AS USER_EMAIL
    FROM "DISCOVERY_PRODUCT_MANAGEMENT"."TEL_STRAT"."ERROR_MESSAGES"
    WHERE 
      LAST_DAY(PAYLOAD_DTS, 'quarter') >= DATEADD(day, -90, CURRENT_DATE()) 
      AND PAYLOAD_DTS <= CURRENT_DATE()
      AND MESSAGE NOT LIKE '%Unable to decode these messages%'
      AND LOWER(USER_EMAIL) NOT LIKE '%@alteryx.com%'
),
resolved_errors AS (
    SELECT 
        c.CLEANSED_TOOL_NAME,
        c.TOOL_GROUP,
        e.MESSAGE,
        e.PAYLOAD_ID,
        e.USER_EMAIL
    FROM error_logs e
    JOIN clickstream_base c 
      ON e.PAYLOAD_ID = c.PAYLOAD_ID 
     AND e.ERROR_TOOL_ID = c.TOOL_ID
),
error_summaries AS (
    SELECT 
        CLEANSED_TOOL_NAME,
        TOOL_GROUP,
        MESSAGE,
        COUNT(DISTINCT PAYLOAD_ID) AS CountDistinct_PAYLOAD_ID,
        COUNT(DISTINCT USER_EMAIL) AS CountDistinct_USER_ID
    FROM resolved_errors
    GROUP BY 1, 2, 3
)
SELECT 
    e.CLEANSED_TOOL_NAME,
    e.TOOL_GROUP,
    e.MESSAGE,
    e.CountDistinct_PAYLOAD_ID,
    e.CountDistinct_USER_ID,
    c.Total_Payloads,
    c.Total_Users
FROM error_summaries e
JOIN click_summaries c 
  ON e.CLEANSED_TOOL_NAME = c.CLEANSED_TOOL_NAME 
 AND e.TOOL_GROUP = c.TOOL_GROUP;