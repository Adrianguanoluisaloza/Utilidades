#!/bin/bash
set -euo pipefail

# Configuración RDS (ajusta si cambian credenciales/endpoints)
HOST="databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com"
PORT=5432
DB_NAME="databasefinal"
USER="Michael"
PGPASSWORD="XxM7pYbQvtmOo3YdAbYs"

# Lista extensiones instaladas en la base actual
# Salida: una por línea (pgcrypto, plpgsql, ...)
docker run --rm -e PGPASSWORD="$PGPASSWORD" postgres:17-alpine \
  psql -h "$HOST" -U "$USER" -p "$PORT" -d "$DB_NAME" -At \
  -c "SELECT extname FROM pg_extension ORDER BY 1;"
