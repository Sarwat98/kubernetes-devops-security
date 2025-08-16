#!/usr/bin/env bash
set -euo pipefail

# 1) Accept license for the current user (Jenkins)
export CHEF_LICENSE=accept-silent
mkdir -p "$HOME/.chef/accepted_licenses"
echo accept > "$HOME/.chef/accepted_licenses/inspec"

# 2) Quick sanity
echo "whoami=$(whoami)  HOME=$HOME"
which inspec
CHEF_LICENSE=accept-silent inspec version

# 3) (Optional) Static check
CHEF_LICENSE=accept-silent inspec check k8s-deploy-audit --chef-license accept-silent

# 4) Run the scan
CHEF_LICENSE=accept-silent inspec exec k8s-deploy-audit -t local:// \
  --input ns=prod deploy_name=devsecops label_key=app label_val=devsecops \
  --input ignore_containers="istio-proxy" \
  --chef-license accept-silent \
  --reporter cli
