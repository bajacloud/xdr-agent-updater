#!/bin/bash

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────
NAMESPACE="cortex-xdr"
DAEMONSET_NAME="cortex-agent"
CONTAINER_NAME="cortex-agent"
DOCKER_CONFIG="/tmp/docker"
AUTHFILE="${DOCKER_CONFIG}/config.json"

# ─────────────────────────────────────────────────────────────
# Discover current image from DaemonSet
# ─────────────────────────────────────────────────────────────
echo "Discovering image registry from current DaemonSet..."

current_image=$(kubectl -n "$NAMESPACE" get daemonset "$DAEMONSET_NAME" \
  -o jsonpath="{.spec.template.spec.containers[?(@.name==\"$CONTAINER_NAME\")].image}")

if [[ -z "$current_image" ]]; then
  echo "ERROR: Failed to retrieve current image from DaemonSet."
  exit 1
fi

current_tag="${current_image##*:}"
image_repo="${current_image%:*}"

echo "🔍 Current image: $current_image"
echo "🔍 Current tag: $current_tag"
echo "🔍 Image repo: $image_repo"

# ─────────────────────────────────────────────────────────────
# Validate Docker auth file
# ─────────────────────────────────────────────────────────────
if [[ ! -r "$AUTHFILE" ]]; then
  echo "ERROR: Docker auth file not found or unreadable at $AUTHFILE"
  exit 1
fi

echo "🔐 Docker credentials loaded."

# ─────────────────────────────────────────────────────────────
# Discover latest available tag using skopeo
# ─────────────────────────────────────────────────────────────
echo "Querying registry for available tags..."

latest_tag=$(skopeo list-tags --authfile "$AUTHFILE" "docker://${image_repo}" \
  | jq -r '.Tags[]' \
  | grep -E '^[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?$' \
  | sort -Vr \
  | head -n1)

if [[ -z "$latest_tag" ]]; then
  echo "ERROR: Unable to determine the latest tag from the registry."
  exit 1
fi

echo "🆕 Latest available version: $latest_tag"

# ─────────────────────────────────────────────────────────────
# Compare and patch if needed
# ─────────────────────────────────────────────────────────────
if [[ "$current_tag" == "$latest_tag" ]]; then
  echo "Agent is already using the latest version."
  exit 0
fi

echo "Updating DaemonSet to use new image: ${image_repo}:${latest_tag}"

kubectl -n "$NAMESPACE" set image daemonset/"$DAEMONSET_NAME" \
  "$CONTAINER_NAME"="${image_repo}:${latest_tag}" \
  --record

echo "Update complete. New image in use: ${image_repo}:${latest_tag}"



