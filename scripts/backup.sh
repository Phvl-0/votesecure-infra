#!/bin/bash
set -euo pipefail
cd ~/votesecure
umask 077
f=backups/authdb-$(date +%F-%H%M).sql.gz
sudo docker compose -f docker-compose.prod.yml exec -T db pg_dump -U appuser authdb | gzip > "$f"
ls -t backups/authdb-*.sql.gz | tail -n +8 | xargs -r rm --
echo "backup: $f"
