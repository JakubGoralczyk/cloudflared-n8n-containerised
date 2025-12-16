# Use the official n8n image as the base
FROM n8nio/n8n:next

# Install dependencies for cloudflared
USER root
RUN apk add --no-cache \
        curl ca-certificates bash

# Fetch the latest cloudflared release
RUN curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
        -o /usr/local/bin/cloudflared \
    && chmod +x /usr/local/bin/cloudflared

    
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
