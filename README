# n8n + Cloudflare Tunnel + External Runners

Multi-container Compose stack: `n8n` serves HTTPS with your cert/key, `cloudflared` handles the tunnel, and dedicated runner containers execute workflows. No host ports are published.

## What this includes
- `n8n` (`n8nio/n8n:next`) with your TLS cert/key mounted
- `cloudflared` (`cloudflare/cloudflared`) using a token-based tunnel
- External runners (`n8nio/runners:next`) for JavaScript and Python
- Two networks: `n8n_internal` (internal: true) for ingress only; `n8n_egress` for outbound calls. No LAN exposure.
- Named volume `n8n_data` for n8n state

## Prerequisites
- Docker and Docker Compose v2
- Cloudflare tunnel token
- TLS cert and key for `N8N_HOST` (provide your own domain)

## Configuration
`.env` (git-ignored) should define at least:
- `TUNNEL_TOKEN`
- `CERT_FILE` / `KEY_FILE` (filenames in repo root)
- `N8N_HOST` (e.g., `n8n.example.com`)
- `N8N_RUNNERS_AUTH_TOKEN` (shared secret for runners)
- `N8N_TRUSTED_PROXIES` — set to your Docker/loopback subnets (e.g., `127.0.0.1/8,172.30.10.0/24,172.30.11.0/24`)
- Optional: `N8N_RUNNERS_INSTANCE_URL` (defaults to `https://<your N8N_HOST>`), concurrency/timeouts, custom subnets

Cloudflare ingress (set in Zero Trust dashboard, token-managed tunnel):
- Service URL: `https://<your N8N_HOST>:443` (must be a literal value, not `${...}`)
- Turn off “No TLS verify”; set Origin Host Header to `N8N_HOST`

Cloudflared config file:
- Copy `cloudflared-config.example.yml` to `cloudflared-config.yml` (git-ignored), then replace the placeholder domain/port with your actual values (no `${...}` expansions inside the file). Or supply a custom path via `CLOUDFLARED_CONFIG_PATH`.
- The same cert is mounted as `origin-ca.pem` for verification.

## Run
1) Place cert/key in repo root and populate `.env` (including runner auth token).
2) Start: `docker compose up -d`
3) Check logs: `docker compose logs -f cloudflared n8n n8n-runner n8n-runner-python`

## Notes
- Ingress flows over `n8n_internal`; outbound API calls use `n8n_egress`.
- Runners auto-shutdown when idle (configurable via `.env`).
- No host ports are exposed; access is through the Cloudflare tunnel using `N8N_HOST`. TLS hostname must match your cert/host.
- Trust proxy must be configured (via `N8N_TRUSTED_PROXIES`) so Express honors `X-Forwarded-For` and rate limits per client.
