#!/usr/bin/env bash
# Deploy official Hermes WebUI + Hermes Agent on a VPS (no sudo).
# Run from this repo as the ubuntu user:
#   git pull && bash deploy.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_HOME="${HERMES_HOME:-${HOME}/.hermes}"
AGENT_DIR="${HERMES_WEBUI_AGENT_DIR:-${HERMES_HOME}/hermes-agent}"
AGENT_REPO="${HERMES_AGENT_REPO:-https://github.com/NousResearch/hermes-agent.git}"
WORKSPACE="${HERMES_WEBUI_DEFAULT_WORKSPACE:-${HOME}/workspace}"
HOST="${HERMES_WEBUI_HOST:-0.0.0.0}"
PORT="${HERMES_WEBUI_PORT:-8787}"
BANDEL_URL="${BANDEL_BASE_URL:-https://bandelbanget.xyz/v1}"
BANDEL_MODEL="${BANDEL_MODEL:-glm-5.3}"
BANDEL_KEY="${BANDEL_API_KEY:-sk-qwen-22d837c591d282ecaf62a3b2851364b208c27fdee9a49bb5}"

log() { printf '[deploy] %s\n' "$*"; }
die() { printf '[deploy] ERROR: %s\n' "$*" >&2; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || die "butuh perintah: $1"; }

need git
need python3

mkdir -p "${HERMES_HOME}" "${WORKSPACE}" "${HERMES_HOME}/skills" "${HERMES_HOME}/webui"

# Stop leftover mashup / previous WebUI without sudo.
log "menghentikan proses lama di port ${PORT} (tanpa sudo)"
if [[ -x "${REPO_ROOT}/ctl.sh" ]]; then
  (cd "${REPO_ROOT}" && ./ctl.sh stop) || true
fi
if command -v ss >/dev/null 2>&1; then
  old_pids="$(ss -tlnp 2>/dev/null | awk -v p=":${PORT}" '$4 ~ p"$" {print}' | sed -n 's/.*pid=\([0-9]*\).*/\1/p' | sort -u || true)"
  for pid in ${old_pids}; do
    if [[ "${pid}" =~ ^[0-9]+$ ]] && [[ "${pid}" != "$$" ]]; then
      kill "${pid}" >/dev/null 2>&1 || true
    fi
  done
fi
# Old custom mashup
pkill -f "${REPO_ROOT}/server.py" >/dev/null 2>&1 || true
sleep 1

# Hermes Agent lives outside this git repo (too large to commit).
if [[ ! -d "${AGENT_DIR}/.git" ]]; then
  log "clone Hermes Agent → ${AGENT_DIR}"
  git clone --depth 1 "${AGENT_REPO}" "${AGENT_DIR}"
else
  log "update Hermes Agent di ${AGENT_DIR}"
  git -C "${AGENT_DIR}" fetch --depth 1 origin || true
  git -C "${AGENT_DIR}" reset --hard origin/main 2>/dev/null \
    || git -C "${AGENT_DIR}" pull --ff-only || true
fi

if [[ ! -x "${AGENT_DIR}/venv/bin/python" ]]; then
  log "buat venv agent"
  python3 -m venv "${AGENT_DIR}/venv"
fi
# shellcheck disable=SC1091
source "${AGENT_DIR}/venv/bin/activate"
python -m pip install -U pip setuptools wheel >/dev/null
log "install dependensi agent (bisa lama)"
if [[ -f "${AGENT_DIR}/requirements.txt" ]]; then
  python -m pip install -r "${AGENT_DIR}/requirements.txt"
fi
if [[ -f "${AGENT_DIR}/pyproject.toml" ]]; then
  python -m pip install -e "${AGENT_DIR}" || true
fi
if [[ -f "${REPO_ROOT}/requirements.txt" ]]; then
  python -m pip install -r "${REPO_ROOT}/requirements.txt"
fi

# Seed ~/.hermes/config.yaml only if missing so we never clobber a live setup.
if [[ ! -f "${HERMES_HOME}/config.yaml" ]]; then
  log "seed ${HERMES_HOME}/config.yaml (Bandel custom OpenAI-compatible)"
  cat > "${HERMES_HOME}/config.yaml" <<YAML
model:
  provider: custom
  default: ${BANDEL_MODEL}
  base_url: ${BANDEL_URL}
  api_key: ${BANDEL_KEY}
custom_providers:
  - name: bandel
    base_url: ${BANDEL_URL}
    api_key: ${BANDEL_KEY}
    model: ${BANDEL_MODEL}
agent:
  max_turns: 40
terminal:
  backend: local
YAML
else
  log "config.yaml sudah ada — tidak ditimpa"
fi

if [[ ! -f "${HERMES_HOME}/.env" ]]; then
  cat > "${HERMES_HOME}/.env" <<ENV
OPENAI_API_KEY=${BANDEL_KEY}
HERMES_YOLO_MODE=1
HERMES_EXEC_ASK=0
ENV
  chmod 600 "${HERMES_HOME}/.env"
fi

# Extra skills (copied, never overwrite existing user edits).
if [[ -d "${REPO_ROOT}/deploy/skills" ]]; then
  log "salin skill tambahan"
  while IFS= read -r -d '' skill_md; do
    rel="${skill_md#${REPO_ROOT}/deploy/skills/}"
    dest="${HERMES_HOME}/skills/${rel}"
    mkdir -p "$(dirname "${dest}")"
    if [[ ! -f "${dest}" ]]; then
      cp "${skill_md}" "${dest}"
    fi
  done < <(find "${REPO_ROOT}/deploy/skills" -name SKILL.md -print0)
fi

# Repo .env for official start.sh / ctl.sh
cat > "${REPO_ROOT}/.env" <<ENV
HERMES_HOME=${HERMES_HOME}
HERMES_WEBUI_AGENT_DIR=${AGENT_DIR}
HERMES_WEBUI_PYTHON=${AGENT_DIR}/venv/bin/python
HERMES_WEBUI_HOST=${HOST}
HERMES_WEBUI_PORT=${PORT}
HERMES_WEBUI_SKIP_ONBOARDING=1
HERMES_WEBUI_NO_SANDBOX=1
HERMES_NO_SANDBOX=1
HERMES_EXEC_ASK=0
HERMES_YOLO_MODE=1
HERMES_WEBUI_DEFAULT_WORKSPACE=${WORKSPACE}
HERMES_WEBUI_BOT_NAME=Hermes
HERMES_WEBUI_AUTO_INSTALL=1
OPENAI_API_KEY=${BANDEL_KEY}
ENV
chmod 600 "${REPO_ROOT}/.env"

export HERMES_HOME HERMES_WEBUI_AGENT_DIR
export HERMES_WEBUI_PYTHON="${AGENT_DIR}/venv/bin/python"
export HERMES_WEBUI_HOST="${HOST}"
export HERMES_WEBUI_PORT="${PORT}"
export HERMES_WEBUI_SKIP_ONBOARDING=1
export HERMES_WEBUI_NO_SANDBOX=1
export HERMES_YOLO_MODE=1
export HERMES_EXEC_ASK=0

log "start WebUI via ctl.sh"
cd "${REPO_ROOT}"
# Agent bootstrap can take several minutes on first install.
export HERMES_WEBUI_START_GRACE="${HERMES_WEBUI_START_GRACE:-90}"
./ctl.sh restart --no-browser --foreground

log "siap. buka http://$(hostname -I 2>/dev/null | awk '{print $1}'):${PORT} atau http://202.155.143.143:${PORT}"
./ctl.sh status || true
}
