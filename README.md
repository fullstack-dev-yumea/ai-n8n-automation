# AI Automation Stack

GitHub Codespace pre-configured with:

| Service | Port | Description |
|---------|------|-------------|
| **n8n** | 5678 | Workflow automation UI |
| **Ollama** | 11434 | Local LLM inference (gemma3:4b) |
| **SearXNG** | 8080 | Private meta search engine |
| **Valkey** | 6379 | Redis-compatible cache (internal) |

Everything starts automatically — no manual commands needed.

---

## Quick Start

### 1. Recommended: Set GitHub Codespaces Secrets (do this ONCE before creating the codespace)

This step ensures your n8n credentials survive if the codespace is deleted and recreated.

1. Generate a key on your local machine:
   ```bash
   openssl rand -hex 32
   ```
2. Go to **GitHub → Your Repo → Settings → Secrets and variables → Codespaces → New repository secret**
3. Add secret:
   - **Name**: `N8N_ENCRYPTION_KEY`
   - **Value**: the hex string from step 1

> If you skip this step, a random key is generated each time. Credentials work fine but are **lost if the codespace is deleted**.

### 2. Create the Codespace

Click **Code → Codespaces → Create codespace on main** in your GitHub repo.

GitHub Codespaces requires at least **8 GB RAM / 4 CPUs** (enforced via `hostRequirements`).

### 3. Wait for initialization (~5–10 min on first start)

The codespace:
1. Generates secrets and config (`initializeCommand.sh`)
2. Starts all containers via Docker Compose
3. Pulls `gemma3:4b` from Ollama (~3.3 GB — first start only if the volume is intact)
4. Displays service URLs in the terminal

When a notification appears for **"n8n UI"**, click **Open in Browser** (or use the URLs shown in the terminal).

---

## Service URLs

| Service | Codespaces URL pattern | Local URL |
|---------|----------------------|-----------|
| n8n | `https://<codespace-name>-5678.app.github.dev/` | `http://localhost:5678` |
| SearXNG | `https://<codespace-name>-8080.app.github.dev/` | `http://localhost:8080` |
| Ollama | `https://<codespace-name>-11434.app.github.dev/` | `http://localhost:11434` |

---

## Using n8n with Ollama and SearXNG

When configuring n8n nodes, use these **internal Docker network URLs** (they work from any workflow node):

| Destination | URL to use in n8n |
|-------------|-------------------|
| Ollama REST API | `http://ollama:11434/api/generate` |
| Ollama (OpenAI-compatible) | `http://ollama:11434/v1` |
| SearXNG JSON search | `http://searxng:8080/search?q=your+query&format=json` |

### Example: SearXNG search from n8n

Add an **HTTP Request** node with:
- Method: `GET`
- URL: `http://searxng:8080/search`
- Query parameters: `q=your search`, `format=json`

### Example: Ollama chat from n8n

Add an **HTTP Request** node with:
- Method: `POST`
- URL: `http://ollama:11434/api/chat`
- Body (JSON):
  ```json
  {
    "model": "gemma3:4b",
    "messages": [{"role": "user", "content": "Hello!"}],
    "stream": false
  }
  ```

Or use the **Ollama node** / **LangChain Ollama node** in n8n and set the base URL to `http://ollama:11434`.

---

## Data Persistence

| Data | Persists between suspensions | Persists after codespace deletion |
|------|------------------------------|-----------------------------------|
| Ollama model (volume) | Yes | **No** — re-downloaded (~3.3 GB) |
| n8n workflows (`n8n-data/`) | Yes (git) | Yes (committed to repo) |
| n8n credentials (encrypted) | Yes (git) | **Yes — only if `N8N_ENCRYPTION_KEY` is a GitHub Secret** |
| `.devcontainer/.env` | Yes (VM) | No — regenerated on next start |

> **Do not commit `.devcontainer/.env`** — it is gitignored and contains your encryption keys.

> **Never change `N8N_ENCRYPTION_KEY`** after saving credentials in n8n. A changed key makes all stored credentials permanently unreadable.

---

## Monitoring

```bash
# Watch all service logs
docker compose -f .devcontainer/docker-compose.yml logs -f

# Watch Ollama model pull progress
docker compose -f .devcontainer/docker-compose.yml logs -f ollama

# Check service health
docker compose -f .devcontainer/docker-compose.yml ps
```

---

## Project Structure

```
.devcontainer/
  devcontainer.json          # Codespaces config (ports, lifecycle hooks)
  docker-compose.yml         # 5-service stack
  initializeCommand.sh       # Runs on host before containers — generates secrets
  ollama-entrypoint.sh       # Auto-pulls gemma3:4b on first Ollama start
  postCreate.sh              # Runs once after codespace creation
  postStart.sh               # Runs on every codespace start/resume
  .env.example               # Template for .env (committed)
  .env                       # Generated secrets — GITIGNORED
  searxng/
    settings.yml.example     # SearXNG config template (committed)
    settings.yml             # Generated with real secret — GITIGNORED
    limiter.toml             # Rate-limiter config (permissive for n8n)
    uwsgi.ini                # uWSGI server config (HTTP on port 8080)
n8n-data/
  .gitkeep                   # Creates the directory in git
  *.sqlite                   # n8n database — GITIGNORED
README.md
.gitignore
```
