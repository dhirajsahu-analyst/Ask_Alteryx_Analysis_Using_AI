import os
import requests
import time
import hmac
import hashlib
import urllib.parse
from dotenv import load_dotenv

# Load credentials from .env
load_dotenv(os.path.join(os.path.dirname(__file__), '../.env'))

class AlteryxGalleryConnector:
    """Connector for interacting with Alteryx Server Gallery API v3 to audit schedules and job logs."""
    
    def __init__(self):
        self.base_url = os.getenv('GALLERY_BASE_URL', '').rstrip('/')
        self.client_id = os.getenv('GALLERY_CLIENT_ID')
        self.client_secret = os.getenv('GALLERY_CLIENT_SECRET')

    def _get_auth_headers(self, method: str, endpoint: str, params: dict = None) -> dict:
        """Generates OAuth 1.0 or API v3 authentication headers."""
        # Standard placeholder for Gallery API V3 Header authentication
        return {
            "Authorization": f"Bearer {self.client_secret}",
            "Accept": "application/json",
            "Content-Type": "application/json"
        }

    def get_workflow_schedules(self, workflow_id: str) -> dict:
        """Fetches active schedules for a given Alteryx Server workflow."""
        if not self.base_url or not self.client_id:
            print("⚠️ Gallery API credentials missing. Returning mock metadata for local testing.")
            return {
                "workflow_id": workflow_id,
                "workflow_name": "COPILOT DESIGNER WORKFLOW",
                "active_schedules": [
                    {"schedule_id": "sch_112233", "frequency": "Twice Daily", "last_run": "Denver 01:15"},
                    {"schedule_id": "sch_445566", "frequency": "Twice Daily", "last_run": "Mauritius 04:35"}
                ],
                "status": "ACTIVE"
            }
        
        url = f"{self.base_url}/workflows/{workflow_id}/schedules"
        try:
            response = requests.get(url, headers=self._get_auth_headers("GET", url))
            if response.status_code == 200:
                return response.json()
            else:
                print(f"❌ Failed to fetch schedules: {response.status_code} - {response.text}")
                return {}
        except Exception as e:
            print(f"❌ Error connecting to Gallery API: {e}")
            return {}

    def get_job_status(self, job_id: str) -> dict:
        """Retrieves the run execution status and data output logs of a background engine job."""
        if not self.base_url:
            return {
                "job_id": job_id,
                "status": "Completed",
                "duration_seconds": 142,
                "outputs": [{"output_id": "out_9988", "name": "AYX_DAILY_USERS_AT", "records_written": 21450280}]
            }
        
        url = f"{self.base_url}/jobs/{job_id}"
        try:
            response = requests.get(url, headers=self._get_auth_headers("GET", url))
            if response.status_code == 200:
                return response.json()
            else:
                print(f"❌ Failed to fetch job status: {response.status_code}")
                return {}
        except Exception as e:
            print(f"❌ Error: {e}")
            return {}

if __name__ == "__main__":
    connector = AlteryxGalleryConnector()
    # Test checking the schedule of the legacy materialized workflow
    print(connector.get_workflow_schedules("6a201f6dc234cfa240606ac4"))