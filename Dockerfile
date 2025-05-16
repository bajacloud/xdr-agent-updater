FROM bitnami/kubectl:1.33.1-debian-12-r0

LABEL maintainer="toquiwokey" \
      org.opencontainers.image.title="Cortex XDR Agent Updater" \
      org.opencontainers.image.description="Automatically updates XDR agent to latest version in Kubernetes" \
      org.opencontainers.image.source="https://github.com/bajacloud/xdr-agent-updater"

USER 0
RUN install_packages jq skopeo

COPY xdr-agent-updater.sh /usr/local/bin/xdr-agent-updater.sh
RUN chmod +x /usr/local/bin/xdr-agent-updater.sh

USER 1001
ENTRYPOINT ["/usr/local/bin/xdr-agent-updater.sh"]

