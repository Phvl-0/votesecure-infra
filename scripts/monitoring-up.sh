#!/bin/bash
set -euo pipefail
umask 077
cd /home/ubuntu/votesecure/monitoring
ENVF=/run/votesecure/monitoring.env
mkdir -p /run/votesecure
trap 'rm -f "$ENVF"' EXIT
printf 'GRAFANA_ADMIN_PASSWORD=%s\n' "$(aws ssm get-parameter --region eu-north-1 --name /votesecure/GRAFANA_ADMIN_PASSWORD --with-decryption --query Parameter.Value --output text)" > "$ENVF"
docker compose --env-file "$ENVF" up -d
