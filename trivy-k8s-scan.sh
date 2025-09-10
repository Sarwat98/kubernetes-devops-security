#!/bin/bash
trivy fs --security-checks config --severity HIGH,CRITICAL \
    --format table k8s_deployment_service.yaml
    
trivy fs --security-checks config --severity HIGH,CRITICAL \
    --format json --output trivy-k8s-results.json k8s_deployment_service.yaml
