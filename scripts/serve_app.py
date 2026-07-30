import os
import sys
import json
import socket
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler

# Add parent directory to system path for relative imports
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from skills.snowflake_connector import execute_query
from scripts.ai_analytics_console import route_natural_language_question, analyze_query_governance, run_qa_check

START_PORT = 8080
MAX_PORT_ATTEMPTS = 10

class AskAlteryxHTTPHandler(BaseHTTPRequestHandler):
    """Custom, lightweight REST API and Static File Server with zero external library dependencies."""
    
    def do_GET(self):
        parsed_url = urllib.parse.urlparse(self.path)
        path = parsed_url.path
        
        # 1. REST API Endpoint: /api/ask?q=...
        if path == "/api/ask":
            query_params = urllib.parse.parse_qs(parsed_url.query)
            user_query = query_params.get("q", [""])[0]
            
            if not user_query:
                self._send_json({"error": "Empty query parameter 'q'"}, status=400)
                return
                
            print(f"🧠 Web App User Prompt: \"{user_query}\"")
            sql = route_natural_language_question(user_query)
            
            # Enforce Read-Only Governance Block
            if not analyze_query_governance(sql):
                self._send_json({
                    "error": "❌ GOVERNANCE SECURITY BLOCK: Write/modification commands are strictly blocked.",
                    "status": "blocked"
                }, status=403)
                return
                
            try:
                # Execute Snowflake query and convert to JSON dictionary
                df = execute_query(sql)
                qa_badge = run_qa_check(df)
                
                # Format NaN/Null values to prevent JSON serialization errors
                df_clean = df.fillna("")
                records = df_clean.to_dict(orient="records")
                columns = list(df.columns)
                
                self._send_json({
                    "query": user_query,
                    "sql": sql.strip(),
                    "qa_badge": qa_badge,
                    "columns": columns,
                    "records": records
                })
            except Exception as e:
                self._send_json({"error": f"Snowflake execution error: {e}"}, status=500)
                
        # 2. Serve Front-end App HTML: /
        elif path == "/" or path == "/index.html" or path == "/app.html":
            html_path = os.path.join(os.path.dirname(__file__), "../app.html")
            if os.path.exists(html_path):
                self._send_file(html_path, "text/html")
            else:
                self.send_error(404, "Frontend app.html not found on disk.")
                
        else:
            self.send_error(404, "File not found.")

    def _send_json(self, payload: dict, status: int = 200):
        """Sends a JSON REST API response."""
        try:
            content = json.dumps(payload).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Content-Length", len(content))
            self.end_headers()
            self.wfile.write(content)
        except Exception as e:
            print(f"❌ Socket Write Error: {e}")

    def _send_file(self, file_path: str, content_type: str):
        """Serves a static file from disk."""
        try:
            with open(file_path, "rb") as f:
                content = f.read()
            self.send_response(200)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", len(content))
            self.end_headers()
            self.wfile.write(content)
        except Exception as e:
            self.send_error(500, f"Error reading file: {e}")

def run_server():
    port = START_PORT
    for attempt in range(MAX_PORT_ATTEMPTS):
        try:
            server_address = ("127.0.0.1", port)
            httpd = HTTPServer(server_address, AskAlteryxHTTPHandler)
            print("================================================================================")
            print(f"🌐 ASK ALTERYX SELF-SERVE ANALYTICS PORTAL RUNNING LIVE!")
            print(f"👉 Local Web URL: http://127.0.0.1:{port}")
            print("================================================================================")
            httpd.serve_forever()
            return
        except OSError as e:
            if e.errno == 48: # Address already in use
                print(f"⚠️ Port {port} is occupied. Scanning next port...")
                port += 1
            else:
                print(f"❌ Socket binding error: {e}")
                sys.exit(1)
                
    print("❌ Critical: Max port scanning attempts exceeded. No available ports found.")
    sys.exit(1)

if __name__ == "__main__":
    run_server()