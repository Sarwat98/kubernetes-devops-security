#!/bin/bash

echo "=== Running Kubesec Security Scan ==="

# Run Kubesec scan and save results
kubesec scan k8s_deployment_service.yaml > kubesec-results.json

# Display full results
cat kubesec-results.json

# Extract and display scores properly (handle array)
echo ""
echo "=== Security Score Summary ==="

# Method 1: Extract all scores from the array
SCORES=$(cat kubesec-results.json | jq -r '.[].score // 0')
echo "Scores: $SCORES"

# Method 2: Get the deployment score specifically  
DEPLOYMENT_SCORE=$(cat kubesec-results.json | jq -r '.[] | select(.object | startswith("Deployment/")) | .score // 0')
echo "Deployment Security Score: $DEPLOYMENT_SCORE"

# Method 3: Check if any object failed (score < 0)
FAILED=$(cat kubesec-results.json | jq -r '.[] | select(.score < 0) | .object')
if [[ -n "$FAILED" ]]; then
    echo "❌ Failed security checks for: $FAILED"
    exit 1
else
    echo "✅ All security checks passed!"
fi

echo "Kubesec scan completed successfully"
