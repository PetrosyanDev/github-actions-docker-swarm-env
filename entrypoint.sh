#!/bin/bash
set -euo pipefail

SSH_PRIVATE_KEY="${INPUT_SSH_PRIVATE_KEY}"
SSH_HOST="${INPUT_SSH_HOST}"
SSH_USER="${INPUT_SSH_USER}"
SSH_REMOTE_PORT="${INPUT_SSH_REMOTE_PORT:-22}"
FILE="${INPUT_FILE}"
STACK_NAME="${INPUT_STACK_NAME}"
ENV_LIST="${INPUT_ENV_LIST:-}"

# Setup SSH
mkdir -p ~/.ssh
printf "%s" "$SSH_PRIVATE_KEY" | tr -d '\r' > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa

ssh-keyscan -p "$SSH_REMOTE_PORT" -t rsa "$SSH_HOST" >> ~/.ssh/known_hosts 2>/dev/null || true
ssh-keyscan -p "$SSH_REMOTE_PORT" -t rsa -4 "$SSH_HOST" >> ~/.ssh/known_hosts 2>/dev/null || true

# Build environment variable export string
ENV_EXPORTS=""
if [ -n "$ENV_LIST" ]; then
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        KEY="${line%%=*}"
        VALUE="${line#*=}"

        # automatically quote values
        ENV_EXPORTS="${ENV_EXPORTS}export ${KEY}='${VALUE}'; "
    done <<< "$ENV_LIST"
fi

ssh \
  -i ~/.ssh/id_rsa \
  -p "$SSH_REMOTE_PORT" \
  -o IdentitiesOnly=yes \
  -o StrictHostKeyChecking=no \
  "$SSH_USER@$SSH_HOST" \
  "${ENV_EXPORTS} docker stack deploy --with-registry-auth -c \"$FILE\" \"$STACK_NAME\""

echo "Stack '$STACK_NAME' deployed successfully!"
