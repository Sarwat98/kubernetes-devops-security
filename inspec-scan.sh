#!/usr/bin/env bash
set -e

# 1. Set license acceptance through all possible methods
export CHEF_LICENSE="accept-silent"

# 2. Ensure Jenkins home directory exists and has correct permissions
JENKINS_HOME="/var/lib/jenkins"
sudo mkdir -p "$JENKINS_HOME/.chef/accepted_licenses"
sudo chown -R jenkins:jenkins "$JENKINS_HOME/.chef"
sudo chmod -R 755 "$JENKINS_HOME/.chef"

# 3. Write license acceptance file
echo "accept" | sudo tee "$JENKINS_HOME/.chef/accepted_licenses/inspec" >/dev/null

# 4. Add system-wide acceptance if possible (optional)
sudo mkdir -p /etc/chef/accepted_licenses
echo "accept" | sudo tee /etc/chef/accepted_licenses/inspec >/dev/null

# 5. Debugging output
echo "License acceptance locations:"
ls -la "$JENKINS_HOME/.chef/accepted_licenses/" 2>/dev/null || echo "No user license found"
ls -la "/etc/chef/accepted_licenses/" 2>/dev/null || echo "No system license found"

# 6. Run InSpec with all license acceptance methods
sudo inspec exec k8s-deploy-audit -t local:// \
  --input ns=prod deploy_name=devsecops label_key=app label_val=devsecops \
  --input ignore_containers="istio-proxy" \
  --chef-license accept-silent \
  --reporter cli