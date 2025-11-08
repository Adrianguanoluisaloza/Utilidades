#!/bin/bash
set -euo pipefail

HOST="databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com"
PORT="5432"
USER="Michael"
DB_NAME="databasefinal"
PGPASSWORD="XxM7pYbQvtmOo3YdAbYs"

# Usa contenedor oficial de psql para crear la base
docker run --rm \
  -e PGPASSWORD="$PGPASSWORD" \
  postgres:17-alpine \
  sh -lc "psql -h $HOST -U $USER -p $PORT -d postgres -v ON_ERROR_STOP=1 -c 'CREATE DATABASE \"$DB_NAME\";'"

echo "Base de datos '$DB_NAME' creada (si no existía)." 
