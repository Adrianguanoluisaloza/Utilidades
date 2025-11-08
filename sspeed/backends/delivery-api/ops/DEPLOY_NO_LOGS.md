# Despliegue de delivery-api en AWS (sin CloudWatch logs)

Este guía despliega la API en una instancia EC2 con Docker y docker-compose SIN el driver de logs de CloudWatch (usa el `docker-compose.yml` básico del repo).

Requisitos previos:
- EC2 con Docker y docker-compose instalados.
- Usuario con permisos para usar Docker (o `sudo`).
- Archivo `.env` válido en el servidor (no se sube desde el repo por seguridad).
- Acceso SSH (IP/host, usuario, y clave/llave `.pem`).

## Archivos relevantes
- `backends/delivery-api/docker-compose.yml`: sin configuración de `logging`.
- `backends/delivery-api/Dockerfile`: copia `target/delivery-api-*-jar-with-dependencies.jar` como `app.jar`.
- `backends/delivery-api/target/delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar`: artefacto a construir.

## Pasos

1) Construir el JAR con dependencias (local)
   - Con Maven instalado:
     - Windows (CMD/PowerShell):
       - `mvn -f backends/delivery-api/pom.xml -DskipTests package`
   - Resultado esperado:
     - `backends/delivery-api/target/delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar`

2) Subir al servidor (sin logs)
   - Opción A: Subir carpeta completa y construir en el servidor
     - Copiar `backends/delivery-api/` al servidor (ejemplo a `/opt/delivery-api`)
     - Asegurar que en `/opt/delivery-api` existe `.env` (no se versiona)
   - Opción B: Solo actualizar el JAR (si en el servidor ya está el repo y Dockerfile)
     - Copiar únicamente el JAR a `target/` en el servidor.

3) Levantar el contenedor en EC2 (sin CloudWatch logs)
   - En la ruta `/opt/delivery-api` (o la que uses):
     - `docker compose down`
     - `docker compose build --no-cache`
     - `docker compose up -d`
   - Verificar salud:
     - `curl -fsS http://localhost:7070/health`

4) Troubleshooting
   - Si el contenedor no arranca, ver logs locales:
     - `docker logs -f delivery-api`
   - Verificar variables en `.env` (DB_URL, DB_USER, DB_PASSWORD, JWT_SECRET, etc.)

## Script de ayuda (Windows)

Puedes usar `ops/deploy_no_logs.ps1` para automatizar A→Z. Edita las variables al inicio (HOST/USER/KEY y ruta remota).
