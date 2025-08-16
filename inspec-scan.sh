#!/usr/bin/env bash
set -e

# Accept in both locations
export CHEF_LICENSE="accept-silent"
mkdir -p "$HOME/.chef/accepted_licenses"
echo "accept" > "$HOME/.chef/accepted_licenses/inspec"

# Only try system location if we have sudo
if sudo -n true 2>/dev/null; then
  sudo mkdir -p /etc/chef/accepted_licenses
  sudo bash -c 'echo "accept" > /etc/chef/accepted_licenses/inspec'
fi

# Run your profile
inspec exec k8s-deploy-audit -t local:// \
  --input ns=prod deploy_name=devsecops label_key=app label_val=devsecops \
  --input ignore_containers="istio-proxy" \
  --chef-license accept-silent \
  --reporter cli