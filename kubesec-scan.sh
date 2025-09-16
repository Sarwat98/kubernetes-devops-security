#!/bin/bash

echo "=== Running Kubesec Security Scan ==="

kubesec scan k8s_deployment_service.yaml > kubesec-results.json

cat kubesec-results.json

echo ""
echo "=== Security Score Summary ==="

SCORES=$(cat kubesec-results.json | jq -r '.[].score // 0')
echo "Scores: $SCORES"

echo "Kubesec scan completed successfully"
