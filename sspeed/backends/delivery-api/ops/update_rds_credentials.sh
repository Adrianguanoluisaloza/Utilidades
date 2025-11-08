#!/bin/bash
# Actualizar credenciales RDS en .env

cp /home/ubuntu/.env /home/ubuntu/.env.backup-fix-$(date +%s)

sed -i 's|^DB_URL=.*|DB_URL=jdbc:postgresql://databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com:5432/databasefinal?sslmode=require|' /home/ubuntu/.env
sed -i 's|^DB_USER=.*|DB_USER=Michael|' /home/ubuntu/.env
sed -i 's|^DB_PASSWORD=.*|DB_PASSWORD=XxM7pYbQvtmOo3YdAbYs|' /home/ubuntu/.env

echo "===ENV ACTUALIZADO==="
grep '^DB_' /home/ubuntu/.env
