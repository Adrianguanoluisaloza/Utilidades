-- ============================================================================
-- SCHEMA COMPLETO UNIFICADO - UNITE SPEED DELIVERY
-- ============================================================================
-- CEO: Michael Ortiz
-- Versión: 1.0
-- Fecha: 2025
-- Base de Datos: PostgreSQL 12+
-- Descripción: Script unificado con todas las tablas, índices y datos de ejemplo
-- ============================================================================

BEGIN;

-- Limpiar schema existente (CUIDADO: Elimina todos los datos)
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
ALTER SCHEMA public OWNER TO CURRENT_USER;
SET search_path TO public;

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- TABLAS PRINCIPALES
-- ============================================================================

-- Roles de usuarios
CREATE TABLE roles (
    id_rol SERIAL PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

INSERT INTO roles (nombre) VALUES ('cliente'), ('delivery'), ('negocio'), ('admin'), ('soporte')
ON CONFLICT (nombre) DO NOTHING;

-- Usuarios
CREATE TABLE usuarios (
    id_usuario BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    correo VARCHAR(160) NOT NULL UNIQUE,
    contrasena TEXT NOT NULL,
    telefono VARCHAR(60),
    id_rol INTEGER NOT NULL REFERENCES roles(id_rol),
    activo BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- Negocios
CREATE TABLE negocios (
    id_negocio BIGSERIAL PRIMARY KEY,
    id_usuario BIGINT REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    nombre_comercial VARCHAR(150) NOT NULL,
    email VARCHAR(160),
    ruc VARCHAR(13),
    direccion TEXT,
    telefono VARCHAR(60),
    logo_url TEXT,
    activo BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- Categorías
CREATE TABLE categorias (
    id_categoria BIGSERIAL PRIMARY KEY,
    id_negocio BIGINT REFERENCES negocios(id_negocio) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- Productos
CREATE TABLE productos (
    id_producto BIGSERIAL PRIMARY KEY,
    id_negocio BIGINT NOT NULL REFERENCES negocios(id_negocio) ON DELETE CASCADE,
    id_categoria BIGINT REFERENCES categorias(id_categoria) ON DELETE SET NULL,
    nombre VARCHAR(160) NOT NULL,
    descripcion TEXT,
    precio NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
    disponible BOOLEAN DEFAULT TRUE NOT NULL,
    stock INTEGER DEFAULT 0 NOT NULL,
    imagen_url TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- Ubicaciones
CREATE TABLE ubicaciones (
    id_ubicacion BIGSERIAL PRIMARY KEY,
    id_usuario BIGINT REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    latitud DOUBLE PRECISION NOT NULL CHECK (latitud BETWEEN -90 AND 90),
    longitud DOUBLE PRECISION NOT NULL CHECK (longitud BETWEEN -180 AND 180),
    direccion TEXT NOT NULL,
    descripcion TEXT,
    activa BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- Pedidos
CREATE TABLE pedidos (
    id_pedido BIGSERIAL PRIMARY KEY,
    id_cliente BIGINT NOT NULL REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
    id_delivery BIGINT REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    id_ubicacion BIGINT REFERENCES ubicaciones(id_ubicacion) ON DELETE SET NULL,
    direccion_entrega TEXT,
    metodo_pago VARCHAR(30) NOT NULL,
    estado VARCHAR(30) NOT NULL DEFAULT 'pendiente',
    total NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    fecha_entrega TIMESTAMP WITHOUT TIME ZONE
);

-- Detalle de pedidos
CREATE TABLE detalle_pedidos (
    id_detalle BIGSERIAL PRIMARY KEY,
    id_pedido BIGINT NOT NULL REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    id_producto BIGINT NOT NULL REFERENCES productos(id_producto) ON DELETE RESTRICT,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- ============================================================================
-- TRACKING EN TIEMPO REAL
-- ============================================================================

-- Tracking de ruta (histórico)
CREATE TABLE tracking_ruta (
    id_tracking BIGSERIAL PRIMARY KEY,
    id_pedido BIGINT NOT NULL REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    latitud DOUBLE PRECISION NOT NULL,
    longitud DOUBLE PRECISION NOT NULL,
    registrado_en TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- Tracking de eventos (puntos de ruta predefinidos)
CREATE TABLE tracking_eventos (
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

-- ============================================================================
-- SISTEMA DE CHAT Y IA
-- ============================================================================

-- Conversaciones de chat
CREATE TABLE chat_conversaciones (
    id_conversacion BIGSERIAL PRIMARY KEY,
    id_pedido BIGINT REFERENCES pedidos(id_pedido) ON DELETE SET NULL,
    id_cliente BIGINT REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_delivery BIGINT REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    id_admin_soporte BIGINT REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    canal VARCHAR(50),
    es_chatbot BOOLEAN DEFAULT FALSE NOT NULL,
    activa BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- Mensajes de chat
CREATE TABLE chat_mensajes (
    id_mensaje BIGSERIAL PRIMARY KEY,
    id_conversacion BIGINT NOT NULL REFERENCES chat_conversaciones(id_conversacion) ON DELETE CASCADE,
    id_remitente BIGINT,
    id_destinatario BIGINT,
    tipo VARCHAR(20) DEFAULT 'texto' NOT NULL,
    mensaje TEXT NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- Categorías de respuestas IA
CREATE TABLE ia_categorias_respuesta (
    id_categoria_ia SERIAL PRIMARY KEY,
    nombre VARCHAR(80) UNIQUE NOT NULL,
    descripcion TEXT
);

-- Respuestas automáticas IA
CREATE TABLE ia_respuestas_automaticas (
    id_respuesta_ia BIGSERIAL PRIMARY KEY,
    id_categoria_ia INTEGER REFERENCES ia_categorias_respuesta(id_categoria_ia),
    canal VARCHAR(30) DEFAULT 'general' NOT NULL,
    scope_destino VARCHAR(30) DEFAULT 'cliente' NOT NULL,
    intent VARCHAR(80),
    keywords TEXT[],
    regex_match TEXT,
    respuesta TEXT NOT NULL,
    idioma VARCHAR(5) DEFAULT 'es' NOT NULL,
    tono VARCHAR(30) DEFAULT 'amigable',
    prioridad SMALLINT DEFAULT 3 NOT NULL,
    activo BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- ============================================================================
-- SISTEMA DE SOPORTE
-- ============================================================================

-- Conversaciones de soporte
CREATE TABLE soporte_conversaciones (
    id_soporte_conv BIGSERIAL PRIMARY KEY,
    id_usuario BIGINT REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_negocio BIGINT REFERENCES negocios(id_negocio) ON DELETE SET NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'abierta',
    id_agente_soporte BIGINT,
    canal VARCHAR(50) DEFAULT 'app',
    prioridad SMALLINT NOT NULL DEFAULT 3 CHECK (prioridad BETWEEN 1 AND 5),
    permite_ia BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- Mensajes de soporte
CREATE TABLE soporte_mensajes (
    id_sop_msj BIGSERIAL PRIMARY KEY,
    id_soporte_conv BIGINT NOT NULL REFERENCES soporte_conversaciones(id_soporte_conv) ON DELETE CASCADE,
    id_remitente BIGINT,
    es_agente BOOLEAN DEFAULT FALSE NOT NULL,
    tipo VARCHAR(20) DEFAULT 'texto' NOT NULL,
    mensaje TEXT NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- Respuestas predefinidas de soporte
CREATE TABLE soporte_respuestas_predef (
    id_respuesta BIGSERIAL PRIMARY KEY,
    categoria VARCHAR(60) NOT NULL,
    pregunta TEXT NOT NULL,
    respuesta TEXT NOT NULL,
    solo_cliente BOOLEAN DEFAULT FALSE NOT NULL,
    solo_delivery BOOLEAN DEFAULT FALSE NOT NULL,
    prioridad INTEGER DEFAULT 100 NOT NULL,
    activo BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- Usuarios de soporte
CREATE TABLE soporte_usuarios (
    id_soporte BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    correo VARCHAR(160) NOT NULL UNIQUE,
    contrasena_hash TEXT NOT NULL,
    activo BOOLEAN DEFAULT TRUE NOT NULL,
    fecha_registro TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- ============================================================================
-- RECOMENDACIONES Y OPINIONES
-- ============================================================================

-- Recomendaciones de productos
CREATE TABLE recomendaciones (
    id_recomendacion BIGSERIAL PRIMARY KEY,
    id_producto BIGINT NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
    id_usuario BIGINT NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    puntuacion INTEGER NOT NULL CHECK (puntuacion BETWEEN 1 AND 5),
    comentario TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE (id_producto, id_usuario)
);

-- ============================================================================
-- RESET DE PASSWORD
-- ============================================================================

CREATE TABLE password_resets (
    id BIGSERIAL PRIMARY KEY,
    correo VARCHAR(160) NOT NULL,
    codigo VARCHAR(6) NOT NULL,
    expira_en TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usado BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_password_resets_correo ON password_resets(correo);
CREATE INDEX idx_password_resets_codigo ON password_resets(codigo);

-- ============================================================================
-- FUNCIONES Y TRIGGERS
-- ============================================================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.created_at IS NULL THEN NEW.created_at := NOW(); END IF;
        NEW.updated_at := NOW();
    ELSIF TG_OP = 'UPDATE' THEN
        IF to_jsonb(NEW) - 'updated_at' IS DISTINCT FROM to_jsonb(OLD) - 'updated_at' THEN
            NEW.updated_at := NOW();
        END IF;
    END IF;
    RETURN NEW;
END; $$;

-- Función para hashear contraseñas
CREATE OR REPLACE FUNCTION trg_hash_password()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.contrasena IS NULL OR length(NEW.contrasena) < 4 THEN
        RAISE EXCEPTION 'Contraseña inválida';
    END IF;
    IF NEW.contrasena NOT LIKE '$2%' THEN
        NEW.contrasena := crypt(NEW.contrasena, gen_salt('bf', 10));
    END IF;
    RETURN NEW;
END; $$;

-- Función para matching de respuestas IA
CREATE OR REPLACE FUNCTION fn_chatbot_match_predef(
    p_texto TEXT,
    p_scope VARCHAR DEFAULT 'cliente',
    p_canal VARCHAR DEFAULT 'general',
    p_idioma VARCHAR DEFAULT 'es'
)
RETURNS TABLE(id_respuesta_ia BIGINT, respuesta TEXT, prioridad SMALLINT)
LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY
    WITH candidatos AS (
        SELECT *
        FROM ia_respuestas_automaticas
        WHERE activo = TRUE
        AND idioma = p_idioma
        AND (scope_destino = p_scope OR scope_destino = 'mixto')
        AND (canal = p_canal OR canal = 'general')
    ),
    kw AS (
        SELECT c.id_respuesta_ia, c.respuesta, c.prioridad, 1 AS orden
        FROM candidatos c
        WHERE c.keywords IS NOT NULL
        AND EXISTS (
            SELECT 1
            FROM unnest(c.keywords) k
            WHERE lower(p_texto) LIKE '%' || lower(k) || '%'
        )
    ),
    ft AS (
        SELECT c.id_respuesta_ia, c.respuesta, c.prioridad, 2 AS orden
        FROM candidatos c
        WHERE lower(c.respuesta) LIKE '%' || lower(p_texto) || '%'
        OR lower(p_texto) LIKE '%' || lower(COALESCE(c.intent, '')) || '%'
        LIMIT 5
    )
    SELECT r.id_respuesta_ia, r.respuesta, r.prioridad
    FROM (
        SELECT * FROM kw
        UNION ALL
        SELECT * FROM ft
    ) r
    ORDER BY r.orden, r.prioridad
    LIMIT 1;
END;
$$;

-- Aplicar triggers
CREATE TRIGGER usuarios_hash_before_insert BEFORE INSERT ON usuarios
FOR EACH ROW EXECUTE FUNCTION trg_hash_password();

CREATE TRIGGER usuarios_hash_before_update BEFORE UPDATE OF contrasena ON usuarios
FOR EACH ROW WHEN (NEW.contrasena IS DISTINCT FROM OLD.contrasena)
EXECUTE FUNCTION trg_hash_password();

CREATE TRIGGER usuarios_touch_updated BEFORE UPDATE ON usuarios
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER negocios_touch BEFORE UPDATE ON negocios
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER productos_touch BEFORE UPDATE ON productos
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER pedidos_touch BEFORE UPDATE ON pedidos
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ============================================================================

CREATE INDEX idx_usuarios_lower_correo ON usuarios (LOWER(correo));
CREATE INDEX idx_productos_negocio ON productos (id_negocio);
CREATE INDEX idx_productos_categoria ON productos (id_categoria);
CREATE INDEX idx_ubicaciones_usuario ON ubicaciones (id_usuario);
CREATE INDEX idx_pedidos_cliente ON pedidos (id_cliente);
CREATE INDEX idx_pedidos_delivery ON pedidos (id_delivery);
CREATE INDEX idx_pedidos_estado ON pedidos (estado);
CREATE INDEX idx_pedidos_estado_created ON pedidos (estado, created_at DESC);
CREATE INDEX idx_detalle_pedido ON detalle_pedidos (id_pedido);
CREATE INDEX idx_tracking_pedido ON tracking_eventos(id_pedido);
CREATE INDEX idx_tracking_fecha ON tracking_eventos(fecha_evento);
CREATE INDEX idx_tracking_ruta_pedido ON tracking_ruta (id_pedido, registrado_en DESC);
CREATE INDEX idx_chatconv_cliente ON chat_conversaciones (id_cliente);
CREATE INDEX idx_chatmsg_conv_created ON chat_mensajes (id_conversacion, created_at);

-- ============================================================================
-- DATOS DE EJEMPLO (SEED)
-- ============================================================================

-- Usuarios de ejemplo
INSERT INTO usuarios (nombre, correo, contrasena, telefono, id_rol)
VALUES
    ('Carlos Cliente', 'carlos@test.com', 'Cliente123!', '0999999999', 1),
    ('Pablo Delivery', 'pablo@test.com', 'Delivery123!', '0988888888', 2),
    ('Nelson Negocio', 'nelson@test.com', 'Negocio123!', '0977777777', 3),
    ('Ana Admin', 'ana@test.com', 'Admin123!', '0966666666', 4);

-- Categorías IA
INSERT INTO ia_categorias_respuesta (nombre, descripcion)
VALUES
    ('bienvenida', 'Saludos iniciales'),
    ('estado_pedido', 'Consultas sobre estado'),
    ('tiempo_entrega', 'Consultas sobre tiempos'),
    ('pago', 'Consultas sobre pagos'),
    ('promociones', 'Ofertas y descuentos');

-- Respuestas IA básicas
INSERT INTO ia_respuestas_automaticas (id_categoria_ia, intent, keywords, respuesta, tono, prioridad)
VALUES
    (1, 'saludo_inicial', ARRAY['hola','buenos','hey'], '¡Hola! ¿En qué puedo ayudarte hoy?', 'amigable', 1),
    (2, 'pedido_procesando', ARRAY['estado','pedido','dónde'], 'Tu pedido está siendo procesado. Te avisaré cuando salga a reparto.', 'amigable', 1),
    (3, 'tiempo_estimado', ARRAY['cuánto','tiempo','minutos'], 'El tiempo estimado de entrega es de 20 a 30 minutos.', 'amigable', 1);

-- Datos de tracking para pedido #1
INSERT INTO tracking_eventos (id_pedido, orden, latitud, longitud, descripcion)
VALUES
    (1, 1, 0.970362, -79.652557, 'Saliendo del negocio'),
    (1, 2, 0.970524, -79.655029, 'Avanzando por Av. Principal'),
    (1, 3, 0.976980, -79.654840, 'Pasando por el parque'),
    (1, 4, 0.983438, -79.655182, 'A 2 cuadras del destino'),
    (1, 5, 0.984854, -79.657457, 'A 1 cuadra del destino'),
    (1, 6, 0.988033, -79.659094, 'Llegando al destino')
ON CONFLICT (id_pedido, orden) DO NOTHING;

COMMIT;

-- ============================================================================
-- VERIFICACIÓN
-- ============================================================================

SELECT 'Schema creado exitosamente' AS status;
SELECT COUNT(*) AS total_tablas FROM information_schema.tables WHERE table_schema = 'public';
SELECT COUNT(*) AS total_usuarios FROM usuarios;
SELECT COUNT(*) AS total_tracking FROM tracking_eventos;

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
-- CEO: Michael Ortiz
-- Unite Speed Delivery - Sistema Completo
-- ============================================================================
