#!/bin/bash
set -e

echo "=== DevSecOps Integration Test ==="

# Configuration
KUBECTL_CMD="sudo /usr/local/bin/k3s kubectl"
SERVICE_NAME="devsecops-svc"
APPLICATION_URI="compare/99"

# Use port-forward method (most reliable)
echo "🔍 Testing via port-forward..."
${KUBECTL_CMD} port-forward svc/${SERVICE_NAME} 8080:8080 &
PORT_FORWARD_PID=$!
sleep 15

TEST_URL="http://localhost:8080/${APPLICATION_URI}"
echo "Testing: $TEST_URL"

response=$(timeout 30 curl -s "$TEST_URL" 2>/dev/null || echo "")
http_code=$(timeout 30 curl -s -o /dev/null -w "%{http_code}" "$TEST_URL" 2>/dev/null || echo "000")

# Clean up port-forward
kill $PORT_FORWARD_PID 2>/dev/null || true

echo "Response: '$response'"
echo "HTTP Code: $http_code"

# Updated assertion to match actual application behavior
if [[ "$response" == "Greater than 50" ]] && [[ "$http_code" == "200" ]]; then
    echo "✅ Integration Test PASSED"
    echo "Application correctly responds with: $response"
    exit 0
else
    echo "❌ Integration Test FAILED"
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
            echo "✅ External access also working correctly!"
            echo "✅ Integration Test PASSED (via external access)"
            exit 0
        fi
    fi
    
    exit 1
fi
