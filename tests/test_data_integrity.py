import os
import pytest
from skills.snowflake_connector import execute_query

def test_l1_fanout_prevention():
    """Validates that L1 enriched view has 0% fan-out compared to raw active logs."""
    raw_sql = """
        SELECT COUNT(*) FROM DISCOVERY_ENGINEERING.COPILOT.COPILOT_USAGE_ALL_REGIONS_VW
        WHERE CONV_CREATED_DATE >= '2025-12-03'
          AND SPLIT_PART(LOWER(NULLIF(TRIM(USER_EMAIL), '')), '@', 2) NOT LIKE '%alteryx.com%'
          AND SPLIT_PART(LOWER(NULLIF(TRIM(USER_EMAIL), '')), '@', 2) NOT LIKE '%aleeas.com%'
    """
    l1_sql = "SELECT COUNT(*) FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED"
    
    raw_count = execute_query(raw_sql).iloc[0,0]
    l1_count = execute_query(l1_sql).iloc[0,0]
    
    # We expect L1 to be slightly smaller due to failed chats pruning
    assert l1_count <= raw_count, f"Fan-out detected! L1 ({l1_count}) > Raw ({raw_count})"
    assert l1_count > (raw_count * 0.95), "Massive data loss detected in L1 view."

def test_l2_no_double_counting():
    """Validates that L2 daily view retains 100% of distinct chats from L1."""
    l1_chats = execute_query("SELECT COUNT(DISTINCT CHAT_ID) FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_ACTIVITY_ENRICHED").iloc[0,0]
    l2_chats = execute_query("SELECT SUM(CHATS) FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_DAILY").iloc[0,0]
    
    assert l1_chats == l2_chats, f"Double-counting leak! L1 Chats ({l1_chats}) != L2 Chats ({l2_chats})"