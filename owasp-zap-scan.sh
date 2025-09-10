#!/bin/bash
PORT=$(kubectl -n default get svc ${serviceName} -o json | jq .spec.ports[].nodePort)
echo $PORT
echo $applicationURL:$PORT

mkdir owasp-zap-report
docker run -v $(pwd)/owasp-zap-report:/zap/wrk/:rw \
    -t owasp/zap2docker-stable zap-baseline.py \
    -t $applicationURL:$PORT/$applicationURI || true
