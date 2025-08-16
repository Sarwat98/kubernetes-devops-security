#!/usr/bin/env bash
set -e

# accept license for the jenkins user (no prompts)
export CHEF_LICENSE=accept-silent
mkdir -p "$HOME/.chef/accepted_licenses"
echo accept > "$HOME/.chef/accepted_licenses/inspec"

# run your profile
inspec exec k8s-deploy-audit -t local:// \
  --input ns=prod deploy_name=devsecops label_key=app label_val=devsecops \
  --input ignore_containers="istio-proxy" \
  --chef-license accept-silent \
  --reporter cli
