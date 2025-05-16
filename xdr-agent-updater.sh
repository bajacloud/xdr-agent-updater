#!/bin/bash

set -euo pipefail

# Configurable vars
export NAMESPACE="cortex-xdr"
export DOCKER_CONFIG="/tmp/docker"
export AUTHFILE="$DOCKER_CONFIG/config.json"
export IMAGE_REPO="us-central1-docker.pkg.dev/xdr-us-1002203369220/agent-docker/cortex-agent"
export DAEMONSET_NAME="cortex-agent"
export CONTAINER_NAME="cortex-agent"

echo "Using AUTHFILE: $AUTHFILE"
echo "Checking latest image tag in: $IMAGE_REPO"

# Ensure auth file is readable
if [[ ! -r "$AUTHFILE" ]]; then
  echo "ERROR: Cannot read Docker auth file at $AUTHFILE"
  exit 1
fi

# Get list of tags from the image registry
latest_tag=$(skopeo list-tags --authfile "$AUTHFILE" "docker://${IMAGE_REPO}" \
  | jq -r '.Tags[]' \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' \
  | sort -Vr \
  | head -n1)

if [[ -z "$latest_tag" ]]; then
  echo "ERROR: Could not determine latest tag."
  exit 1
fi

echo "Latest available version: $latest_tag"

# Get current image from the DaemonSet
current_image=$(kubectl -n "$NAMESPACE" get daemonset "$DAEMONSET_NAME" -o jsonpath="{.spec.template.spec.containers[?(@.name==\"$CONTAINER_NAME\")].image}")

echo "Currently deployed image: $current_image"

# Extract current version (assumes it ends in :<tag>)
current_tag="${current_image##*:}"

if [[ "$current_tag" == "$latest_tag" ]]; then
  echo "Agent is up to date — no changes needed."
  exit 0
fi

echo "Updating DaemonSet to use version: $latest_tag"

# Patch DaemonSet with new image tag
kubectl -n "$NAMESPACE" set image daemonset/"$DAEMONSET_NAME" \
  "$CONTAINER_NAME"="$IMAGE_REPO:$latest_tag" \
  --record

echo "DaemonSet successfully updated to version: $latest_tag"


