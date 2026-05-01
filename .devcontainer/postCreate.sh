#!/bin/bash
# postCreate.sh
#
# Runs ONCE inside the dev container after the codespace is first created.
# - Ensures n8n-data/ has the correct permissions for uid 1000 (n8n user).
# - Waits for n8n to respond (up to 120 s) before displaying the service URLs.
# - n8n is reached at http://n8n:5678 via the Docker Compose internal network
#   (NOT localhost — n8n is a separate container).

set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMEOUT=120
INTERVAL=3

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║       AI Automation Stack — First-Run Setup      ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Ensure n8n-data permissions ───────────────────────────────────────────────
# n8n runs as uid 1000 inside its container. Ensure the mounted directory
# is writable by that uid (same as the workspace owner in Codespaces).
echo "[setup] Ensuring n8n-data/ is writable by uid 1000 ..."
mkdir -p "${WORKSPACE_ROOT}/n8n-data"
chmod 755 "${WORKSPACE_ROOT}/n8n-data"
echo "[setup] Done."
echo ""

# ── Wait for n8n ──────────────────────────────────────────────────────────────
echo "[setup] Waiting for n8n to start at http://n8n:5678 ..."
ELAPSED=0
N8N_READY=false

until curl -sf --max-time 3 http://n8n:5678 > /dev/null 2>&1; do
  if [ "${ELAPSED}" -ge "${TIMEOUT}" ]; then
    echo ""
    echo "[setup] WARNING: n8n did not respond within ${TIMEOUT}s."
    echo "        It may still be initialising. Check with:"
    echo "          docker compose -f .devcontainer/docker-compose.yml logs n8n"
    break
  fi
  printf "."
  sleep "${INTERVAL}"
  ELAPSED=$((ELAPSED + INTERVAL))
done

if curl -sf --max-time 3 http://n8n:5678 > /dev/null 2>&1; then
  N8N_READY=true
  echo ""
  echo "[setup] n8n is ready."
fi
echo ""

# ── Display service URLs ───────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════╗"
echo "║                  Service URLs                   ║"
echo "╠══════════════════════════════════════════════════╣"

if [ -n "${CODESPACE_NAME:-}" ]; then
  DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  echo "║  n8n      https://${CODESPACE_NAME}-5678.${DOMAIN}/"
  echo "║  SearXNG  https://${CODESPACE_NAME}-8080.${DOMAIN}/"
  echo "║  Ollama   https://${CODESPACE_NAME}-11434.${DOMAIN}/"
else
  echo "║  n8n      http://localhost:5678"
  echo "║  SearXNG  http://localhost:8080"
  echo "║  Ollama   http://localhost:11434"
fi

echo "╠══════════════════════════════════════════════════╣"
echo "║  Internal (Docker network — use in n8n nodes):  ║"
echo "║  Ollama   http://ollama:11434                   ║"
echo "║  SearXNG  http://searxng:8080                   ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "NOTE: Ollama may still be pulling gemma3:4b (~3.3 GB)."
echo "      Monitor progress: docker compose -f .devcontainer/docker-compose.yml logs -f ollama"
echo ""
