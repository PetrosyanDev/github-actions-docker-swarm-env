#!/bin/bash
set -euo pipefail

# Raw inputs from GitHub
SSH_PRIVATE_KEY="${INPUT_SSH_PRIVATE_KEY}"
SSH_HOST="${INPUT_SSH_HOST}"
SSH_USER="${INPUT_SSH_USER}"
SSH_REMOTE_PORT="${INPUT_SSH_REMOTE_PORT:-22}"
FILE="${INPUT_FILE}"
STACK_NAME="${INPUT_STACK_NAME}"
ENV_LIST="${INPUT_ENV_LIST:-}"

# ---------- SSH SETUP ----------
mkdir -p ~/.ssh

# 1) Fix literal "\n" -> real newlines
# 2) Strip any Windows \r
printf "%s" "$SSH_PRIVATE_KEY" \
  | sed 's/\\n/\n/g' \
  | tr -d '\r' \
  > ~/.ssh/id_rsa

chmod 600 ~/.ssh/id_rsa

# Optional debug (won't show real key, GitHub will mask it, but you see header)
# head -2 ~/.ssh/id_rsa || true

ssh-keyscan -p "$SSH_REMOTE_PORT" "$SSH_HOST" >> ~/.ssh/known_hosts 2>/dev/null || true
ssh-keyscan -p "$SSH_REMOTE_PORT" -t rsa -4 "$SSH_HOST" >> ~/.ssh/known_hosts 2>/dev/null || true

# Build env exports as you already do...
ENV_EXPORTS=""
if [ -n "$ENV_LIST" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    KEY="${line%%=*}"
    VALUE="${line#*=}"

    ENV_EXPORTS="${ENV_EXPORTS}export ${KEY}='${VALUE}'; "
  done <<< "$ENV_LIST"
fi

# ---------- DEPLOY ----------
ssh \
  -i ~/.ssh/id_rsa \
  -p "$SSH_REMOTE_PORT" \
  -o IdentitiesOnly=yes \
  -o StrictHostKeyChecking=no \
  "$SSH_USER@$SSH_HOST" \
  "${ENV_EXPORTS} docker stack deploy --with-registry-auth -c \"$FILE\" \"$STACK_NAME\""

echo "Stack '$STACK_NAME' deployed successfully!"
