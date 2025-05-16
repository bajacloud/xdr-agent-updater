# Cortex XDR Agent Updater (for Kubernetes)

This lightweight container automates the process of checking for newer versions of the Cortex XDR agent and updates the DaemonSet running in your Kubernetes cluster.  NOT AN OFFICIAL PALO ALTO NETWORKS TOOL.  USE AT YOUR OWN RISK.

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

- **RBAC** is required to allow the job/cronjob to read and patch the XDR DaemonSet:
  - `get`, `list`, `patch`, `update` on `daemonsets`
- The container runs as a **non-root user** (`USER 1001`).
- The Docker registry credentials are mounted read-only into the pod from an existing secret.

---

## Quick Way To Run, ad-hoc
kubectl -n cortex-xdr delete job xdr-agent-updater-manual --ignore-not-found && \
kubectl -n cortex-xdr apply -f https://raw.githubusercontent.com/bajacloud/xdr-agent-updater/main/k8s/job.yaml && \
sleep 2 && \
kubectl -n cortex-xdr logs -f job/xdr-agent-updater-manual

## To run as a daily cronjob
kubectl -n cortex-xdr apply -f https://raw.githubusercontent.com/bajacloud/xdr-agent-updater/main/k8s/cronjob.yaml && \
kubectl -n cortex-xdr create job --from=cronjob/xdr-agent-updater xdr-agent-updater-now && \
sleep 2 && \
kubectl -n cortex-xdr logs -f job/xdr-agent-updater-now



---
License
MIT License