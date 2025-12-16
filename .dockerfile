# Use the official n8n image as the base
FROM n8nio/n8n:next

# Install dependencies for cloudflared
USER root
RUN set -eux; \
    if command -v apt-get >/dev/null 2>&1; then \
      apt-get update; \
      apt-get install -y --no-install-recommends curl ca-certificates bash; \
      rm -rf /var/lib/apt/lists/*; \
    elif command -v apk >/dev/null 2>&1; then \
      apk add --no-cache curl ca-certificates bash; \
    else \
      echo "Unsupported base image: need apt-get or apk" >&2; \
      exit 1; \
    fi

# Fetch the latest cloudflared release
RUN set -eux; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64) cloud_arch=amd64 ;; \
      aarch64|arm64) cloud_arch=arm64 ;; \
      armv7l|armv6l) cloud_arch=arm ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${cloud_arch}" \
      -o /usr/local/bin/cloudflared; \
    chmod +x /usr/local/bin/cloudflared

    
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/bash
set -euo pipefail

# Start cloudflared in the background only when a token is provided
if [ -n "${TUNNEL_TOKEN:-}" ]; then
  /usr/local/bin/cloudflared tunnel --no-autoupdate run --token "${TUNNEL_TOKEN}" > /dev/stdout 2>&1 &
fi

# Switch to node user and start n8n
exec su -s /bin/sh node -c "n8n start"
EOF


RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh

# Run as root to manage both processes
USER root
WORKDIR /home/node/n8n
ENV N8N_CUSTOM_EXTENSIONS=/home/node/n8n/custom
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
CMD []
