-- ============================================================================
-- SCRIPT DE CONFIGURACIÓN DE SOPORTE PARA UNITE SPEED DELIVERY
-- ============================================================================
-- Este script crea las tablas necesarias para el sistema de soporte y chat
-- Autor: Sistema Unite Speed
-- Fecha: 2024
-- Base de Datos: PostgreSQL
-- ============================================================================

-- TABLA: soporte_conversaciones
-- Almacena las conversaciones de soporte entre usuarios y agentes
-- ============================================================================
CREATE TABLE IF NOT EXISTS soporte_conversaciones (
    id_conversacion BIGSERIAL PRIMARY KEY,
    id_usuario BIGINT NOT NULL,
    rol VARCHAR(20) NOT NULL DEFAULT 'cliente',
    id_agente INTEGER NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'abierta',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_soporte_usuario FOREIGN KEY (id_usuario) 
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE
);

-- TABLA: soporte_mensajes
-- Almacena los mensajes dentro de cada conversación de soporte
-- ============================================================================
CREATE TABLE IF NOT EXISTS soporte_mensajes (
    id_mensaje BIGSERIAL PRIMARY KEY,
    id_conversacion BIGINT NOT NULL,
    id_remitente BIGINT NOT NULL,
    mensaje TEXT NOT NULL,
    es_agente BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_soporte_conversacion FOREIGN KEY (id_conversacion) 
        REFERENCES soporte_conversaciones(id_conversacion) ON DELETE CASCADE,
    CONSTRAINT fk_soporte_remitente FOREIGN KEY (id_remitente) 
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE
);

-- TABLA: soporte_respuestas_automaticas
-- Almacena respuestas predefinidas para el sistema de soporte automático
-- ============================================================================
CREATE TABLE IF NOT EXISTS soporte_respuestas_automaticas (
    id_respuesta SERIAL PRIMARY KEY,
    categoria VARCHAR(50) NOT NULL,
    pregunta TEXT NOT NULL,
    respuesta TEXT NOT NULL,
    keywords TEXT[],
    scope VARCHAR(20) DEFAULT 'general',
    canal VARCHAR(20) DEFAULT 'chat',
    idioma VARCHAR(10) DEFAULT 'es',
    tono VARCHAR(20) DEFAULT 'formal',
    prioridad SMALLINT DEFAULT 1,
    activo BOOLEAN DEFAULT TRUE,
    regex VARCHAR(255),
    intent VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- TABLA: chat_conversaciones
-- Almacena las conversaciones del chat bot y chat entre usuarios
-- ============================================================================
CREATE TABLE IF NOT EXISTS chat_conversaciones (
    id_conversacion BIGSERIAL PRIMARY KEY,
    id_cliente BIGINT,
    id_delivery BIGINT NULL,
    id_admin_soporte BIGINT NULL,
    id_pedido BIGINT NULL,
    es_bot BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_chat_cliente FOREIGN KEY (id_cliente) 
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_chat_delivery FOREIGN KEY (id_delivery) 
        REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    CONSTRAINT fk_chat_admin FOREIGN KEY (id_admin_soporte) 
        REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    CONSTRAINT fk_chat_pedido FOREIGN KEY (id_pedido) 
        REFERENCES pedidos(id_pedido) ON DELETE SET NULL
);

-- TABLA: chat_mensajes
-- Almacena los mensajes del chat (bot y humano)
-- ============================================================================
CREATE TABLE IF NOT EXISTS chat_mensajes (
    id_mensaje BIGSERIAL PRIMARY KEY,
    id_conversacion BIGINT NOT NULL,
    id_remitente BIGINT NOT NULL,
    id_destinatario BIGINT NULL,
    mensaje TEXT NOT NULL,
    es_bot BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_chat_msg_conversacion FOREIGN KEY (id_conversacion) 
        REFERENCES chat_conversaciones(id_conversacion) ON DELETE CASCADE,
    CONSTRAINT fk_chat_msg_remitente FOREIGN KEY (id_remitente) 
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_chat_msg_destinatario FOREIGN KEY (id_destinatario) 
        REFERENCES usuarios(id_usuario) ON DELETE SET NULL
);

-- ============================================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_soporte_conv_usuario ON soporte_conversaciones(id_usuario);
CREATE INDEX IF NOT EXISTS idx_soporte_conv_estado ON soporte_conversaciones(estado);
CREATE INDEX IF NOT EXISTS idx_soporte_msg_conversacion ON soporte_mensajes(id_conversacion);
CREATE INDEX IF NOT EXISTS idx_soporte_msg_fecha ON soporte_mensajes(created_at);

CREATE INDEX IF NOT EXISTS idx_chat_conv_cliente ON chat_conversaciones(id_cliente);
CREATE INDEX IF NOT EXISTS idx_chat_conv_pedido ON chat_conversaciones(id_pedido);
CREATE INDEX IF NOT EXISTS idx_chat_msg_conversacion ON chat_mensajes(id_conversacion);
CREATE INDEX IF NOT EXISTS idx_chat_msg_fecha ON chat_mensajes(created_at);

CREATE INDEX IF NOT EXISTS idx_respuestas_categoria ON soporte_respuestas_automaticas(categoria);
CREATE INDEX IF NOT EXISTS idx_respuestas_activo ON soporte_respuestas_automaticas(activo);

-- ============================================================================
-- USUARIO BOT PARA EL SISTEMA
-- ============================================================================
-- Crear usuario bot para el sistema de chat automático
INSERT INTO usuarios (nombre, correo, contrasena, telefono, id_rol, activo, created_at, updated_at)
VALUES ('CIA Bot', 'bot@unitespeed.com', '$2a$06$dummy.hash.for.bot.user.only', NULL, 
        (SELECT id_rol FROM roles WHERE nombre = 'admin' LIMIT 1), TRUE, NOW(), NOW())
ON CONFLICT (correo) DO NOTHING;

-- ============================================================================
-- RESPUESTAS AUTOMÁTICAS PREDEFINIDAS
-- ============================================================================
INSERT INTO soporte_respuestas_automaticas 
(categoria, pregunta, respuesta, keywords, scope, prioridad) VALUES

-- Categoría: Pedidos
('pedidos', '¿Cómo hago un pedido?', 
 'Para hacer un pedido: 1) Selecciona productos del catálogo, 2) Agrégalos al carrito, 3) Ve al checkout, 4) Confirma tu dirección, 5) Elige método de pago y confirma.',
 ARRAY['pedido', 'hacer', 'como', 'ordenar'], 'cliente', 1),

('pedidos', '¿Cuánto demora mi pedido?', 
 'Los pedidos normalmente tardan entre 30-45 minutos. Puedes seguir tu pedido en tiempo real desde la sección "Mis Pedidos".',
 ARRAY['tiempo', 'demora', 'cuanto', 'tardar'], 'cliente', 1),

('pedidos', '¿Puedo cancelar mi pedido?', 
 'Puedes cancelar tu pedido solo si está en estado "pendiente". Una vez que el repartidor lo tome, ya no se puede cancelar.',
 ARRAY['cancelar', 'anular', 'quitar'], 'cliente', 2),

-- Categoría: Delivery
('delivery', '¿Cómo me registro como repartidor?', 
 'Para ser repartidor: 1) Regístrate con rol "delivery", 2) Completa tu perfil, 3) Espera aprobación, 4) Comienza a recibir pedidos.',
 ARRAY['repartidor', 'delivery', 'registrar', 'trabajar'], 'delivery', 1),

('delivery', '¿Cómo tomo un pedido?', 
 'Ve a "Pedidos Disponibles", selecciona uno y presiona "Tomar Pedido". Asegúrate de estar cerca del negocio.',
 ARRAY['tomar', 'aceptar', 'pedido', 'disponible'], 'delivery', 1),

-- Categoría: Pagos
('pagos', '¿Qué métodos de pago aceptan?', 
 'Aceptamos: Efectivo, Tarjeta de crédito/débito, y transferencias bancarias.',
 ARRAY['pago', 'metodo', 'tarjeta', 'efectivo'], 'cliente', 1),

-- Categoría: Técnico
('tecnico', 'La app no funciona', 
 'Intenta: 1) Cerrar y abrir la app, 2) Verificar tu conexión a internet, 3) Actualizar la app. Si persiste, contáctanos.',
 ARRAY['app', 'funciona', 'error', 'problema'], 'general', 2),

-- Categoría: General
('general', 'Horarios de atención', 
 'Nuestro servicio está disponible de Lunes a Domingo de 8:00 AM a 10:00 PM.',
 ARRAY['horario', 'atencion', 'abierto', 'cerrado'], 'general', 1)

ON CONFLICT DO NOTHING;

-- ============================================================================
-- COMENTARIOS DE TABLAS
-- ============================================================================
COMMENT ON TABLE soporte_conversaciones IS 'Conversaciones de soporte entre usuarios y agentes';
COMMENT ON TABLE soporte_mensajes IS 'Mensajes dentro de conversaciones de soporte';
COMMENT ON TABLE soporte_respuestas_automaticas IS 'Respuestas predefinidas para soporte automático';
COMMENT ON TABLE chat_conversaciones IS 'Conversaciones del chat bot y entre usuarios';
COMMENT ON TABLE chat_mensajes IS 'Mensajes del chat (bot y humano)';

-- ============================================================================
-- VERIFICACIÓN DE DATOS
-- ============================================================================
-- Verificar que las tablas se crearon correctamente
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE tablename IN (
    'soporte_conversaciones', 
    'soporte_mensajes', 
    'soporte_respuestas_automaticas',
    'chat_conversaciones',
    'chat_mensajes'
)
ORDER BY tablename;

-- Verificar respuestas automáticas
SELECT categoria, COUNT(*) as total_respuestas 
FROM soporte_respuestas_automaticas 
WHERE activo = TRUE 
GROUP BY categoria 
ORDER BY categoria;

-- ============================================================================
-- CONSULTAS ÚTILES
-- ============================================================================

-- 1. Obtener conversaciones activas de soporte
-- SELECT * FROM soporte_conversaciones WHERE estado = 'abierta';

-- 2. Obtener mensajes de una conversación específica
-- SELECT * FROM soporte_mensajes WHERE id_conversacion = 1 ORDER BY created_at;

-- 3. Buscar respuesta automática por keywords
-- SELECT * FROM soporte_respuestas_automaticas 
-- WHERE activo = TRUE AND 'pedido' = ANY(keywords);

-- 4. Obtener estadísticas de soporte
-- SELECT estado, COUNT(*) FROM soporte_conversaciones GROUP BY estado;

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================