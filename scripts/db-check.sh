#!/bin/bash
# Writes a metric for node-exporter's textfile collector: 1 if the authdb database exists, else 0.
set -euo pipefail
d="${TEXTFILE_DIR:-/var/lib/node_exporter/textfile}"
mkdir -p "$d"
n=$(docker exec votesecure-db-1 psql -U appuser -d postgres -tA -c "SELECT count(*) FROM pg_database WHERE datname='authdb'" 2>/dev/null || true)
if [ "$n" = "1" ]; then v=1; else v=0; fi
tmp="$d/.db.prom.$$"
printf '# HELP votesecure_database_up 1 if the authdb database exists, 0 if it is missing or unreachable\n# TYPE votesecure_database_up gauge\nvotesecure_database_up %s\n' "$v" > "$tmp"
mv "$tmp" "$d/db.prom"
