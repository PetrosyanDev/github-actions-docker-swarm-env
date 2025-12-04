#!/bin/bash
set -euo pipefail

# ---------- INPUTS ----------
SSH_PRIVATE_KEY="${INPUT_SSH_PRIVATE_KEY:?ssh_private_key is required}"
SSH_HOST="${INPUT_SSH_HOST:?ssh_host is required}"
SSH_USER="${INPUT_SSH_USER:-root}"
SSH_REMOTE_PORT="${INPUT_SSH_REMOTE_PORT:-22}"
FILE="${INPUT_FILE:?file is required}"
STACK_NAME="${INPUT_STACK_NAME:?stack_name is required}"
ENV_LIST="${INPUT_ENV_LIST:-}"
SSH_REMOTE_KNOWN_HOSTS="${INPUT_SSH_REMOTE_KNOWN_HOSTS:-}"

# Fallback remote workdir:
# You already copy files to /home/erik/${{ github.repository }}/
# GITHUB_REPOSITORY is available inside the action container (Owner/repo)
REMOTE_WORKDIR="${INPUT_REMOTE_WORKDIR:-/home/${SSH_USER}/${GITHUB_REPOSITORY}}"

echo "DEBUG: SSH_USER='${SSH_USER}'"
echo "DEBUG: SSH_HOST='${SSH_HOST}'"
echo "DEBUG: SSH_REMOTE_PORT='${SSH_REMOTE_PORT}'"
echo "DEBUG: REMOTE_WORKDIR='${REMOTE_WORKDIR}'"
echo "DEBUG: FILE='${FILE}'"

# ---------- SSH SETUP (like the “secure” examples) ----------

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"

# Use ssh-agent + ssh-add instead of -i id_rsa
export SSH_AUTH_SOCK=/tmp/ssh_agent.sock
ssh-agent -a "${SSH_AUTH_SOCK}" > /dev/null

# Safely feed the key:
#  - fix literal '\n'
#  - strip Windows CR
if ! printf '%s' "${SSH_PRIVATE_KEY}" \
    | sed 's/\\n/\n/g' \
    | tr -d '\r' \
    | ssh-add - 2>/dev/null; then
  echo "::error::Invalid SSH private key format. Make sure ssh_private_key is a valid OpenSSH key (ideally RSA 4096 for CI)." >&2
  exit 1
fi

# known_hosts handling similar to serversideup action
KNOWN_HOSTS_FILE="${HOME}/.ssh/known_hosts"

if [ -n "${SSH_REMOTE_KNOWN_HOSTS}" ]; then
  # user-provided known_hosts line (most secure)
  printf '%s\n' "${SSH_REMOTE_KNOWN_HOSTS}" > "${KNOWN_HOSTS_FILE}"
  chmod 644 "${KNOWN_HOSTS_FILE}"
else
  # fall back to ssh-keyscan
  echo "::warning::No ssh_remote_known_hosts provided. Using ssh-keyscan (less secure)."
  ssh-keyscan -p "${SSH_REMOTE_PORT}" -H "${SSH_HOST}" >> "${KNOWN_HOSTS_FILE}" 2>/dev/null || true
  chmod 644 "${KNOWN_HOSTS_FILE}"
fi

# ---------- BUILD ENV EXPORT STRING (your original logic) ----------

ENV_EXPORTS=""
if [ -n "${ENV_LIST}" ]; then
  while IFS= read -r line; do
    # skip empty or commented lines
    [ -z "${line}" ] && continue
    [[ "${line}" =~ ^[[:space:]]*# ]] && continue

    KEY="${line%%=*}"
    VALUE="${line#*=}"

    # auto-quote value
    ENV_EXPORTS="${ENV_EXPORTS}export ${KEY}='${VALUE}'; "
  done <<< "${ENV_LIST}"
fi

# ---------- SSH OPTIONS (use StrictHostKeyChecking=yes if we have known_hosts) ----------

SSH_OPTS="-o BatchMode=yes -o UserKnownHostsFile=${KNOWN_HOSTS_FILE}"

if [ -n "${SSH_REMOTE_KNOWN_HOSTS}" ]; then
  SSH_OPTS="${SSH_OPTS} -o StrictHostKeyChecking=yes"
else
  SSH_OPTS="${SSH_OPTS} -o StrictHostKeyChecking=no"
fi

# ---------- REMOTE COMMAND ----------

# We:
# 1) cd into your project dir on the server
# 2) export env vars from ENV_LIST
# 3) run docker stack deploy with your compose file
REMOTE_CMD="cd '${REMOTE_WORKDIR}' && ${ENV_EXPORTS} docker stack deploy --with-registry-auth -c '${FILE}' '${STACK_NAME}'"

echo "DEBUG: Remote command: ${REMOTE_CMD}"

ssh ${SSH_OPTS} -p "${SSH_REMOTE_PORT}" "${SSH_USER}@${SSH_HOST}" "${REMOTE_CMD}"

echo "Stack '${STACK_NAME}' deployed successfully!"
