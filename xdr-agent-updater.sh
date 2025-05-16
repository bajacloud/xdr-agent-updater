#!/bin/bash

set -euo pipefail

# Config
NAMESPACE="cortex-xdr"
IMAGE_REPO="us-central1-docker.pkg.dev/xdr-us-1002203369220/agent-docker/cortex-agent"
DAEMONSET_NAME="cortex-agent"
CONTAINER_NAME="cortex-agent"
AUTHFILE="/root/.docker/config.json"

# Step 1: Fetch latest tag (excluding 'latest')
echo "Checking registry for latest Cortex agent version..."

latest_version=$(skopeo list-tags docker://$IMAGE_REPO \
  --authfile "$AUTHFILE" | \
  jq -r '.Tags[]' | grep -v '^latest$' | sort -V | tail -n1)

if [[ -z "$latest_version" ]]; then
  echo "Could not determine latest version."
  exit 1
fi

echo "Latest available agent version: $latest_version"

# Step 2: Get current DaemonSet version
current_image=$(kubectl get daemonset "$DAEMONSET_NAME" -n "$NAMESPACE" \
  -o jsonpath='{.spec.template.spec.containers[0].image}')

current_version=$(echo "$current_image" | awk -F: '{print $2}')
echo "Current deployed version: $current_version"

# Step 3: Compare and update
if [[ "$current_version" == "$latest_version" ]]; then
  echo "Agent is already up-to-date."
else
  echo "Updating agent to version $latest_version..."
  kubectl set image daemonset/$DAEMONSET_NAME \
    $CONTAINER_NAME=$IMAGE_REPO:$latest_version \
    -n "$NAMESPACE"
  echo "DaemonSet update triggered."
fi

