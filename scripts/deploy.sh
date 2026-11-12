#!/bin/bash
set -euo pipefail
umask 077
cd /home/ubuntu/votesecure
SHA="${1:?usage: deploy.sh <40-char-commit-sha>}"
[[ "$SHA" =~ ^[0-9a-f]{40}$ ]] || { echo "bad sha"; exit 1; }
REGION=eu-north-1
ENVF=/run/votesecure/app.env
mkdir -p /run/votesecure
cleanup() { rm -f "$ENVF"; docker logout ghcr.io > /dev/null 2>&1 || true; }
trap cleanup EXIT
get() { aws ssm get-parameter --region "$REGION" --name "/votesecure/$1" --with-decryption --query Parameter.Value --output text; }
build_env() {
  { cat images.env
    echo "POSTGRES_PASSWORD=$(get POSTGRES_PASSWORD)"
    echo "SECRET_KEY=$(get SECRET_KEY)"; } > "$ENVF"
}
C="docker compose -f docker-compose.prod.yml --env-file $ENVF"
cp images.env images.env.bak
sed -i -E "s#(votesecure-fullstack-(api|web)):[^ ]*#\1:${SHA}#" images.env
build_env
get GHCR_TOKEN | docker login ghcr.io -u Phvl-0 --password-stdin > /dev/null
$C pull -q
$C up -d
sleep 25

SITE=$(grep -E '^SITE_ADDRESS=' images.env | cut -d= -f2- || true)
healthy() {
  if [ "${SITE:-}" = ":80" ]; then
    curl -fsS -o /dev/null http://127.0.0.1/
  else
    curl -fsS -o /dev/null --resolve votesecure-phvl-0.duckdns.org:443:127.0.0.1 https://votesecure-phvl-0.duckdns.org/
  fi
}
if [ "$($C ps --status running -q | wc -l)" -eq 4 ] && healthy; then

  echo "deploy ok: $SHA"
else
  echo "health check failed, rolling back"
  cp images.env.bak images.env
  build_env
  $C up -d
  exit 1
fi
