# Cortex XDR Agent Updater (for Kubernetes)

This lightweight container automates the process of checking for newer versions of the Cortex XDR agent and optionally updating the DaemonSet running in your Kubernetes cluster.

---

## Purpose

Automatically keep your Cortex XDR agent updated in an EKS or Kubernetes cluster by:

- Fetching the latest available version from Palo Alto Networks' image registry
- Comparing it to the currently deployed version
- Patching the DaemonSet if a newer version is available

---

## How It Works

The container is designed to run as a Kubernetes CronJob (or on-demand Job) with the following workflow:

1. Uses `skopeo` to list tags from the Cortex XDR private image registry.
2. Authenticates using a mounted Docker registry secret (`cortex-docker-secret`).
3. Retrieves the latest non-`latest` tag available.
4. Queries the currently deployed DaemonSet and extracts the running image version.
5. If an update is needed, it uses `kubectl set image` to patch the DaemonSet.
6. Logs the result and exits.

---

## Security Considerations

- **RBAC** is required to allow the container to read and patch the XDR DaemonSet:
  - `get`, `list`, `patch`, `update` on `daemonsets`
- The container runs as a **non-root user** (`USER 1001`) for security.
- The Docker registry credentials are mounted read-only into the pod and never exposed in the container environment.

---

License
MIT License