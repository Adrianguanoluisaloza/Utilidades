# Seeds de usuarios (SQL)

Este directorio incluye dos scripts para crear/actualizar usuarios sin tocar el rebuild_database.sql:

- seed_usuario_adrian.sql: crea/actualiza un usuario Admin para Adrian (usa variables psql).
- seed_usuario_template.sql: plantilla para crear/actualizar cualquier usuario con rol configurable.

Ambos scripts son idempotentes por correo (usan ON CONFLICT (correo) DO UPDATE). El trigger trg_hash_password() hashea la contraseña al insertar/actualizar.

## Cómo ejecutar (desde EC2 o local con acceso a RDS)

Windows (cmd):

psql -h databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com -U Michael -p 5432 -d databasefinal ^
  -v admin_name="Adrian" ^
  -v admin_email="adrian@tu-dominio.com" ^
  -v admin_phone="555-0000" ^
  -v admin_password="TuPassFuerte!" ^
  -f seed_usuario_adrian.sql

Plantilla genérica (ajusta variables):

psql -h databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com -U Michael -p 5432 -d databasefinal ^
  -v user_name="Tu Nombre" ^
  -v user_email="tu.correo@dominio.com" ^
  -v user_phone="555-0100" ^
  -v user_password="Cliente123!" ^
  -v user_role="cliente" ^
  -f seed_usuario_template.sql

Con Docker en la EC2 (recomendado):

docke run --rm -e PGPASSWORD="$PGPASSWORD" -v /home/ubuntu:/work -w /work postgres:17-alpine \
  sh -lc "psql -h databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com -U Michael -p 5432 -d databasefinal \
  -v admin_name='Adrian' -v admin_email='adrian@tu-dominio.com' -v admin_phone='555-0000' -v admin_password='TuPassFuerte!' \
  -f seed_usuario_adrian.sql"

## Roles disponibles

- cliente
- delivery
- negocio
- admin
- soporte

## Notas de seguridad

- Usa contraseñas fuertes y únicas por usuario.
- No comitees credenciales reales en el repo; pasa los valores por -v o .env en el servidor.
- En producción, ejecuta los seeds desde la EC2 para no abrir el RDS a IPs públicas.