-- =====================================================
-- Script para restablecer contraseñas de usuarios existentes
-- después de eliminar los triggers de doble hasheo
-- =====================================================


UPDATE usuarios SET contrasena = '$2a$06$Fi/xruiMEi/gmLgCxdCpXehrfzS5NUmByIT0BIa2pB/aPJinp5fri' 
WHERE correo IN (
    'carlos.cliente@example.com',
    'diana.cliente@example.com',
    'ana.admin@example.com',
    'pablo.delivery@example.com',
    'laura.delivery@example.com',
    'marco.delivery@example.com',
    'nelson.negocio@example.com',
    'beatriz.negocio@example.com',
    'rocio.negocio@example.com',
    'victor.negocio@example.com',
    'chatbot@system.local'
);

-- OPCIÓN 2: Para usuarios reales en producción
-- Pueden usar la función de "olvidé mi contraseña" del frontend
-- O puedes generar un hash temporal con este comando en Java/consola:
-- BCrypt.hashpw("temporal123", BCrypt.gensalt(6))
-- Y luego ejecutar:
-- UPDATE usuarios SET contrasena = '<hash_generado>' WHERE correo = 'usuario@example.com';

COMMIT;
