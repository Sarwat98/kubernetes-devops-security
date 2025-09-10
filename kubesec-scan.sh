#!/bin/bash
kubesec scan k8s_deployment_service.yaml > kubesec-results.json
cat kubesec-results.json

# Check for critical issues
CRITICAL_ISSUES=$(cat kubesec-results.json | jq '.score')
if [[ $CRITICAL_ISSUES -lt 0 ]]; then
    echo "Kubesec scan failed with score: $CRITICAL_ISSUES"
    exit 1
else
    echo "Kubesec scan passed with score: $CRITICAL_ISSUES"
fi
