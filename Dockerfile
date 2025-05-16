# syntax=docker/dockerfile:1

FROM debian:bookworm-slim AS base

LABEL maintainer="toquiwokey" \
      org.opencontainers.image.title="Cortex XDR Agent Updater" \
      org.opencontainers.image.description="Checks latest Cortex XDR agent image version and updates DaemonSet if needed" \
      org.opencontainers.image.source="https://github.com/bajacloud/upgradertron"

# Set environment
ENV DEBIAN_FRONTEND=noninteractive

# Install required tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        bash \
        jq \
        skopeo \
        kubectl \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd --system --create-home --shell /bin/bash updater

# Copy the script
COPY xdr-agent-updater.sh /usr/local/bin/xdr-agent-updater.sh

# Set permissions
RUN chmod +x /usr/local/bin/xdr-agent-updater.sh && \
    chown updater:updater /usr/local/bin/xdr-agent-updater.sh

# Switch to non-root user (optional – can run as root if needed for kubectl access)
USER updater

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/xdr-agent-updater.sh"]
