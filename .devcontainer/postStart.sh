#!/bin/bash
# postStart.sh
#
# Runs inside the dev container on EVERY codespace start or resume.
# Intentionally lightweight — only prints the service URLs.
# Heavy setup is done once in postCreate.sh.

if [ -n "${CODESPACE_NAME:-}" ]; then
  DOMAIN="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
  echo ""
  echo "=== AI Stack is running ==="
  echo "  n8n      https://${CODESPACE_NAME}-5678.${DOMAIN}/"
  echo "  SearXNG  https://${CODESPACE_NAME}-8080.${DOMAIN}/"
  echo "  Ollama   https://${CODESPACE_NAME}-11434.${DOMAIN}/"
  echo "==========================="
  echo ""
else
  echo ""
  echo "=== AI Stack is running ==="
  echo "  n8n      http://localhost:5678"
  echo "  SearXNG  http://localhost:8080"
  echo "  Ollama   http://localhost:11434"
  echo "==========================="
  echo ""
fi
