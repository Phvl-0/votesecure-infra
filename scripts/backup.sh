#!/bin/bash
set -euo pipefail
cd ~/votesecure
umask 077
f=backups/authdb-$(date +%F-%H%M).sql.gz
sudo docker exec votesecure-db-1 pg_dump -U appuser authdb | gzip > "$f"
ls -t backups/authdb-*.sql.gz | tail -n +8 | xargs -r rm --
echo "backup: $f"
