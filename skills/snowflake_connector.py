import os
import snowflake.connector
import pandas as pd
from dotenv import load_dotenv

# Load credentials from .env
load_dotenv(os.path.join(os.path.dirname(__file__), '../.env'))

def execute_query(sql_query: str) -> pd.DataFrame:
    """Executes a SQL query against Snowflake and returns a Pandas DataFrame."""
    try:
        conn = snowflake.connector.connect(
            user=os.getenv('SNOWFLAKE_USER'),
            account=os.getenv('SNOWFLAKE_ACCOUNT'),
            warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
            database=os.getenv('SNOWFLAKE_DATABASE'),
            schema=os.getenv('SNOWFLAKE_SCHEMA'),
            role=os.getenv('SNOWFLAKE_ROLE'),
            authenticator=os.getenv('SNOWFLAKE_AUTHENTICATOR')
        )
        cur = conn.cursor()
        cur.execute(sql_query)
        cols = [desc[0] for desc in cur.description]
        df = pd.DataFrame(cur.fetchall(), columns=cols)
        return df
    except Exception as e:
        print(f"❌ Snowflake Execution Error: {e}")
        return pd.DataFrame()
    finally:
        if 'cur' in locals(): cur.close()
        if 'conn' in locals(): conn.close()

if __name__ == "__main__":
    # Test query
    sql = "SELECT COUNT(*) AS total_l2_rows FROM DISCOVERY_PRODUCT_MANAGEMENT.METRIC_STORE.SEM_COPILOT_USER_DAILY"
    print(execute_query(sql))