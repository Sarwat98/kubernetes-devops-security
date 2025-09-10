#!/bin/bash
dockerImageName=$(awk 'NR==1 {print $2}' Dockerfile)
echo $dockerImageName

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    -v $HOME/Library/Caches:/root/.cache/ aquasec/trivy:latest \
    image --exit-code 0 --severity LOW,MEDIUM,HIGH --light $dockerImageName

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
    -v $HOME/Library/Caches:/root/.cache/ aquasec/trivy:latest \
    image --exit-code 1 --severity CRITICAL --light $dockerImageName

# Trivy scan result processing
echo $? > /tmp/trivy-exit-code
if [[ $(cat /tmp/trivy-exit-code) == 1 ]]; then
    echo "Image scanning failed. Vulnerabilities found"
    exit 1;
else
    echo "Image scanning passed. No CRITICAL vulnerabilities found"
fi;
