#!/bin/bash
set -e

# Nessus API Scanner Script for Jenkins
# Uses environment variables: NESSUS_URL, NESSUS_ACCESS_KEY, NESSUS_SECRET_KEY, APP_TARGET

echo "=== Starting Tenable Nessus VM Scan ==="

# Check required environment variables
if [ -z "$NESSUS_URL" ] || [ -z "$NESSUS_ACCESS_KEY" ] || [ -z "$NESSUS_SECRET_KEY" ] || [ -z "$APP_TARGET" ]; then
    echo "❌ Missing required environment variables:"
    echo "   NESSUS_URL, NESSUS_ACCESS_KEY, NESSUS_SECRET_KEY, APP_TARGET"
    exit 1
fi

echo "✅ Environment variables verified"
echo "🔍 Scanner: $NESSUS_URL"
echo "🎯 Target: $APP_TARGET"

# Create reports directory
mkdir -p nessus-scan-report

# Run Nessus scan via Python
python3 << 'EOF'
import requests
import time
import sys
import os
from urllib3.packages.urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

class NessusScanner:
    def __init__(self, url, access_key, secret_key):
        self.url = url.rstrip('/')
        self.session = requests.Session()
        self.session.verify = False
        self.session.headers.update({
            'X-ApiKeys': f'accessKey={access_key}; secretKey={secret_key}',
            'Content-Type': 'application/json'
        })

    def login(self):
        resp = self.session.post(f'{self.url}/session')
        if resp.status_code == 200:
            token = resp.json().get('token')
            self.session.headers.update({'X-Cookie': f'token={token}'})
            print('✅ Successfully authenticated to Nessus VM')
            return True
        print(f'❌ Authentication failed: {resp.text}')
        return False

    def run_complete_scan(self, target):
        # Create scan
        scan_data = {
            "uuid": "731a8e52-3ea6-a291-ec0a-d2ff0619c19d7bd788d6",
            "settings": {
                "name": f"DevSecOps-Pipeline-{int(time.time())}",
                "text_targets": target,
                "description": "Automated DevSecOps Pipeline Vulnerability Scan"
            }
        }
        
        resp = self.session.post(f'{self.url}/scans', json=scan_data)
        if resp.status_code != 200:
            print(f'❌ Failed to create scan: {resp.text}')
            return False
        
        scan_id = resp.json()['scan']['id']
        print(f'✅ Scan created with ID: {scan_id}')
        
        # Launch scan
        resp = self.session.post(f'{self.url}/scans/{scan_id}/launch')
        if resp.status_code != 200:
            print(f'❌ Failed to launch scan: {resp.text}')
            return False
        
        print('🚀 Scan launched, monitoring progress...')
        
        # Wait for completion
        for i in range(60):  # 30 minutes max
            resp = self.session.get(f'{self.url}/scans/{scan_id}')
            if resp.status_code != 200:
                print('❌ Failed to get scan status')
                return False
                
            status = resp.json()['info']['status']
            print(f'📊 Scan status: {status} ({i+1}/60 checks)')
            
            if status in ['completed', 'imported']:
                print('✅ Scan completed successfully!')
                break
            elif status in ['aborted', 'canceled', 'stopped']:
                print(f'❌ Scan terminated: {status}')
                return False
            
            time.sleep(30)
        else:
            print('⏰ Scan timeout reached')
            return False
        
        # Export HTML report
        print('📄 Exporting HTML report...')
        resp = self.session.post(f'{self.url}/scans/{scan_id}/export', json={'format': 'html'})
        if resp.status_code != 200:
            print(f'❌ Export request failed: {resp.text}')
            return False
        
        file_id = resp.json()['file']
        
        # Wait for export
        while True:
            resp = self.session.get(f'{self.url}/scans/{scan_id}/export/{file_id}/status')
            if resp.status_code != 200:
                print('❌ Export status check failed')
                return False
            
            if resp.json()['status'] == 'ready':
                break
            print('📝 Export in progress...')
            time.sleep(5)
        
        # Download report
        resp = self.session.get(f'{self.url}/scans/{scan_id}/export/{file_id}/download')
        if resp.status_code != 200:
            print('❌ Report download failed')
            return False
        
        # Save to both locations for Jenkins
        with open('nessus_report.html', 'wb') as f:
            f.write(resp.content)
        with open('nessus-scan-report/nessus_report.html', 'wb') as f:
            f.write(resp.content)
        
        print('✅ HTML report downloaded successfully')
        
        # Create index file for better navigation
        with open('nessus-scan-report/index.html', 'w') as f:
            f.write(f'''<!DOCTYPE html>
<html>
<head>
    <title>Tenable Nessus VM Scan Results</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }}
        .container {{ background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
        .vm-badge {{ background: linear-gradient(45deg, #8e44ad, #9b59b6); color: white; padding: 8px 16px; border-radius: 25px; font-weight: bold; display: inline-block; margin-bottom: 15px; }}
        .btn {{ display: inline-block; background: #3498db; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 10px 5px; }}
        .success {{ color: #27ae60; font-weight: bold; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="vm-badge">🖥️ ON-PREMISES VM</div>
        <h1>🛡️ Tenable Nessus VM Security Scan</h1>
        <div class="success">✅ Vulnerability Scan Completed Successfully</div>
        
        <h3>📋 Scan Details:</h3>
        <ul>
            <li><strong>Target:</strong> {target}</li>
            <li><strong>Scanner:</strong> Tenable Nessus VM</li>
            <li><strong>Integration:</strong> Jenkins DevSecOps Pipeline</li>
            <li><strong>Timestamp:</strong> {time.strftime('%Y-%m-%d %H:%M:%S')}</li>
        </ul>
        
        <h3>📊 Available Reports:</h3>
        <a href="nessus_report.html" class="btn">View Detailed HTML Report</a>
    </div>
</body>
</html>''')
        
        return True

# Main execution
url = os.environ.get('NESSUS_URL')
access_key = os.environ.get('NESSUS_ACCESS_KEY')
secret_key = os.environ.get('NESSUS_SECRET_KEY')
target = os.environ.get('APP_TARGET')

scanner = NessusScanner(url, access_key, secret_key)

if not scanner.login():
    sys.exit(1)

if not scanner.run_complete_scan(target):
    sys.exit(1)

print('🎉 Nessus VM scan completed successfully!')
EOF

echo "✅ Tenable Nessus VM scan integration completed"
