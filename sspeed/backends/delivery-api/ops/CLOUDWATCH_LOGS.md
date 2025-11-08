# CloudWatch Logs para delivery-api

Este servicio puede enviar sus logs de Docker a AWS CloudWatch Logs usando el log driver `awslogs`.

## Requisitos

- Instancia EC2 con un IAM Role adjunto (por ejemplo `EC2-SSM-Role`).
- El rol debe tener permisos mínimos sobre CloudWatch Logs:
  - `logs:CreateLogGroup`
  - `logs:CreateLogStream`
  - `logs:PutLogEvents`
  - `logs:DescribeLogStreams`
- Conocer la región AWS de la instancia (por ejemplo `us-east-2`).

Ejemplo de política mínima (adjuntar al rol de la instancia):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "*"
    }
  ]
}
```

> Alternativa rápida: adjuntar la política administrada `CloudWatchLogsFullAccess` al rol de instancia.

## docker-compose (ejemplo)

Archivo ejemplo en `deploy/docker-compose.cloudwatch.yml`:

```yaml
version: "3.9"
services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: delivery-api
    environment:
      - PORT=7070
    env_file:
      - .env
    ports:
      - "7070:7070"
    restart: unless-stopped
    logging:
      driver: awslogs
      options:
        awslogs-region: us-east-2
        awslogs-group: /sspeed/delivery-api
        awslogs-stream: delivery-api
        awslogs-create-group: "true"
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://localhost:7070/health || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 20s
```

Copia este archivo a `/home/ubuntu/docker-compose.yml` y levanta el servicio:

```bash
# En la instancia EC2
cd /home/ubuntu
docker-compose down
docker-compose up -d
```

Si ves un error de `AccessDeniedException` al crear el Log Stream, añade la política indicada al rol de la instancia y ejecuta nuevamente `docker-compose up -d`.

## Ver los logs en CloudWatch

1. Abre AWS Console → CloudWatch → Logs → Log groups.
2. Busca el grupo `/sspeed/delivery-api`.
3. Entra al stream `delivery-api` para ver las entradas.

## Notas

- Región: si tu instancia no está en `us-east-2`, cambia `awslogs-region` por la región real.
- Si prefieres el CloudWatch Agent en lugar del log driver, también funciona, pero requiere instalar el agente y configurar `/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`.
- Este repo conserva el `docker-compose.yml` original en producción. Para activar CloudWatch, sube el compose de ejemplo y reinicia. 
