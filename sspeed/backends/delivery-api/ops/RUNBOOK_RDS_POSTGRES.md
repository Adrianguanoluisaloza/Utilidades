# Runbook: Migrar PostgreSQL a Amazon RDS (y apuntar delivery-api)

Este documento te guía para mover la base de datos a RDS y hacer que `delivery-api` use ese RDS.
Incluye creación del RDS, reglas de seguridad, migración de datos y actualización del `.env` en el servidor.

Tiempo estimado: 30–60 minutos

---

## 1) Crear instancia RDS PostgreSQL (consola AWS)

1. Ve a RDS → Create database
2. Engine: PostgreSQL (versión estable p. ej. 15.x)
3. Templates: Free tier (si aplica) o Dev/Test
4. Settings:
   - DB instance identifier: `sspeed-db`
   - Master username: `sspeed_admin` (ejemplo)
   - Master password: (guárdala en un lugar seguro)
5. Instance configuration: `db.t3.micro` (o similar)
6. Storage: 20 GB (gp3)
7. Connectivity:
   - VPC: la misma donde está tu EC2
   - Public access: No (recomendado)
   - Security group: crea uno nuevo o usa uno que permita acceso desde tu EC2
     - Regla entrante: Postgres (5432) desde el Security Group de la EC2 (mejor práctica) o desde su IP privada
8. Database authentication: Password authentication
9. Additional configuration:
   - Initial database name: `delivery_db`
10. Create database y espera a que esté en estado `Available`

Obtén el Endpoint (por ejemplo: `sspeed-db.xxxxx.us-east-2.rds.amazonaws.com`).

---

## 2) Habilitar acceso desde tu EC2

- Ve a Security Groups del RDS y agrega una regla entrante:
  - Tipo: PostgreSQL
  - Puerto: 5432
  - Source: `Security Group` de la EC2 (recomendado) o su IP privada

Nota: Evita abrir 0.0.0.0/0. Mantén todo dentro de la VPC.

---

## 3) Migrar datos (pg_dump → RDS)

Puedes ejecutar esto desde la EC2 (si tu DB actual está en esa misma EC2). Requiere cliente `psql`/`pg_dump`.

### 3.1 Instalar cliente PostgreSQL (Ubuntu)

```bash
sudo apt-get update && sudo apt-get install -y postgresql-client
```

### 3.2 Volcar la DB actual (ejemplos)

Si tu DB actual corre en localhost:5432 y se llama `sspeed`:

```bash
pg_dump -h localhost -U tu_usuario_local -d sspeed -Fc -f backup_sspeed.dump
```

O en formato SQL:

```bash
pg_dump -h localhost -U tu_usuario_local -d sspeed -f backup_sspeed.sql
```

### 3.3 Restaurar en RDS

Con usuario master creado en RDS (ej: `sspeed_admin`) y DB `delivery_db`:

```bash
# Opción A (custom, formato comprimido)
pg_restore -h <RDS_ENDPOINT> -U sspeed_admin -d delivery_db -c -v backup_sspeed.dump

# Opción B (SQL plano)
psql -h <RDS_ENDPOINT> -U sspeed_admin -d delivery_db -f backup_sspeed.sql
```

> Si necesitas crear roles/usuarios específicos, hazlo antes de restaurar (o después) con `psql`.

---

## 4) Actualizar el .env de delivery-api en la EC2

Editar `/home/ubuntu/.env` (o la carpeta donde despliegas) con los valores de RDS:

```dotenv
DB_URL=jdbc:postgresql://<RDS_ENDPOINT>:5432/delivery_db?sslmode=require
DB_USER=sspeed_admin
DB_PASSWORD=TU_PASSWORD

# (Opcional) Pool tuning para RDS
DB_POOL_SIZE=10
DB_MIN_IDLE=2
DB_CONN_TIMEOUT_MS=10000
DB_IDLE_TIMEOUT_MS=600000
DB_MAX_LIFETIME_MS=1800000
```

> `sslmode=require` es recomendado con RDS.

Puedes hacerlo manualmente (ssh + nano) o con el script `ops/update_env_rds.ps1` (ver siguiente sección).

---

## 5) Reiniciar delivery-api

Desde `/home/ubuntu` (o tu carpeta REMOTE):

```bash
docker-compose down && docker-compose build --no-cache && docker-compose up -d
```

Verifica salud:

```bash
curl -fsS http://localhost:7070/health
```

---

## 6) Validar funcionalidad

- Login, productos, pedidos, ubicaciones
- Chatbot (probar `/chat/bot/mensajes`)
- Revisa logs si algo falla:

```bash
docker logs -f delivery-api
```

### 6.1) Verificación RDS (extensiones y smoke test)

Para confirmar que tu RDS tiene las extensiones necesarias y que la app responde con el chatbot:

1) Listar extensiones instaladas en RDS (desde la EC2):

```bash
bash ops/list_rds_extensions.sh
# Salida esperada (al menos):
# pgcrypto
# plpgsql
```

2) Smoke test mínimo de API (desde tu PC) — requiere que la app esté arriba en EC2:

```bash
# 1) Login con usuario seed (del rebuild_database.sql)
curl -X POST http://<EC2_PUBLIC_IP>:7070/auth/login \
   -H "Content-Type: application/json" \
   -d '{"correo":"carlos.cliente@example.com","contrasena":"Cliente123!"}'

# 2) Usa el token devuelto para el chatbot (reemplaza TU_TOKEN)
curl -X POST http://<EC2_PUBLIC_IP>:7070/chat/bot/mensajes \
   -H "Content-Type: application/json" \
   -H "Authorization: Bearer TU_TOKEN" \
   -d '{"idRemitente":1,"mensaje":"hola"}'
```

Notas:
- Las rutas `/chat/*` requieren JWT; sin Authorization devolverán 401.
- El comando de extensiones usa un contenedor `postgres:17-alpine` (no instala paquetes en la EC2) y lee host/credenciales dentro del script.

---

## 7) Volver atrás (Rollback)

- Si hay problema con RDS, regresa el `.env` a `DB_URL` original (localhost) y reinicia el contenedor.

---

## 8) Script opcional para actualizar .env (Windows)

Usa `ops/update_env_rds.ps1` para subir un `.env` nuevo asegurando backup del actual.

```powershell
# Ejemplo (ajusta variables)
$HostName = "18.217.51.221"
$User = "ubuntu"
$Pem = "C:\Users\Adrian\Downloads\finalidad.pem"
$Remote = "/home/ubuntu"
$DbUrl = "jdbc:postgresql://sspeed-db.xxxxx.us-east-2.rds.amazonaws.com:5432/delivery_db?sslmode=require"
$DbUser = "sspeed_admin"
$DbPass = "TU_PASSWORD"

powershell -File ops/update_env_rds.ps1 -HostName $HostName -User $User -PemFile $Pem -RemotePath $Remote -DbUrl $DbUrl -DbUser $DbUser -DbPassword $DbPass
```

Esto creará un `.env.new` local, lo subirá, hará backup del `.env` remoto y lo reemplazará.
