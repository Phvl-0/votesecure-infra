#!/bin/bash
set -euo pipefail
umask 077
cd /home/ubuntu/votesecure/monitoring
ENVF=/run/votesecure/monitoring.env
mkdir -p /run/votesecure
trap 'rm -f "$ENVF"' EXIT
printf 'GRAFANA_ADMIN_PASSWORD=%s\n' "$(aws ssm get-parameter --region eu-north-1 --name /votesecure/GRAFANA_ADMIN_PASSWORD --with-decryption --query Parameter.Value --output text)" > "$ENVF"
SECDIR=/run/votesecure/alertmanager
mkdir -p "$SECDIR" && chmod 755 "$SECDIR"
for n in telegram_token:TELEGRAM_BOT_TOKEN telegram_chat_id:TELEGRAM_CHAT_ID; do
  aws ssm get-parameter --region eu-north-1 --name "/votesecure/${n#*:}" --with-decryption --query Parameter.Value --output text | tr -d '\n' > "$SECDIR/${n%%:*}"
  chmod 644 "$SECDIR/${n%%:*}"
done
docker compose --env-file "$ENVF" up -d
