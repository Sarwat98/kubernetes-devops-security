#!/bin/bash
sleep 5s

# Use K3s embedded kubectl with full path
KUBECTL_CMD="sudo /usr/local/bin/k3s kubectl"

# Use jq -r to get raw output without quotes
PORT=$(${KUBECTL_CMD} -n default get svc ${serviceName} -o json | jq -r '.spec.ports[].nodePort')

echo $PORT
echo $applicationURL:$PORT/$applicationURI

# Better check: use -n for "not empty"
if [[ -n "$PORT" ]]; then
    # Properly quote the URL components
    response=$(curl -s "${applicationURL}:${PORT}/${applicationURI}")
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "${applicationURL}:${PORT}/${applicationURI}")
    
    if [[ "$response" == "100" ]] && [[ "$http_code" == "200" ]]; then
        echo "Increment Test Passed"
    else
        echo "Increment Test Failed"
        echo "Response: $response, HTTP Code: $http_code"
        exit 1
    fi
else
    echo "The Service does not have a NodePort"
    exit 1
fi
