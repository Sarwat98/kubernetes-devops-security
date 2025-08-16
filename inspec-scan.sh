#!/usr/bin/env bash
set -e

# Add this to your script before the inspec command
sudo chown -R jenkins:jenkins "$HOME/.chef"

# Add to your script
sudo mkdir -p /etc/chef/accepted_licenses
sudo echo accept > /etc/chef/accepted_licenses/inspec

# accept license for the jenkins user (no prompts)
export CHEF_LICENSE=accept-silent
mkdir -p "$HOME/.chef/accepted_licenses"
echo accept > "$HOME/.chef/accepted_licenses/inspec"

# Print environment for debugging
env | sort

# run your profile
inspec exec k8s-deploy-audit -t local:// \
  --input ns=prod deploy_name=devsecops label_key=app label_val=devsecops \
  --input ignore_containers="istio-proxy" \
  --chef-license accept-silent \
  --reporter cli
