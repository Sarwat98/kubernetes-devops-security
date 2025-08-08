#!/bin/bash
# kubesec-scan.sh

# --- Using the Kubesec v2 API directly ---
scan_result=$(curl -sSX POST --data-binary @"k8s_deployment_service.yaml" https://v2.kubesec.io/scan)
scan_message=$(curl -sSX POST --data-binary @"k8s_deployment_service.yaml" https://v2.kubesec.io/scan | jq '.[0].message' -r)
scan_score=$(curl -sSX POST --data-binary @"k8s_deployment_service.yaml" https://v2.kubesec.io/scan | jq '.[0].score')

# --- Alternative: use the Kubesec Docker image (offline) ---
# scan_result=$(docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < k8s_deployment_service.yaml)
# scan_message=$(docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < k8s_deployment_service.yaml | jq '.[].message' -r)
# scan_score=$(docker run -i kubesec/kubesec:512c5e0 scan /dev/stdin < k8s_deployment_service.yaml | jq '.[].score')

# --- Kubesec scan result processing ---
# echo "Scan Score: ${scan_score}"

if [[ "${scan_score}" -ge 5 ]]; then
  echo "Score is ${scan_score}"
  echo "Kubesec Scan ${scan_message}"
else
  echo "Score is ${scan_score}, which is less than or equal to 5."
  echo "Scanning Kubernetes Resource has Failed"
  exit 1
fi
