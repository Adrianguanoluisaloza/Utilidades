#!/bin/bash
set -euo pipefail
HOST="databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com"
PORT=5432
USER="Michael"
PGPASSWORD="XxM7pYbQvtmOo3YdAbYs"

docker run --rm -e PGPASSWORD="$PGPASSWORD" postgres:17-alpine \
  sh -lc "psql -h $HOST -U $USER -p $PORT -d postgres -tAc 'SELECT datname FROM pg_database;'"
