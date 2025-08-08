#!/bin/bash
# trivy-k8s-scan.sh

# Getting Image name from env variable
echo $imageName

# Scan for LOW, MEDIUM, HIGH severity vulnerabilities
docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.17.2 -q image --exit-code 0 --severity LOW,MEDIUM,HIGH --light $imageName

# Scan for CRITICAL severity vulnerabilities and set exit code if found
docker run --rm -v $WORKSPACE:/root/.cache/ aquasec/trivy:0.17.2 -q image --exit-code 0 --severity CRITICAL --light $imageName

# Capture the exit code from the last scan
exit_code=$?

# Check scan results
if [[ ${exit_code} == 1 ]]; then
  echo "Image scanning failed. Vulnerabilities found"
  exit 1
else
  echo "Image scanning passed. No vulnerabilities found"
fi
