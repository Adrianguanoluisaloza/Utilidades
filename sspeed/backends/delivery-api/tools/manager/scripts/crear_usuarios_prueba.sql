-- Script para crear usuarios de NEGOCIO y SOPORTE
-- Base de datos: databasefinal

-- Primero verificamos los roles disponibles
SELECT * FROM roles;

-- Insertamos usuario NEGOCIO
-- Nota: La contraseña debe estar hasheada con BCrypt en producción
-- Para pruebas, usamos la contraseña: Negocio123!
INSERT INTO usuarios (nombre, correo, contrasena, telefono, id_rol, activo, created_at, updated_at)
VALUES (
    'Maria Negocio',
    'maria.negocio@example.com',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhCu', -- BCrypt hash de "Negocio123!"
    '0987654321',
    (SELECT id_rol FROM roles WHERE nombre = 'negocio' LIMIT 1),
    true,
    NOW(),
    NOW()
);

-- Insertamos usuario SOPORTE
-- Contraseña: Soporte123!
INSERT INTO usuarios (nombre, correo, contrasena, telefono, id_rol, activo, created_at, updated_at)
VALUES (
    'Juan Soporte',
    'juan.soporte@example.com',
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhCu', -- BCrypt hash de "Soporte123!"
    '0987654322',
    (SELECT id_rol FROM roles WHERE nombre = 'soporte' LIMIT 1),
    true,
    NOW(),
    NOW()
);

-- Verificamos que se crearon correctamente
SELECT u.id_usuario, u.nombre, u.correo, r.nombre as rol, u.activo
FROM usuarios u
JOIN roles r ON u.id_rol = r.id_rol
WHERE u.correo IN ('maria.negocio@example.com', 'juan.soporte@example.com');

-- Si el usuario negocio necesita un negocio asociado, crear uno:
INSERT INTO negocios (nombre, descripcion, direccion, telefono, id_usuario, calificacion_promedio, activo, created_at, updated_at)
VALUES (
    'Negocio de Prueba',
    'Negocio de prueba para testing',
    'Calle Test #123, Esmeraldas',
    '0987654321',
    (SELECT id_usuario FROM usuarios WHERE correo = 'maria.negocio@example.com' LIMIT 1),
    5.0,
    true,
    NOW(),
    NOW()
);

-- Verificar negocio creado
SELECT * FROM negocios WHERE id_usuario = (SELECT id_usuario FROM usuarios WHERE correo = 'maria.negocio@example.com');
