#!/bin/bash
set -euo pipefail
cd ~/votesecure
umask 077
f=backups/authdb-$(date +%F-%H%M%S).sql.gz
tmp="$f.part"
trap 'rm -f "$tmp"' EXIT
sudo docker exec votesecure-db-1 pg_dump -U appuser authdb | gzip > "$tmp"
gzip -t "$tmp"
mv "$tmp" "$f"
ls -t backups/authdb-*.sql.gz | tail -n +8 | xargs -r rm --
echo "backup: $f"
BUCKET=votesecure-backups-$(aws sts get-caller-identity --query Account --output text)
aws s3 cp "$f" "s3://$BUCKET/db/$(basename "$f")" --region eu-north-1 --only-show-errors
echo "uploaded: s3://$BUCKET/db/$(basename "$f")"
