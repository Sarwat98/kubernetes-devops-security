#!/usr/bin/env bash
set -Eeuo pipefail

# --------- Config (override via env) ----------
PROFILE_DIR="${PROFILE_DIR:-k8s-deploy-audit}"
NS="${NS:-prod}"
DEPLOY="${DEPLOY:-devsecops}"
LABEL_KEY="${LABEL_KEY:-app}"
LABEL_VAL="${LABEL_VAL:-devsecops}"
# CSV list, e.g. "istio-proxy,sidecar-x"  (string on purpose)
IGNORE_CONTAINERS="${IGNORE_CONTAINERS:-istio-proxy}"

# --------- License (accept + optional key) ----------
mkdir -p "$HOME/.chef/accepted_licenses"
echo accept > "$HOME/.chef/accepted_licenses/inspec"
export CHEF_LICENSE="${CHEF_LICENSE:-accept-silent}"

# If you stored your license ID in Jenkins, expose it as any of these:
# (the runtime will pick whichever it understands; harmless otherwise)
if [[ -n "${PROGRESS_LICENSE_ID:-}" ]]; then
  export PROGRESS_LICENSE_ID
  export CHEF_LICENSE_ID="$PROGRESS_LICENSE_ID"
  export CHEF_LICENSE_KEY="$PROGRESS_LICENSE_ID"
fi

# --------- Keep Java coverage agents out of this step ----------
unset JAVA_TOOL_OPTIONS _JAVA_OPTIONS MAVEN_OPTS JACOCO_AGENT || true

# --------- Sanity ----------
echo "== whoami: $(whoami)"
echo "== HOME:   $HOME"
echo "== KUBECONFIG: ${KUBECONFIG:-<not set>}"
command -v inspec >/dev/null 2>&1 || {
  echo "InSpec not found in PATH. Trying to install..."
  if command -v sudo >/dev/null 2>&1; then
    curl -sSL https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec || {
      echo "Failed to install InSpec. Install it on the agent and rerun."; exit 127; }
  else
    echo "No sudo available to install InSpec. Please preinstall it on this agent."; exit 127
  fi
}
inspec version

command -v kubectl >/dev/null 2>&1 || {
  echo "WARNING: kubectl not found. Your profile shells out to kubectl; install it on the agent." >&2
}

[[ -d "$PROFILE_DIR" ]] || { echo "Profile dir '$PROFILE_DIR' not found"; exit 2; }

# --------- Static lint (fails fast with clear messages) ----------
CHEF_LICENSE=accept-silent inspec check "$PROFILE_DIR" --chef-license accept-silent

# --------- Execute scan ----------
CHEF_LICENSE=accept-silent inspec exec "$PROFILE_DIR" -t local:// \
  --input ns="$NS" deploy_name="$DEPLOY" label_key="$LABEL_KEY" label_val="$LABEL_VAL" \
  --input ignore_containers="$IGNORE_CONTAINERS" \
  --chef-license accept-silent \
  --reporter cli json:"$PROFILE_DIR/inspec.json" junit:"$PROFILE_DIR/inspec-junit.xml"
