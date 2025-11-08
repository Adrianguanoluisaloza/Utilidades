-- Seed de usuario Admin para Adrian
-- Ejecutar con psql. Puedes sobreescribir estas variables con -v VAR=valor
-- Ejemplo:
--   psql -h <host> -U <user> -d <db> -v admin_name="Adrian" -v admin_email="adrian@tu-dominio.com" -v admin_phone="555-0000" -v admin_password="TuPassFuerte!" -f seed_usuario_adrian.sql

\set admin_name     'Adrian'
\set admin_email    'adrian@example.com'
\set admin_phone    '555-0000'
\set admin_password 'Admin123!'

-- Inserta o actualiza (por correo) un usuario con rol admin
INSERT INTO usuarios (nombre, correo, contrasena, telefono, id_rol)
VALUES (
  :'admin_name',
  :'admin_email',
  :'admin_password',
  :'admin_phone',
  (SELECT id_rol FROM roles WHERE nombre = 'admin')
)
ON CONFLICT (correo) DO UPDATE SET
  nombre     = EXCLUDED.nombre,
  telefono   = EXCLUDED.telefono,
  contrasena = EXCLUDED.contrasena, -- el trigger rehashea si cambia
  id_rol     = EXCLUDED.id_rol,
  updated_at = NOW();

-- Nota: trg_hash_password() hashea contrasena en INSERT/UPDATE
