-- =====================================================
-- Script para eliminar triggers de hasheo de contraseñas
-- Porque el código Java ya maneja el hasheo con BCrypt
-- =====================================================

-- Eliminar triggers de hasheo de contraseña
DROP TRIGGER IF EXISTS usuarios_hash_before_insert ON usuarios;
DROP TRIGGER IF EXISTS usuarios_hash_before_update ON usuarios;

-- Eliminar función de hasheo (ya no es necesaria)
DROP FUNCTION IF EXISTS trg_hash_password();

-- IMPORTANTE: Los usuarios existentes con doble hasheo necesitan regenerar sus contraseñas
-- o migrar sus hashes actuales. Para desarrollo, puedes resetear las contraseñas manualmente.

-- Ejemplo para resetear contraseñas de prueba (SOLO PARA DESARROLLO):
-- UPDATE usuarios SET contrasena = '$2a$06$hash_del_bcrypt_generado_en_java' WHERE correo = 'test@example.com';

COMMIT;
