-- Plantilla de creación/actualización de usuario
-- Requiere definir variables psql ANTES de ejecutar o pasarlas con -v
-- Variables requeridas:
--   -v user_name="Tu Nombre"
--   -v user_email="tu.correo@dominio.com"
--   -v user_phone="555-0000"
--   -v user_password="TuPassFuerte!"
--   -v user_role="cliente"   -- (cliente|delivery|negocio|admin|soporte)
-- Ejemplo de ejecución:
--   psql -h <host> -U <user> -d <db> \
--     -v user_name="Juan Perez" \
--     -v user_email="juan@example.com" \
--     -v user_phone="555-0100" \
--     -v user_password="Cliente123!" \
--     -v user_role="cliente" \
--     -f seed_usuario_template.sql

-- (Opcional) Valores por defecto para pruebas locales (cámbialos al ejecutar en producción)
\set user_name     'PON TU NOMBRE AQUI'
\set user_email    'pon-tu-correo@example.com'
\set user_phone    '555-XXXX'
\set user_password 'CambiaEstaClave!'
\set user_role     'cliente'

-- Inserta o actualiza (por correo) un usuario con el rol indicado
INSERT INTO usuarios (nombre, correo, contrasena, telefono, id_rol)
VALUES (
  :'user_name',
  :'user_email',
  :'user_password',
  :'user_phone',
  (SELECT id_rol FROM roles WHERE nombre = :'user_role')
)
ON CONFLICT (correo) DO UPDATE SET
  nombre     = EXCLUDED.nombre,
  telefono   = EXCLUDED.telefono,
  contrasena = EXCLUDED.contrasena, -- el trigger rehashea si cambia
  id_rol     = EXCLUDED.id_rol,
  updated_at = NOW();
