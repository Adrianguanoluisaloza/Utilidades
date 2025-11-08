-- ============================================================================
-- SCRIPT DE CONFIGURACIÓN DE TRACKING PARA UNITE SPEED DELIVERY
-- ============================================================================
-- Este script crea las tablas necesarias para el sistema de tracking en tiempo real
-- Autor: Sistema Unite Speed
-- Fecha: 2024
-- Base de Datos: PostgreSQL
-- ============================================================================

-- TABLA: tracking_eventos
-- Almacena los puntos de la ruta del repartidor para cada pedido
-- ============================================================================
CREATE TABLE IF NOT EXISTS tracking_eventos (
    id_pedido INTEGER NOT NULL,
    orden INTEGER NOT NULL,
    latitud DOUBLE PRECISION NOT NULL,
    longitud DOUBLE PRECISION NOT NULL,
    descripcion VARCHAR(255),
    fecha_evento TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_pedido, orden),
    CONSTRAINT fk_tracking_pedido FOREIGN KEY (id_pedido) 
        REFERENCES pedidos(id_pedido) ON DELETE CASCADE
);

-- Índices para optimizar consultas de tracking
CREATE INDEX IF NOT EXISTS idx_tracking_pedido ON tracking_eventos(id_pedido);
CREATE INDEX IF NOT EXISTS idx_tracking_fecha ON tracking_eventos(fecha_evento);

-- ============================================================================
-- COMENTARIOS DE TABLA
-- ============================================================================
COMMENT ON TABLE tracking_eventos IS 'Almacena los puntos de ruta del tracking en tiempo real';
COMMENT ON COLUMN tracking_eventos.id_pedido IS 'ID del pedido al que pertenece este punto de tracking';
COMMENT ON COLUMN tracking_eventos.orden IS 'Orden secuencial del punto en la ruta (1, 2, 3...)';
COMMENT ON COLUMN tracking_eventos.latitud IS 'Latitud GPS del punto (-90 a 90)';
COMMENT ON COLUMN tracking_eventos.longitud IS 'Longitud GPS del punto (-180 a 180)';
COMMENT ON COLUMN tracking_eventos.descripcion IS 'Descripción opcional del punto (ej: "Saliendo del negocio")';
COMMENT ON COLUMN tracking_eventos.fecha_evento IS 'Timestamp de cuando se registró este punto';

-- ============================================================================
-- DATOS DE EJEMPLO PARA TESTING
-- ============================================================================
-- Ruta de ejemplo para pedido #1 (Esmeraldas, Ecuador)
-- Simula una ruta desde un negocio hasta la casa del cliente

-- Punto 1: Negocio (inicio)
INSERT INTO tracking_eventos (id_pedido, orden, latitud, longitud, descripcion) 
VALUES (1, 1, 0.970362, -79.652557, 'Saliendo del negocio')
ON CONFLICT (id_pedido, orden) DO NOTHING;

-- Punto 2: Primera intersección
INSERT INTO tracking_eventos (id_pedido, orden, latitud, longitud, descripcion) 
VALUES (1, 2, 0.970524, -79.655029, 'Avanzando por Av. Principal')
ON CONFLICT (id_pedido, orden) DO NOTHING;

-- Punto 3: Zona intermedia
INSERT INTO tracking_eventos (id_pedido, orden, latitud, longitud, descripcion) 
VALUES (1, 3, 0.976980, -79.654840, 'Pasando por el parque')
ON CONFLICT (id_pedido, orden) DO NOTHING;

-- Punto 4: Acercándose al destino
INSERT INTO tracking_eventos (id_pedido, orden, latitud, longitud, descripcion) 
VALUES (1, 4, 0.983438, -79.655182, 'A 2 cuadras del destino')
ON CONFLICT (id_pedido, orden) DO NOTHING;

-- Punto 5: Muy cerca
INSERT INTO tracking_eventos (id_pedido, orden, latitud, longitud, descripcion) 
VALUES (1, 5, 0.984854, -79.657457, 'A 1 cuadra del destino')
ON CONFLICT (id_pedido, orden) DO NOTHING;

-- Punto 6: Destino final (casa del cliente)
INSERT INTO tracking_eventos (id_pedido, orden, latitud, longitud, descripcion) 
VALUES (1, 6, 0.988033, -79.659094, 'Llegando al destino')
ON CONFLICT (id_pedido, orden) DO NOTHING;

-- ============================================================================
-- VERIFICACIÓN DE DATOS
-- ============================================================================
-- Consulta para verificar que los datos se insertaron correctamente
SELECT 
    id_pedido,
    orden,
    latitud,
    longitud,
    descripcion,
    fecha_evento
FROM tracking_eventos
WHERE id_pedido = 1
ORDER BY orden;

-- ============================================================================
-- CONSULTAS ÚTILES PARA TRACKING
-- ============================================================================

-- 1. Obtener toda la ruta de un pedido específico
-- SELECT * FROM tracking_eventos WHERE id_pedido = 1 ORDER BY orden;

-- 2. Obtener el último punto registrado de un pedido
-- SELECT * FROM tracking_eventos WHERE id_pedido = 1 ORDER BY orden DESC LIMIT 1;

-- 3. Contar cuántos puntos tiene la ruta de un pedido
-- SELECT COUNT(*) as total_puntos FROM tracking_eventos WHERE id_pedido = 1;

-- 4. Obtener todos los pedidos que tienen tracking
-- SELECT DISTINCT id_pedido FROM tracking_eventos;

-- ============================================================================
-- NOTAS IMPORTANTES
-- ============================================================================
-- 1. La tabla usa una clave primaria compuesta (id_pedido, orden)
-- 2. Los puntos deben insertarse en orden secuencial (1, 2, 3...)
-- 3. Las coordenadas son para Esmeraldas, Ecuador (zona de operación)
-- 4. El campo fecha_evento se llena automáticamente con CURRENT_TIMESTAMP
-- 5. Si se elimina un pedido, sus puntos de tracking se eliminan automáticamente (CASCADE)

-- ============================================================================
-- ENDPOINTS DE LA API QUE USAN ESTA TABLA
-- ============================================================================
-- GET /tracking/pedido/{idPedido}/ruta
--   → Obtiene todos los puntos de tracking de un pedido
--   → Usado por: tracking_simulation_screen.dart
--
-- GET /tracking/pedido/{idPedido}
--   → Obtiene la ubicación actual del repartidor
--   → Usado por: order_tracking_screen.dart
--
-- PUT /ubicaciones/repartidor/{idRepartidor}
--   → Actualiza la posición GPS del repartidor en tiempo real
--   → Usado por: App del repartidor

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
