# Runbook: Despliegue delivery-api (Windows CMD) sin CloudWatch logs

Este documento contiene los comandos exactos para:
- Compilar el JAR del backend
- Subir artefactos a la EC2 por SCP usando tu llave .pem
- Reconstruir y levantar el contenedor en el servidor con docker-compose (sin CloudWatch logs)
- Verificar salud y hacer un smoke test básico

Requisitos previos:
- Windows 10/11 con OpenSSH Client instalado (ssh y scp disponibles en CMD)
- En la EC2: Docker y docker-compose instalados
- En la EC2: archivo `.env` válido en la carpeta de despliegue (contiene DB_URL, DB_USER, DB_PASSWORD, JWT_SECRET, PORT, etc.)

> Importante: Mantén tu archivo .pem en privado. No lo subas al repositorio.

---

## 1) Variables de entorno (en CMD)

Configura estas variables en la sesión actual de CMD. Debajo va un bloque PRE-LLENO con tus valores reales para que solo lo pegues.

### Opción A — Plantilla editable
```cmd
:: RUTA A TU LLAVE .PEM (LOCAL)
set PEM=C:\\Users\\TU_USUARIO\\.ssh\\mi-llave.pem

:: HOST/IP DE TU EC2
set HOST=ec2-xx-xx-xx-xx.compute.amazonaws.com

:: USUARIO SSH
set USER=ubuntu

:: CARPETA REMOTA DONDE YA EXISTEN docker-compose.yml Y .env
set REMOTE=/home/ubuntu

:: RUTA LOCAL DE ESTE REPO
set REPO=C:\\ruta\\a\\tu\\repo\\sspeed
```

### Opción B — Tus valores reales (listo para pegar)
```cmd
set PEM=C:\\Users\\Adrian\\Downloads\\finalidad.pem
set HOST=18.217.51.221
set USER=ubuntu
set REMOTE=/home/ubuntu
set REPO=C:\\Users\\Adrian\\Proyecto\\sspeed
```

---

## 2) Construir el JAR con Maven (local)

```cmd
mvn -f %REPO%\backends\delivery-api\pom.xml -DskipTests package
```

Artefacto generado:
- `%REPO%\backends\delivery-api\target\delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar`

---

## 3) Subir artefactos a la EC2 (SCP)

- Opción A: subir solo el JAR (si en el servidor ya existe `docker-compose.yml` y `.env` en `%REMOTE%`)

```cmd
scp -i "%PEM%" "%REPO%\backends\delivery-api\target\delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar" "%USER%@%HOST%:%REMOTE%/target/"
```

- Opción B: subir también Dockerfile y docker-compose.yml (si quieres reemplazarlos)

```cmd
scp -i "%PEM%" "%REPO%\backends\delivery-api\Dockerfile" "%USER%@%HOST%:%REMOTE%/"
scp -i "%PEM%" "%REPO%\backends\delivery-api\docker-compose.yml" "%USER%@%HOST%:%REMOTE%/"
scp -i "%PEM%" "%REPO%\backends\delivery-api\target\delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar" "%USER%@%HOST%:%REMOTE%/target/"
```

> Nota: Asegúrate de que en `%REMOTE%` existe un `.env` válido. Si no, créalo allí antes de levantar el contenedor.

Comentarios prácticos:
- No subimos `.env` por seguridad. Mantén la versión del servidor como fuente de verdad.
- El JAR se sube a `%REMOTE%/target/`. El Dockerfile del servidor copia `target/delivery-api-*-jar-with-dependencies.jar` como `app.jar`.

---

## 4) Reconstruir e iniciar el contenedor (SSH + docker-compose)

Ejecuta en el servidor (un solo comando desde tu CMD):

```cmd
ssh -i "%PEM%" %USER%@%HOST% "cd %REMOTE% && docker-compose down && docker-compose build --no-cache && docker-compose up -d && docker ps --filter name=delivery-api"
```

> Si tu servidor usa `docker compose` (sin guion), sustituye `docker-compose` por `docker compose`.

Comentarios prácticos:
- Si ves `docker: unknown command: docker compose`, usa `docker-compose`.
- Si sale `Couldn't find env file: %REMOTE%/.env`, entra al servidor y confirma que el `.env` esté en `%REMOTE%`.

---

## 5) Verificar salud

El contenedor tarda unos segundos en iniciar. Espera ~10-20s y revisa salud:

```cmd
ssh -i "%PEM%" %USER%@%HOST% "curl -fsS http://localhost:7070/health || true"
```

Respuesta esperada (ejemplo):

```json
{"status":"UP","uptimeMs":12345,"db":{"connected":true,"error":null}}
```

---

## 6) Smoke tests (opcionales)

- Login (ajusta correo/contraseña a un usuario real):

```cmd
curl -X POST http://%HOST%:7070/auth/login -H "Content-Type: application/json" -d "{\"correo\":\"usuario@correo.com\",\"contrasena\":\"TuPass123\"}"
```

Copia el token `Bearer` de la respuesta para el siguiente paso.

- Chatbot (requiere token y un idRemitente válido):

```cmd
curl -X POST http://%HOST%:7070/chat/bot/mensajes ^
  -H "Content-Type: application/json" ^
  -H "Authorization: Bearer TU_TOKEN_JWT_AQUI" ^
  -d "{\"idRemitente\":1,\"mensaje\":\"test\"}"
```

> En CMD, el carácter `^` permite dividir el comando en varias líneas. Puedes ponerlo en una sola línea si prefieres.

Comentarios prácticos:
- Las rutas `/chat/*` requieren token JWT (el middleware de auth lo exige). Primero haz login y copia el token.
- Para `idRemitente`, usa el ID real del usuario autenticado.

---

## 7) Logs (locales en el servidor)

Si necesitas ver logs en la EC2:

```cmd
ssh -i "%PEM%" %USER%@%HOST% "docker logs -f delivery-api"
```

---

## 8) Problemas comunes

- `Couldn't find env file: %REMOTE%/.env`
  - Solución: sube/crea `.env` en `%REMOTE%` (no versionado por seguridad)
- `docker: unknown command: docker compose`
  - Solución: usa `docker-compose` en lugar de `docker compose`
- Health falla justo al subir
  - Espera unos segundos y reintenta `curl http://localhost:7070/health`
- Error 500 en chatbot
  - Con el fix aplicado, si `idRemitente` o `mensaje` son inválidos, devuelve 400 (con mensaje claro) y no 500. Asegúrate de enviar campos válidos.
  - Si persiste algún 500, revisa `docker logs -f delivery-api` y ejecuta de nuevo la petición con `-v` para ver detalles.

---

## 9) Comando de todo en uno (rápido)

Si ya tienes `%REMOTE%` con `.env`, `docker-compose.yml` y sólo quieres reemplazar el JAR y reiniciar:

```cmd
mvn -f %REPO%\backends\delivery-api\pom.xml -DskipTests package && ^
scp -i "%PEM%" "%REPO%\backends\delivery-api\target\delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar" "%USER%@%HOST%:%REMOTE%/target/" && ^
ssh -i "%PEM%" %USER%@%HOST% "cd %REMOTE% && docker-compose down && docker-compose build --no-cache && docker-compose up -d && docker ps --filter name=delivery-api" && ^
ssh -i "%PEM%" %USER%@%HOST% "curl -fsS http://localhost:7070/health || true"
```

---

Listo. Con este runbook puedes realizar el despliegue completo desde Windows CMD usando tu llave `.pem` (que conservas en tu equipo).

---

## 10) Apéndice — Variante con `docker compose` (sin guion)

Si tu servidor tiene el plugin moderno:

```cmd
ssh -i "%PEM%" %USER%@%HOST% "cd %REMOTE% && docker compose down && docker compose build --no-cache && docker compose up -d && docker ps --filter name=delivery-api" && ^
ssh -i "%PEM%" %USER%@%HOST% "curl -fsS http://localhost:7070/health || true"
```

Consejo: La primera vez suele tardar un poco por la reconstrucción de imagen. Espera 10–20s y vuelve a consultar `/health`.

---

## 11) Cambiar a RDS (resumen)

Pasos rápidos:
- Crea RDS PostgreSQL en la misma VPC que tu EC2 y permite 5432 desde el Security Group de la EC2.
- Migra datos (pg_dump/pg_restore) desde tu DB actual a RDS.
- Actualiza `/home/ubuntu/.env`:
  - `DB_URL=jdbc:postgresql://<RDS_ENDPOINT>:5432/delivery_db?sslmode=require`
  - `DB_USER=...`
  - `DB_PASSWORD=...`
- Reinicia el contenedor.

Detalle completo: ver `ops/RUNBOOK_RDS_POSTGRES.md`.