-- ===============================================
-- SCRIPT DE VERIFICACIÓN DE DATOS DE PRUEBA
-- Unite Speed Delivery - PostgreSQL
-- ===============================================

\echo '========================================='
\echo 'VERIFICANDO ESTRUCTURA Y DATOS DE PRUEBA'
\echo '========================================='
\echo ''

-- 1. Verificar roles
\echo '1. ROLES DISPONIBLES:'
SELECT id_rol, nombre, created_at 
FROM roles 
ORDER BY id_rol;

\echo ''

-- 2. Verificar usuarios de prueba
\echo '2. USUARIOS DE PRUEBA:'
SELECT u.id_usuario, u.nombre, u.correo, r.nombre as rol, u.activo
FROM usuarios u
JOIN roles r ON u.id_rol = r.id_rol
WHERE u.correo LIKE '%@example.com'
ORDER BY u.id_usuario;

\echo ''

-- 3. Verificar negocios activos
\echo '3. NEGOCIOS ACTIVOS:'
SELECT id_negocio, nombre_comercial, telefono, activo, created_at
FROM negocios
WHERE activo = TRUE
LIMIT 5;

\echo ''

-- 4. Verificar productos disponibles
\echo '4. PRODUCTOS DISPONIBLES:'
SELECT p.id_producto, p.nombre, p.precio, p.disponible, n.nombre_comercial as negocio
FROM productos p
JOIN negocios n ON p.id_negocio = n.id_negocio
WHERE p.disponible = TRUE
LIMIT 10;

\echo ''

-- 5. Verificar ubicaciones
\echo '5. UBICACIONES REGISTRADAS:'
SELECT COUNT(*) as total_ubicaciones
FROM ubicaciones;

\echo ''

-- 6. Verificar pedidos
\echo '6. RESUMEN DE PEDIDOS POR ESTADO:'
SELECT estado, COUNT(*) as cantidad
FROM pedidos
GROUP BY estado
ORDER BY cantidad DESC;

\echo ''

-- 7. Verificar categorías IA
\echo '7. CATEGORÍAS IA PARA CHATBOT:'
SELECT id_categoria_ia, nombre, descripcion
FROM ia_categorias_respuesta
ORDER BY id_categoria_ia;

\echo ''

-- 8. Verificar estructura de tabla usuarios
\echo '8. ESTRUCTURA TABLA USUARIOS:'
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'usuarios'
ORDER BY ordinal_position;

\echo ''

-- 9. Verificar estructura de tabla productos
\echo '9. ESTRUCTURA TABLA PRODUCTOS:'
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'productos'
ORDER BY ordinal_position;

\echo ''

-- 10. Verificar estructura de tabla pedidos
\echo '10. ESTRUCTURA TABLA PEDIDOS:'
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'pedidos'
ORDER BY ordinal_position;

\echo ''
\echo '========================================='
\echo 'VERIFICACIÓN COMPLETADA'
\echo '========================================='
