#!/bin/bash
# k8s-deployment-rollout-status.sh (Simple Version)

sleep 60s

# Use 10 minutes timeout and check exit code directly
if kubectl -n default rollout status deploy ${deploymentName} --timeout=600s; then
    echo "✅ Deployment ${deploymentName} Rollout is Success"
else
    echo "❌ Deployment ${deploymentName} Rollout has Failed"
    
    # Debug information
    kubectl -n default describe deploy ${deploymentName}
    kubectl -n default get pods -l app=${deploymentName}
    
    # Rollback
    kubectl -n default rollout undo deploy ${deploymentName}
    exit 1
fi
