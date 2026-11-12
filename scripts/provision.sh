#!/bin/bash
# Copies the app and monitoring files onto a fresh VM and deploys. Usage: provision.sh <app-commit-sha>
set -euo pipefail
cd "$(dirname "$0")/.."
KEY=~/.ssh/votesecure-key.pem
SHA="${1:?usage: provision.sh <40-char app commit sha>}"
IP=$(aws ec2 describe-addresses --region eu-north-1 --filters Name=tag:Name,Values=votesecure-eip --query 'Addresses[0].PublicIp' --output text)
SSH="ssh -i $KEY -o StrictHostKeyChecking=accept-new ubuntu@$IP"
until $SSH 'test -f /var/lib/votesecure-bootstrap-done' 2>/dev/null; do sleep 10; done
scp -i "$KEY" docker-compose.prod.yml Caddyfile scripts/deploy.sh scripts/backup.sh scripts/monitoring-up.sh ubuntu@"$IP":~/votesecure/
scp -i "$KEY" monitoring/* ubuntu@"$IP":~/votesecure/monitoring/
$SSH 'cd ~/votesecure && chmod 700 deploy.sh backup.sh monitoring-up.sh && printf "API_IMAGE=ghcr.io/phvl-0/votesecure-fullstack-api:latest\nWEB_IMAGE=ghcr.io/phvl-0/votesecure-fullstack-web:latest\n" > images.env'
# the first deploy can race the certificate being issued, so allow one retry
[ -z "${SITE_ADDRESS:-}" ] || $SSH "echo 'SITE_ADDRESS=${SITE_ADDRESS}' >> ~/votesecure/images.env"

$SSH "sudo ~/votesecure/deploy.sh $SHA" || { sleep 30; $SSH "sudo ~/votesecure/deploy.sh $SHA"; }
$SSH 'sudo ~/votesecure/monitoring-up.sh'
