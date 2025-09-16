#!/bin/bash
set -e

echo "=== DevSecOps Integration Test ==="
KUBECTL_CMD="sudo /usr/local/bin/k3s kubectl"
SERVICE_NAME="devsecops-svc"
APPLICATION_URI="compare/99"


if [[ "$response" == "Greater than 50" ]] && [[ "$http_code" == "200" ]]; then
    echo "Integration Test PASSED"
    echo "Application correctly responds with: $response"
    exit 0
else
    echo "Integration Test FAILED"
    echo "Expected: response='Greater than 50', http_code='200'"
    echo "Got: response='$response', http_code='$http_code'"
    
    # Try external access as additional verification
    echo "🌐 Testing external access..."
    VM_IP=$(curl -s -H "Metadata-Flavor: Google" \
      http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip 2>/dev/null || echo "unknown")
    NODE_PORT=$(${KUBECTL_CMD} get svc ${SERVICE_NAME} -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "unknown")
    
    if [[ "$VM_IP" != "unknown" ]] && [[ "$NODE_PORT" != "unknown" ]]; then
        EXTERNAL_URL="http://${VM_IP}:${NODE_PORT}/${APPLICATION_URI}"
        echo "External URL: $EXTERNAL_URL"
        
        external_response=$(timeout 10 curl -s "$EXTERNAL_URL" 2>/dev/null || echo "failed")
        echo "External response: '$external_response'"
        
        if [[ "$external_response" == "Greater than 50" ]]; then
            echo "External access also working correctly!"
            echo "Integration Test PASSED (via external access)"
            exit 0
        fi
    fi
    
    exit 1
fi
