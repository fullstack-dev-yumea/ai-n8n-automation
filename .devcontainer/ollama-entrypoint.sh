#!/bin/bash
# ollama-entrypoint.sh
#
# Custom entrypoint for the Ollama container.
# 1. Starts the Ollama server in the background (PID kept as $SERVE_PID).
# 2. Waits for the server to become ready using `ollama list`
#    (curl is NOT available in the ollama/ollama base image).
# 3. Pulls gemma3:4b with up to 3 retry attempts.
# 4. Calls `wait` on the server PID so this script stays alive as PID 1.
#
# The model (~3.3 GB) is pulled on first start. Subsequent starts reuse the
# cached model from the `ollama-models` named volume.

MODEL="gemma3:4b"
MAX_ATTEMPTS=3

# ── Start Ollama server ───────────────────────────────────────────────────────
echo "[ollama] Starting ollama serve ..."
ollama serve &
SERVE_PID=$!

# ── Wait for server readiness ─────────────────────────────────────────────────
# `set +e` prevents the script from exiting while `ollama list` returns
# non-zero (expected until the server finishes initialising).
echo "[ollama] Waiting for server to be ready ..."
set +e
until ollama list > /dev/null 2>&1; do
  sleep 1
done
set -e
echo "[ollama] Server is ready."

# ── Pull model with retry ─────────────────────────────────────────────────────
echo "[ollama] Checking if ${MODEL} is already present ..."
if ollama list 2>/dev/null | grep -q "^${MODEL}"; then
  echo "[ollama] ${MODEL} already present — skipping pull."
else
  echo "[ollama] Pulling ${MODEL} (this may take several minutes on first start) ..."
  ATTEMPT=0
  until ollama pull "${MODEL}"; do
    ATTEMPT=$((ATTEMPT + 1))
    if [ "${ATTEMPT}" -ge "${MAX_ATTEMPTS}" ]; then
      echo "[ollama] ERROR: Failed to pull ${MODEL} after ${MAX_ATTEMPTS} attempts." >&2
      echo "[ollama] The server will remain running. Retry manually: ollama pull ${MODEL}" >&2
      # Do NOT exit — keep the server alive so other services can still use Ollama.
      break
    fi
    echo "[ollama] Pull attempt ${ATTEMPT}/${MAX_ATTEMPTS} failed. Retrying in 10s ..."
    sleep 10
  done
  ollama list 2>/dev/null | grep -q "^${MODEL}" && echo "[ollama] ${MODEL} is ready."
fi

# ── Keep container alive (server is PID 1 via wait) ──────────────────────────
echo "[ollama] Entrypoint complete. Handing off to ollama serve (PID ${SERVE_PID})."
wait "${SERVE_PID}"
