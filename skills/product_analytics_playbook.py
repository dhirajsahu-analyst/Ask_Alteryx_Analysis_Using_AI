import pandas as pd
import numpy as np

class ProductAnalyticsPlaybook:
    """Implementation of standard Amplitude-style analytics algorithms to diagnose user engagement and churn."""
    
    @staticmethod
    def calculate_dau_mau_stickiness(daily_active_df: pd.DataFrame) -> float:
        """Calculates Average DAU over MAU ratio to measure habitual product utility."""
        if daily_active_df.empty or 'USER_EMAIL' not in daily_active_df.columns:
            return 0.0
        
        # Calculate distinct monthly active users (MAU)
        mau = daily_active_df['USER_EMAIL'].nunique()
        if mau == 0: return 0.0
        
        # Calculate average daily active users (DAU)
        dau_by_day = daily_active_df.groupby('ACTIVITY_DATE')['USER_EMAIL'].nunique()
        avg_dau = dau_by_day.mean()
        
        return round(100.0 * avg_dau / mau, 2)

    @staticmethod
    def calculate_one_prompt_bounce_rate(activity_df: pd.DataFrame) -> float:
        """Measures the percentage of active users who sent exactly 1 prompt and abandoned the feature."""
        if activity_df.empty or 'USER_EMAIL' not in activity_df.columns:
            return 0.0
        
        # Count chats per user
        user_chats = activity_df.groupby('USER_EMAIL')['CHAT_ID'].count()
        total_users = len(user_chats)
        if total_users == 0: return 0.0
        
        bounced_users = (user_chats == 1).sum()
        return round(100.0 * bounced_users / total_users, 2)

    @staticmethod
    def calculate_workflow_conversion_funnel(activity_df: pd.DataFrame) -> dict:
        """Generates the step-by-step conversion funnel from Active -> Engaged -> Activated Workflow Creator."""
        if activity_df.empty or 'USER_EMAIL' not in activity_df.columns:
            return {}
            
        total_active = activity_df['USER_EMAIL'].nunique()
        if total_active == 0: return {}
        
        # Engaged users (who initiated a successful conversation)
        engaged = activity_df[activity_df['CONVERSATION_ID'].notnull()]['USER_EMAIL'].nunique()
        
        # Activated creators (who touched a workflow ID)
        activated = activity_df[activity_df['WORKFLOW_ID'].notnull()]['USER_EMAIL'].nunique()
        
        return {
            "Stage 1 - Active User (Total)": total_active,
            "Stage 2 - Engaged Session User (Conv > 0)": engaged,
            "Stage 3 - Activated Workflow Creator (Workflow > 0)": activated,
            "Active-to-Engaged Conversion %": round(100.0 * engaged / total_active, 2),
            "Engaged-to-Activated Conversion %": round(100.0 * activated / engaged, 2) if engaged > 0 else 0.0
        }

if __name__ == "__main__":
    # Mock data to demonstrate execution
    mock_data = pd.DataFrame({
        'ACTIVITY_DATE': ['2026-06-01', '2026-06-01', '2026-06-02'],
        'USER_EMAIL': ['alice@company.com', 'bob@company.com', 'alice@company.com'],
        'CHAT_ID': ['ch_1', 'ch_2', 'ch_3'],
        'CONVERSATION_ID': ['co_1', 'co_2', 'co_1'],
        'WORKFLOW_ID': ['wf_1', None, 'ch_1']
    })
    
    playbook = ProductAnalyticsPlaybook()
    print("Stickiness (DAU/MAU) %:", playbook.calculate_dau_mau_stickiness(mock_data))
    print("Bounce Rate %:", playbook.calculate_one_prompt_bounce_rate(mock_data))
    print("Funnel Stats:", playbook.calculate_workflow_conversion_funnel(mock_data))