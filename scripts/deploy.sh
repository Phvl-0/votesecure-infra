#!/bin/bash
set -euo pipefail
umask 077
cd /home/ubuntu/votesecure
SHA="${1:?usage: deploy.sh <40-char-commit-sha>}"
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || { echo "bad sha"; exit 1; }
C="docker compose -f docker-compose.prod.yml"
cp .env .env.bak
sed -i -E "s#(votesecure-fullstack-(api|web)):[^ ]*#\1:${SHA}#" .env
$C pull -q
$C up -d
sleep 25
if [ "$($C ps --status running -q | wc -l)" -eq 3 ] && curl -fsS -o /dev/null http://localhost/; then
  echo "deploy ok: $SHA"
else
  echo "health check failed, rolling back"
  cp .env.bak .env
  $C up -d
  exit 1
fi
