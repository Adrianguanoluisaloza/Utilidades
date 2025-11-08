-- Rebuild schema for sspeed backend (PostgreSQL)
-- Idempotent when run on a fresh empty database. Execute with psql -f rebuild_database.sql

BEGIN;

-- Wipe existing objects
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
ALTER SCHEMA public OWNER TO CURRENT_USER;
SET search_path TO public;

-- Extensions needed by the triggers (bcrypt helpers)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- Core catalog tables
-- =====================================================

CREATE TABLE roles (
    id_rol        SERIAL PRIMARY KEY,
    nombre        VARCHAR(50) UNIQUE NOT NULL,
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

INSERT INTO roles (nombre) VALUES
    ('cliente'),
    ('delivery'),
    ('negocio'),
    ('admin'),
    ('soporte')
ON CONFLICT (nombre) DO NOTHING;

CREATE TABLE usuarios (
    id_usuario    BIGSERIAL PRIMARY KEY,
    nombre        VARCHAR(120) NOT NULL,
    correo        VARCHAR(160) NOT NULL UNIQUE,
    contrasena    TEXT NOT NULL,
    telefono      VARCHAR(60),
    id_rol        INTEGER NOT NULL REFERENCES roles(id_rol),
    activo        BOOLEAN DEFAULT TRUE NOT NULL,
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE negocios (
    id_negocio        BIGSERIAL PRIMARY KEY,
    id_usuario        BIGINT REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    nombre_comercial  VARCHAR(150) NOT NULL,
    email             VARCHAR(160),
    ruc               VARCHAR(13),
    direccion         TEXT,
    telefono          VARCHAR(60),
    logo_url          TEXT,
    activo            BOOLEAN DEFAULT TRUE NOT NULL,
    created_at        TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at        TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE categorias (
    id_categoria  BIGSERIAL PRIMARY KEY,
    id_negocio    BIGINT REFERENCES negocios(id_negocio) ON DELETE CASCADE,
    nombre        VARCHAR(100) NOT NULL,
    descripcion   TEXT,
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE productos (
    id_producto   BIGSERIAL PRIMARY KEY,
    id_negocio    BIGINT NOT NULL REFERENCES negocios(id_negocio) ON DELETE CASCADE,
    id_categoria  BIGINT REFERENCES categorias(id_categoria) ON DELETE SET NULL,
    nombre        VARCHAR(160) NOT NULL,
    descripcion   TEXT,
    precio        NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
    disponible    BOOLEAN DEFAULT TRUE NOT NULL,
    stock         INTEGER DEFAULT 0 NOT NULL,
    imagen_url    TEXT,
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- =====================================================
-- Pedidos y detalle
-- =====================================================

CREATE TABLE ubicaciones (
    id_ubicacion BIGSERIAL PRIMARY KEY,
    id_usuario   BIGINT REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    latitud      DOUBLE PRECISION NOT NULL CHECK (latitud  BETWEEN -90  AND 90),
    longitud     DOUBLE PRECISION NOT NULL CHECK (longitud BETWEEN -180 AND 180),
    direccion    TEXT NOT NULL,
    descripcion  TEXT,
    activa       BOOLEAN DEFAULT TRUE NOT NULL,
    created_at   TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at   TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE pedidos (
    id_pedido     BIGSERIAL PRIMARY KEY,
    id_cliente    BIGINT NOT NULL REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
    id_delivery   BIGINT REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    id_ubicacion  BIGINT REFERENCES ubicaciones(id_ubicacion) ON DELETE SET NULL,
    direccion_entrega TEXT,
    metodo_pago   VARCHAR(30) NOT NULL,
    estado        VARCHAR(30) NOT NULL DEFAULT 'pendiente',
    total         NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    fecha_entrega TIMESTAMP WITHOUT TIME ZONE
);

CREATE TABLE detalle_pedidos (
    id_detalle      BIGSERIAL PRIMARY KEY,
    id_pedido       BIGINT NOT NULL REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    id_producto     BIGINT NOT NULL REFERENCES productos(id_producto) ON DELETE RESTRICT,
    cantidad        INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal        NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
    created_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE tracking_ruta (
    id_tracking   BIGSERIAL PRIMARY KEY,
    id_pedido     BIGINT NOT NULL REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    latitud       DOUBLE PRECISION NOT NULL,
    longitud      DOUBLE PRECISION NOT NULL,
    registrado_en TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- =====================================================
-- Recomendaciones / feedback
-- =====================================================

CREATE TABLE recomendaciones (
    id_recomendacion BIGSERIAL PRIMARY KEY,
    id_producto      BIGINT NOT NULL REFERENCES productos(id_producto) ON DELETE CASCADE,
    id_usuario       BIGINT NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    puntuacion       INTEGER NOT NULL CHECK (puntuacion BETWEEN 1 AND 5),
    comentario       TEXT,
    created_at       TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE (id_producto, id_usuario)
);

-- =====================================================
-- Chat (clientes/delivery/admin)
-- =====================================================

CREATE TABLE chat_conversaciones (
    id_conversacion BIGSERIAL PRIMARY KEY,
    id_pedido       BIGINT REFERENCES pedidos(id_pedido) ON DELETE SET NULL,
    id_cliente      BIGINT REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_delivery     BIGINT REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    id_admin_soporte BIGINT REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    canal           VARCHAR(50),
    es_chatbot      BOOLEAN DEFAULT FALSE NOT NULL,
    activa          BOOLEAN DEFAULT TRUE NOT NULL,
    created_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE chat_mensajes (
    id_mensaje     BIGSERIAL PRIMARY KEY,
    id_conversacion BIGINT NOT NULL REFERENCES chat_conversaciones(id_conversacion) ON DELETE CASCADE,
    id_remitente   BIGINT,
    id_destinatario BIGINT,
    tipo           VARCHAR(20) DEFAULT 'texto' NOT NULL,
    mensaje        TEXT NOT NULL,
    created_at     TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at     TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE ia_categorias_respuesta (
  id_categoria_ia SERIAL PRIMARY KEY,
  nombre           VARCHAR(80) UNIQUE NOT NULL,
  descripcion      TEXT
);

CREATE TABLE ia_respuestas_automaticas (
  id_respuesta_ia  BIGSERIAL PRIMARY KEY,
  id_categoria_ia INTEGER REFERENCES ia_categorias_respuesta(id_categoria_ia),
  canal           VARCHAR(30) DEFAULT 'general' NOT NULL,
  scope_destino   VARCHAR(30) DEFAULT 'cliente' NOT NULL,
  intent          VARCHAR(80),
  keywords        TEXT[],
  regex_match     TEXT,
  respuesta       TEXT NOT NULL,
  idioma          VARCHAR(5) DEFAULT 'es' NOT NULL,
  tono            VARCHAR(30) DEFAULT 'amigable',
  prioridad       SMALLINT DEFAULT 3 NOT NULL,
  activo          BOOLEAN DEFAULT TRUE NOT NULL,
  created_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- =====================================================
-- Soporte tickets + respuestas
-- =====================================================

CREATE TABLE soporte_conversaciones (
    id_soporte_conv BIGSERIAL PRIMARY KEY,
    id_usuario      BIGINT REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_negocio      BIGINT REFERENCES negocios(id_negocio) ON DELETE SET NULL,
    estado          VARCHAR(20) NOT NULL DEFAULT 'abierta',
    id_agente_soporte BIGINT,
    canal           VARCHAR(50) DEFAULT 'app',
    prioridad       SMALLINT NOT NULL DEFAULT 3 CHECK (prioridad BETWEEN 1 AND 5),
    permite_ia      BOOLEAN DEFAULT FALSE NOT NULL,
    created_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE soporte_mensajes (
    id_sop_msj     BIGSERIAL PRIMARY KEY,
    id_soporte_conv BIGINT NOT NULL REFERENCES soporte_conversaciones(id_soporte_conv) ON DELETE CASCADE,
    id_remitente   BIGINT,
    es_agente      BOOLEAN DEFAULT FALSE NOT NULL,
    tipo           VARCHAR(20) DEFAULT 'texto' NOT NULL,
    mensaje        TEXT NOT NULL,
    created_at     TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE soporte_respuestas_predef (
    id_respuesta   BIGSERIAL PRIMARY KEY,
    categoria      VARCHAR(60) NOT NULL,
    pregunta       TEXT NOT NULL,
    respuesta      TEXT NOT NULL,
    solo_cliente   BOOLEAN DEFAULT FALSE NOT NULL,
    solo_delivery  BOOLEAN DEFAULT FALSE NOT NULL,
    prioridad      INTEGER DEFAULT 100 NOT NULL,
    activo         BOOLEAN DEFAULT TRUE NOT NULL,
    created_at     TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE soporte_usuarios (
    id_soporte     BIGSERIAL PRIMARY KEY,
    nombre         VARCHAR(120) NOT NULL,
    correo         VARCHAR(160) NOT NULL UNIQUE,
    contrasena_hash TEXT NOT NULL,
    activo         BOOLEAN DEFAULT TRUE NOT NULL,
    fecha_registro TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- =====================================================
-- Funciones y triggers (solo las necesarias para app)
-- =====================================================

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

CREATE TRIGGER usuarios_hash_before_insert
BEFORE INSERT ON usuarios
FOR EACH ROW EXECUTE FUNCTION trg_hash_password();

CREATE TRIGGER usuarios_hash_before_update
BEFORE UPDATE OF contrasena ON usuarios
FOR EACH ROW WHEN (NEW.contrasena IS DISTINCT FROM OLD.contrasena)
EXECUTE FUNCTION trg_hash_password();

CREATE TRIGGER usuarios_touch_updated
BEFORE UPDATE ON usuarios
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER negocios_touch
BEFORE UPDATE ON negocios
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER categorias_touch
BEFORE UPDATE ON categorias
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER productos_touch
BEFORE UPDATE ON productos
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER ubicaciones_touch
BEFORE UPDATE ON ubicaciones
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER pedidos_touch
BEFORE UPDATE ON pedidos
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER detalle_pedidos_touch
BEFORE UPDATE ON detalle_pedidos
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER tracking_touch
BEFORE UPDATE ON tracking_ruta
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER chat_conversaciones_touch
BEFORE UPDATE ON chat_conversaciones
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER chat_mensajes_touch
BEFORE UPDATE ON chat_mensajes
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER soporte_conv_touch
BEFORE UPDATE ON soporte_conversaciones
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================
-- Supporting functions for delivery flow
-- =====================================================

CREATE OR REPLACE FUNCTION claim_pedido(p_id_pedido BIGINT, p_id_delivery BIGINT)
RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE v_ok BOOLEAN := FALSE;
BEGIN
  UPDATE pedidos
     SET id_delivery = p_id_delivery,
         estado = CASE WHEN estado = 'pendiente' THEN 'en preparacion' ELSE estado END
   WHERE id_pedido = p_id_pedido
     AND id_delivery IS NULL
     AND estado IN ('pendiente','en preparacion')
   RETURNING TRUE INTO v_ok;
  RETURN COALESCE(v_ok, FALSE);
END;
$$;

CREATE OR REPLACE FUNCTION set_estado_pedido(p_id_pedido BIGINT, p_estado TEXT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE v_estado_actual TEXT;
BEGIN
  SELECT estado INTO v_estado_actual FROM pedidos WHERE id_pedido = p_id_pedido FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Pedido % no existe', p_id_pedido; END IF;

  IF v_estado_actual = 'pendiente'      AND p_estado NOT IN ('en preparacion','cancelado') THEN
    RAISE EXCEPTION 'Transición inválida % -> %', v_estado_actual, p_estado;
  ELSIF v_estado_actual = 'en preparacion' AND p_estado NOT IN ('en camino','cancelado') THEN
    RAISE EXCEPTION 'Transición inválida % -> %', v_estado_actual, p_estado;
  ELSIF v_estado_actual = 'en camino'   AND p_estado NOT IN ('entregado','cancelado') THEN
    RAISE EXCEPTION 'Transición inválida % -> %', v_estado_actual, p_estado;
  ELSIF v_estado_actual IN ('entregado','cancelado') THEN
    RAISE EXCEPTION 'El pedido ya está %', v_estado_actual;
  END IF;

  UPDATE pedidos
     SET estado = p_estado,
         fecha_entrega = CASE WHEN p_estado = 'entregado' THEN NOW() ELSE fecha_entrega END
   WHERE id_pedido = p_id_pedido;
END;
$$;

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

-- =====================================================
-- Materialized views used by dashboard (minimal versions)
-- =====================================================

CREATE OR REPLACE VIEW vw_admin_pedidos AS
SELECT
    p.id_pedido,
    p.estado,
    p.total,
    p.created_at,
    c.nombre AS cliente_nombre,
    c.correo  AS cliente_correo,
    d.nombre AS delivery_nombre,
    COUNT(dp.*)::BIGINT AS items,
    COALESCE(SUM(dp.cantidad),0)::BIGINT AS unidades
FROM pedidos p
LEFT JOIN usuarios c ON c.id_usuario = p.id_cliente
LEFT JOIN usuarios d ON d.id_usuario = p.id_delivery
LEFT JOIN detalle_pedidos dp ON dp.id_pedido = p.id_pedido
GROUP BY p.id_pedido, p.estado, p.total, p.created_at, c.nombre, c.correo, d.nombre;

CREATE OR REPLACE VIEW vw_delivery_tracking AS
WITH last_t AS (
  SELECT DISTINCT ON (id_pedido)
         id_pedido,
         latitud,
         longitud,
         registrado_en
    FROM tracking_ruta
   ORDER BY id_pedido, registrado_en DESC
)
SELECT p.id_pedido,
       p.estado,
       cli.nombre AS cliente,
       del.nombre AS delivery,
       t.latitud,
       t.longitud,
       t.registrado_en AS ultima_posicion
  FROM pedidos p
  LEFT JOIN usuarios cli ON cli.id_usuario = p.id_cliente
  LEFT JOIN usuarios del ON del.id_usuario = p.id_delivery
  LEFT JOIN last_t t ON t.id_pedido = p.id_pedido;

-- =====================================================
-- Datos de ejemplo (seed)
-- =====================================================

-- Usuarios base: clientes, repartidores, admins y dueños de negocio
INSERT INTO usuarios (nombre, correo, contrasena, telefono, id_rol)
VALUES
  ('Carlos Cliente',  'carlos.cliente@example.com',  'Cliente123!',  '555-0101', (SELECT id_rol FROM roles WHERE nombre = 'cliente')),
  ('Diana Cliente',   'diana.cliente@example.com',   'Cliente123!',  '555-0102', (SELECT id_rol FROM roles WHERE nombre = 'cliente')),
  ('Ana Admin',       'ana.admin@example.com',       'Admin123!',    '555-0201', (SELECT id_rol FROM roles WHERE nombre = 'admin')),
  ('Pablo Delivery',  'pablo.delivery@example.com',  'Delivery123!', '555-0301', (SELECT id_rol FROM roles WHERE nombre = 'delivery')),
  ('Laura Delivery',  'laura.delivery@example.com',  'Delivery123!', '555-0302', (SELECT id_rol FROM roles WHERE nombre = 'delivery')),
  ('Marco Delivery',  'marco.delivery@example.com',  'Delivery123!', '555-0303', (SELECT id_rol FROM roles WHERE nombre = 'delivery')),
  ('Nelson Negocio',  'nelson.negocio@example.com',  'Negocio123!',  '555-0401', (SELECT id_rol FROM roles WHERE nombre = 'negocio')),
  ('Beatriz Negocio', 'beatriz.negocio@example.com', 'Negocio123!',  '555-0402', (SELECT id_rol FROM roles WHERE nombre = 'negocio')),
  ('Rocio Negocio',   'rocio.negocio@example.com',   'Negocio123!',  '555-0403', (SELECT id_rol FROM roles WHERE nombre = 'negocio')),
  ('Victor Negocio',  'victor.negocio@example.com',  'Negocio123!',  '555-0404', (SELECT id_rol FROM roles WHERE nombre = 'negocio'));

-- Ubicaciones de clientes y repartidores
INSERT INTO ubicaciones (id_usuario, latitud, longitud, direccion, descripcion)
VALUES
  ((SELECT id_usuario FROM usuarios WHERE correo = 'carlos.cliente@example.com'),  -12.0464, -77.0428, 'Av. Lima 123', 'Casa - Carlos'),
  ((SELECT id_usuario FROM usuarios WHERE correo = 'diana.cliente@example.com'),   -12.0600, -77.0300, 'Jr. Cusco 456', 'Departamento - Diana'),
  ((SELECT id_usuario FROM usuarios WHERE correo = 'pablo.delivery@example.com'),  -12.0550, -77.0200, 'Base Delivery 1', 'Punto de partida Pablo'),
  ((SELECT id_usuario FROM usuarios WHERE correo = 'laura.delivery@example.com'),  -12.0500, -77.0100, 'Base Delivery 2', 'Punto de partida Laura'),
  ((SELECT id_usuario FROM usuarios WHERE correo = 'marco.delivery@example.com'),  -12.0450, -77.0000, 'Base Delivery 3', 'Punto de partida Marco');

-- Negocios y categorías
INSERT INTO negocios (id_usuario, nombre_comercial, email, ruc, direccion, telefono, logo_url)
VALUES
  ((SELECT id_usuario FROM usuarios WHERE correo = 'nelson.negocio@example.com'), 'La Pizzería Lima', 'pizzeria@example.com', '20111111111', 'Av. Primavera 456', '555-0501', 'https://example.com/pizza.png'),
  ((SELECT id_usuario FROM usuarios WHERE correo = 'beatriz.negocio@example.com'), 'Sushi Express', 'sushi@example.com', '20222222222', 'Av. Arequipa 890', '555-0502', 'https://example.com/sushi.png'),
  ((SELECT id_usuario FROM usuarios WHERE correo = 'rocio.negocio@example.com'),   'Café Andino', 'cafe@example.com', '20333333333', 'Jr. Colmena 234', '555-0503', 'https://example.com/cafe.png'),
  ((SELECT id_usuario FROM usuarios WHERE correo = 'victor.negocio@example.com'),  'Burger Station', 'burger@example.com', '20444444444', 'Av. Angamos 765', '555-0504', 'https://example.com/burger.png');

INSERT INTO categorias (id_negocio, nombre, descripcion)
VALUES
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'La Pizzería Lima'), 'Pizzas', 'Pizzas artesanales en horno de leña'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'Sushi Express'), 'Makis', 'Variedad de makis frescos'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'Café Andino'), 'Bebidas', 'Cafés especiales y bebidas calientes'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'Burger Station'), 'Hamburguesas', 'Hamburguesas gourmet'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'La Pizzería Lima'), 'Pastas', 'Pastas frescas y tradicionales'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'Sushi Express'), 'Nigiri', 'Nigiri de pescados frescos'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'Café Andino'), 'Postres', 'Postres artesanales y tortas'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'Burger Station'), 'Acompañamientos', 'Papas, aros de cebolla y más'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'La Pizzería Lima'), 'Ensaladas', 'Ensaladas frescas y saludables'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'Sushi Express'), 'Combos', 'Combos especiales de sushi'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'Café Andino'), 'Otros', 'Otros productos disponibles');

-- Productos con stock inicial
INSERT INTO productos (id_negocio, id_categoria, nombre, descripcion, precio, disponible, stock, imagen_url)
VALUES
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'La Pizzería Lima'),
   (SELECT id_categoria FROM categorias WHERE nombre = 'Pizzas'),
   'Pizza Margarita', 'Masa madre, mozzarella y albahaca fresca', 32.50, TRUE, 25, 'https://example.com/pizza-margarita.png'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'Sushi Express'),
   (SELECT id_categoria FROM categorias WHERE nombre = 'Makis'),
   'Maki Acevichado', 'Relleno de pescado blanco, salsa acevichada', 28.90, TRUE, 40, 'https://example.com/maki-acevichado.png'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'Café Andino'),
   (SELECT id_categoria FROM categorias WHERE nombre = 'Bebidas'),
   'Latte Andino', 'Espresso con leche vaporizada y canela', 14.00, TRUE, 60, 'https://example.com/latte-andino.png'),
  ((SELECT id_negocio FROM negocios WHERE nombre_comercial = 'Burger Station'),
   (SELECT id_categoria FROM categorias WHERE nombre = 'Hamburguesas'),
   'Burger Station Clásica', 'Carne angus, queso cheddar, tocino y salsa especial', 25.00, TRUE, 35, 'https://example.com/burger-classic.png');

-- =====================================================
-- Tabla de opiniones (para landing page web)
-- =====================================================

CREATE TABLE opiniones (
  id_opinion       BIGSERIAL PRIMARY KEY,
  id_usuario       BIGINT REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
  nombre           VARCHAR(150),
  email            VARCHAR(160),
  rating           SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comentario       TEXT NOT NULL,
  clasificacion    VARCHAR(20) GENERATED ALWAYS AS (
                      CASE 
                        WHEN rating <= 2 THEN 'mala'
                        WHEN rating = 3 THEN 'regular'
                        WHEN rating = 4 THEN 'buena'
                        ELSE 'excelente'
                      END
                    ) STORED,
  plataforma       VARCHAR(40) DEFAULT 'web',
  estado           VARCHAR(20) NOT NULL DEFAULT 'aprobada' CHECK (estado IN ('pendiente','aprobada','rechazada')),
  created_at       TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at       TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- =====================================================
-- Tabla de tracking eventos (para simulación)
-- =====================================================

CREATE TABLE tracking_eventos (
    id_pedido     BIGINT NOT NULL REFERENCES pedidos(id_pedido) ON DELETE CASCADE,
    orden         INTEGER NOT NULL,
    latitud       DOUBLE PRECISION NOT NULL,
    longitud      DOUBLE PRECISION NOT NULL,
    descripcion   TEXT,
    fecha_evento  TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
    PRIMARY KEY (id_pedido, orden)
);

-- =====================================================
-- Tabla de password resets
-- =====================================================

CREATE TABLE password_resets (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
  code_hash TEXT NOT NULL,
  created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL,
  expires_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  used_at TIMESTAMP WITHOUT TIME ZONE NULL,
  created_by BIGINT REFERENCES usuarios(id_usuario) ON DELETE SET NULL
);

-- =====================================================
-- Chat predefinido para landing page web
-- =====================================================

CREATE TABLE chat_web_predefinido (
    id_pregunta   BIGSERIAL PRIMARY KEY,
    pregunta      TEXT NOT NULL,
    respuesta     TEXT NOT NULL,
    categoria     VARCHAR(50) DEFAULT 'general',
    orden         INTEGER DEFAULT 1,
    activo        BOOLEAN DEFAULT TRUE NOT NULL,
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW() NOT NULL
);

-- =====================================================
-- Triggers para nuevas tablas
-- =====================================================

CREATE TRIGGER opiniones_touch
BEFORE UPDATE ON opiniones
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================
-- Vistas para opiniones
-- =====================================================

CREATE OR REPLACE VIEW vw_opiniones_resumen AS
SELECT 
  clasificacion,
  COUNT(*) AS total,
  ROUND(AVG(rating),2) AS rating_promedio,
  SUM(CASE WHEN estado='aprobada' THEN 1 ELSE 0 END) AS aprobadas,
  SUM(CASE WHEN estado='pendiente' THEN 1 ELSE 0 END) AS pendientes,
  SUM(CASE WHEN estado='rechazada' THEN 1 ELSE 0 END) AS rechazadas
FROM opiniones
GROUP BY clasificacion;

-- Recomendaciones de clientes sobre productos
INSERT INTO recomendaciones (id_producto, id_usuario, puntuacion, comentario)
VALUES
  ((SELECT id_producto FROM productos WHERE nombre = 'Pizza Margarita'),
   (SELECT id_usuario FROM usuarios WHERE correo = 'carlos.cliente@example.com'), 5, 'Sabor auténtico, llegará caliente.'),
  ((SELECT id_producto FROM productos WHERE nombre = 'Maki Acevichado'),
   (SELECT id_usuario FROM usuarios WHERE correo = 'diana.cliente@example.com'), 4, 'Muy fresco, aunque llegó con poca salsa.');

-- Respuestas predeterminadas del chatbot (Unite Speed Delivery)
INSERT INTO ia_categorias_respuesta (nombre, descripcion)
VALUES
  ('bienvenida', 'Saludos iniciales y mensajes de bienvenida'),
  ('estado_pedido', 'Consultas sobre el estado actual del pedido'),
  ('tiempo_entrega', 'Consultas sobre tiempos estimados de entrega'),
  ('pago', 'Consultas sobre formas de pago y problemas de transacciones'),
  ('cancelacion', 'Información sobre cancelación de pedidos'),
  ('promociones', 'Ofertas, descuentos y promociones activas'),
  ('agradecimiento', 'Mensajes de agradecimiento al cliente'),
  ('error_app', 'Respuestas ante errores técnicos de la aplicación'),
  ('despedida', 'Mensajes de despedida'),
  ('fuera_tema', 'Respuestas cuando la consulta no es reconocida'),
  ('soporte_saludo', 'Saludos del equipo de soporte'),
  ('soporte_retraso', 'Manejo de quejas por retrasos'),
  ('soporte_faltante', 'Productos faltantes o incompletos'),
  ('soporte_reembolso', 'Gestión de reembolsos');

INSERT INTO ia_respuestas_automaticas (id_categoria_ia, canal, scope_destino, intent, keywords, respuesta, idioma, tono, prioridad)
VALUES
  -- ✅ BIENVENIDA (5 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'bienvenida'), 'general', 'cliente', 'saludo_inicial', 
   ARRAY['hola','buenos','buenas','hey','saludos'], '¡Hola! ¿En qué puedo ayudarte hoy?', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'bienvenida'), 'general', 'cliente', 'saludo_inicial', 
   ARRAY['hola','bienvenido'], '¡Bienvenido! Estoy listo para ayudarte con tu pedido.', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'bienvenida'), 'general', 'cliente', 'saludo_inicial', 
   ARRAY['hola','qué tal','cómo estás'], '¡Qué gusto tenerte aquí! ¿Quieres saber algo sobre tu pedido?', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'bienvenida'), 'general', 'cliente', 'saludo_inicial', 
   ARRAY['hola','ayuda'], '¡Hola! ¿Listo para ordenar algo rico?', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'bienvenida'), 'general', 'cliente', 'saludo_marca', 
   ARRAY['hola','unite','speed'], '¡Bienvenido a Unite Speed Delivery! Te ayudo con lo que necesites 🚀', 'es', 'amigable', 1),

  -- ✅ ESTADO DEL PEDIDO (5 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'estado_pedido'), 'general', 'cliente', 'pedido_procesando', 
   ARRAY['estado','pedido','dónde','proceso'], 'Tu pedido está siendo procesado. Te avisaré cuando salga a reparto.', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'estado_pedido'), 'general', 'cliente', 'pedido_preparando', 
   ARRAY['pedido','preparando','listo'], 'Todavía estamos preparando tu pedido, ¡ya falta poco!', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'estado_pedido'), 'general', 'cliente', 'pedido_enviado', 
   ARRAY['enviado','camino','salió'], 'Tu pedido ya fue enviado y está en camino hacia tu dirección.', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'estado_pedido'), 'general', 'cliente', 'pedido_cerca', 
   ARRAY['cerca','llegar','cuando'], 'Tu pedido ya está cerca de llegar, mantente atento 📦', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'estado_pedido'), 'general', 'cliente', 'pedido_tracking', 
   ARRAY['seguir','rastrear','ubicación'], 'En Unite Speed Delivery seguimos tu pedido en tiempo real. ¡Va en camino! 🚚', 'es', 'amigable', 1),

  -- ✅ TIEMPO DE ENTREGA (5 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'tiempo_entrega'), 'general', 'cliente', 'tiempo_estimado', 
   ARRAY['cuánto','tiempo','demora','minutos'], 'El tiempo estimado de entrega es de 20 a 30 minutos.', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'tiempo_entrega'), 'general', 'cliente', 'tiempo_media_hora', 
   ARRAY['cuánto falta','cuándo llega'], 'Tu pedido llegará aproximadamente en media hora.', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'tiempo_entrega'), 'general', 'cliente', 'tiempo_preparacion', 
   ARRAY['preparando','cuánto'], 'Estamos preparando tu pedido, el tiempo estimado aparecerá en la app.', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'tiempo_entrega'), 'general', 'cliente', 'repartidor_salió', 
   ARRAY['repartidor','salió','minutos'], 'El repartidor ya salió. En pocos minutos tocarán tu puerta.', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'tiempo_entrega'), 'general', 'cliente', 'rapido_seguro', 
   ARRAY['rápido','pronto'], 'En Unite Speed Delivery hacemos lo posible por entregarte todo rápido y seguro ✅', 'es', 'amigable', 1),

  -- ✅ PAGO (5 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'pago'), 'general', 'cliente', 'metodos_pago', 
   ARRAY['pago','tarjeta','efectivo','transferencia'], 'Aceptamos pagos en efectivo, tarjeta y transferencia.', 'es', 'amigable', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'pago'), 'general', 'cliente', 'pago_fallo', 
   ARRAY['falló','error','rechazado'], 'Si tu pago falló, intenta nuevamente o cambia de método de pago.', 'es', 'amigable', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'pago'), 'general', 'cliente', 'pago_exitoso', 
   ARRAY['pago','confirmado','registrado'], 'El pago se registró correctamente ✅', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'pago'), 'general', 'cliente', 'pago_problema', 
   ARRAY['error','pago','no funciona'], 'Parece que hubo un error con el pago, inténtalo otra vez por favor.', 'es', 'amigable', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'pago'), 'general', 'cliente', 'seguridad_pago', 
   ARRAY['seguro','protegido','seguridad'], 'En Unite Speed Delivery protegemos tus pagos con seguridad cifrada 🔒', 'es', 'amigable', 1),

  -- ✅ CANCELACIÓN (5 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'cancelacion'), 'general', 'cliente', 'como_cancelar', 
   ARRAY['cancelar','anular','eliminar'], 'Puedes cancelar tu pedido antes de que pase a reparto.', 'es', 'amigable', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'cancelacion'), 'general', 'cliente', 'proceso_cancelacion', 
   ARRAY['cómo cancelo','cancelación'], 'Para cancelar tu pedido entra al detalle del pedido y pulsa "Cancelar".', 'es', 'amigable', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'cancelacion'), 'general', 'cliente', 'no_cancelable', 
   ARRAY['cancelar','repartidor'], 'Una vez que el repartidor salió, ya no es posible cancelar el pedido.', 'es', 'amigable', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'cancelacion'), 'general', 'cliente', 'cancelar_error', 
   ARRAY['error','cancelar','ayuda'], 'Si necesitas cancelar por error, contáctanos por soporte.', 'es', 'amigable', 3),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'cancelacion'), 'general', 'cliente', 'tiempo_cancelacion', 
   ARRAY['tiempo','cancelar','minutos'], 'Unite Speed Delivery solo permite cancelaciones dentro de los primeros minutos.', 'es', 'amigable', 2),

  -- ✅ PROMOCIONES (5 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'promociones'), 'general', 'cliente', 'promo_activas', 
   ARRAY['promoción','descuento','oferta'], 'Hoy tenemos promociones activas en varios locales. ¡Aprovecha!', 'es', 'amigable', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'promociones'), 'general', 'cliente', 'ver_ofertas', 
   ARRAY['dónde','ofertas','descuentos'], 'Puedes ver los descuentos disponibles en la sección de ofertas.', 'es', 'amigable', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'promociones'), 'general', 'cliente', 'promo_efectivo', 
   ARRAY['promoción','efectivo'], 'Algunas promociones aplican solo para pedidos en efectivo.', 'es', 'amigable', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'promociones'), 'general', 'cliente', 'envio_gratis', 
   ARRAY['gratis','envío','combos'], 'Revisa la app, hay combos con envío gratis por tiempo limitado.', 'es', 'amigable', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'promociones'), 'general', 'cliente', 'promo_semanales', 
   ARRAY['nuevas','ofertas','semana'], 'En Unite Speed Delivery activamos ofertas nuevas cada semana. ¡No te las pierdas!', 'es', 'amigable', 1),

  -- ✅ AGRADECIMIENTO (5 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'agradecimiento'), 'general', 'cliente', 'gracias_pedido', 
   ARRAY['gracias','pedido'], '¡Gracias por tu pedido!', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'agradecimiento'), 'general', 'cliente', 'gracias_confianza', 
   ARRAY['gracias','confiar'], '¡Gracias por confiar en nosotros! 😊', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'agradecimiento'), 'general', 'cliente', 'gracias_compra', 
   ARRAY['gracias','compra'], '¡Tu compra nos alegra el día! ❤️', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'agradecimiento'), 'general', 'cliente', 'gracias_marca', 
   ARRAY['gracias','unite'], '¡Gracias por usar Unite Speed Delivery! Siempre para servirte 🙌', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'agradecimiento'), 'general', 'cliente', 'gracias_satisfaccion', 
   ARRAY['gracias','elegir'], '¡Gracias por elegirnos! Tu satisfacción es nuestra prioridad.', 'es', 'amigable', 1),

  -- ✅ ERROR EN LA APP (5 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'error_app'), 'general', 'cliente', 'error_generico', 
   ARRAY['error','fallo','problema'], 'Parece que algo falló, intenta nuevamente por favor.', 'es', 'amigable', 3),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'error_app'), 'general', 'cliente', 'reiniciar_app', 
   ARRAY['no funciona','traba','cierra'], 'Si el problema continúa, cierra y vuelve a abrir la app.', 'es', 'amigable', 3),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'error_app'), 'general', 'cliente', 'error_inesperado', 
   ARRAY['error','inesperado'], 'Tuvimos un error inesperado. Estamos trabajando para solucionarlo.', 'es', 'amigable', 3),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'error_app'), 'general', 'cliente', 'error_temporal', 
   ARRAY['fallo','temporal'], 'Lo sentimos, hubo un fallo temporal. Prueba otra vez en unos segundos.', 'es', 'amigable', 3),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'error_app'), 'general', 'cliente', 'error_registro', 
   ARRAY['error','registro'], 'En Unite Speed Delivery registramos los errores automáticamente para corregirlos ✅', 'es', 'amigable', 2),

  -- ✅ DESPEDIDA (5 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'despedida'), 'general', 'cliente', 'hasta_luego', 
   ARRAY['adiós','chao','hasta luego'], '¡Hasta luego! Aquí estaré si necesitas algo más.', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'despedida'), 'general', 'cliente', 'buen_dia', 
   ARRAY['gracias','bye'], '¡Gracias por escribir! Que tengas un excelente día.', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'despedida'), 'general', 'cliente', 'nos_vemos', 
   ARRAY['nos vemos','chau'], '¡Nos vemos pronto!', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'despedida'), 'general', 'cliente', 'despedida_marca', 
   ARRAY['adiós','unite'], '¡Hasta la próxima, gracias por usar Unite Speed Delivery!', 'es', 'amigable', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'despedida'), 'general', 'cliente', 'aqui_estare', 
   ARRAY['gracias','ayuda'], '¡Gracias! Aquí estaré si vuelves a necesitar ayuda 😊', 'es', 'amigable', 1),

  -- ✅ FUERA DE TEMA / FALLBACK (5 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'fuera_tema'), 'general', 'cliente', 'no_entiendo', 
   ARRAY['otra cosa','diferente'], 'No estoy seguro de entender eso, ¿puedes decirlo de otra manera?', 'es', 'amigable', 3),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'fuera_tema'), 'general', 'cliente', 'sin_info', 
   NULL, 'No tengo información sobre eso, pero puedo ayudarte con tu pedido.', 'es', 'amigable', 3),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'fuera_tema'), 'general', 'cliente', 'ayuda_pedidos', 
   NULL, 'Estoy aquí para ayudarte con entregas, pagos o pedidos. ¿Quieres consultar algo de eso?', 'es', 'amigable', 3),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'fuera_tema'), 'general', 'cliente', 'sin_respuesta', 
   NULL, 'No tengo respuesta para eso, pero puedo ayudarte con tu compra o entrega.', 'es', 'amigable', 3),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'fuera_tema'), 'general', 'cliente', 'uso_ia', 
   NULL, 'Si tu pregunta no es sobre pedidos, Unite Speed Delivery puede usar IA para responder algo más específico 🔍', 'es', 'amigable', 2),

  -- ✅ SOPORTE: SALUDO (3 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_saludo'), 'general', 'cliente', 'saludo_soporte', 
   ARRAY['soporte','agente','ayuda'], 'Hola, soy soporte. ¿En qué puedo ayudarte hoy?', 'es', 'profesional', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_saludo'), 'general', 'cliente', 'revisando_caso', 
   ARRAY['problema','inconveniente'], 'Gracias por escribirnos. Estoy revisando tu caso.', 'es', 'profesional', 1),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_saludo'), 'general', 'cliente', 'asistencia', 
   ARRAY['asistencia','queja'], 'Soy parte del equipo de asistencia de Unite Speed Delivery. ¿Qué inconveniente tienes?', 'es', 'profesional', 1),

  -- ✅ SOPORTE: RETRASO (4 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_retraso'), 'general', 'cliente', 'retraso_verificar', 
   ARRAY['retraso','demora','tarda'], 'Lamento el retraso, estoy contactando al repartidor asignado.', 'es', 'profesional', 3),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_retraso'), 'general', 'cliente', 'retraso_trafico', 
   ARRAY['tráfico','clima'], 'El retraso puede deberse al tráfico o clima. Estoy verificando la ubicación del repartidor.', 'es', 'profesional', 3),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_retraso'), 'general', 'cliente', 'retraso_paciencia', 
   ARRAY['no llega','cuánto falta'], 'Estoy revisando por qué el pedido aún no llega. Gracias por la paciencia.', 'es', 'profesional', 3),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_retraso'), 'general', 'cliente', 'compensacion', 
   ARRAY['compensar','descuento'], 'Si el pedido supera el tiempo estimado, podemos compensarte según el caso.', 'es', 'profesional', 3),

  -- ✅ SOPORTE: PRODUCTO FALTANTE (3 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_faltante'), 'general', 'cliente', 'falta_producto', 
   ARRAY['falta','faltó','incompleto'], 'Lamento que falte un producto en tu pedido. Puedo registrarlo como incidencia.', 'es', 'profesional', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_faltante'), 'general', 'cliente', 'reportar_restaurante', 
   ARRAY['reportar','reclamo'], 'Voy a reportar al restaurante que faltó parte del pedido.', 'es', 'profesional', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_faltante'), 'general', 'cliente', 'reembolso_parcial', 
   ARRAY['reembolso','devolver'], 'Podemos gestionar un reembolso parcial por el producto faltante.', 'es', 'profesional', 2),

  -- ✅ SOPORTE: REEMBOLSO (4 respuestas)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_reembolso'), 'general', 'cliente', 'iniciar_reembolso', 
   ARRAY['reembolso','devolver','dinero'], 'Puedo iniciar el proceso de reembolso si el pedido tiene un error confirmado.', 'es', 'profesional', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_reembolso'), 'general', 'cliente', 'confirmar_motivo', 
   ARRAY['motivo','por qué'], 'Para avanzar con el reembolso, necesito que confirmes el motivo.', 'es', 'profesional', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_reembolso'), 'general', 'cliente', 'tiempo_reembolso', 
   ARRAY['cuánto','días','horas'], 'El reembolso puede tardar entre 24 y 72 horas dependiendo del método de pago.', 'es', 'profesional', 2),
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'soporte_reembolso'), 'general', 'cliente', 'reembolso_total', 
   ARRAY['total','parcial'], 'Unite Speed Delivery puede emitir reembolsos totales o parciales según el caso.', 'es', 'profesional', 2),

  -- ✅ DELIVERY: Actualizar estado (reutilizado del original)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'estado_pedido'), 'general', 'delivery', 'actualizar_estado',
   ARRAY['actualizar','estado','pedido','marcar'], 'Recuerda marcar el pedido como "en camino" cuando lo recojas.', 'es', 'profesional', 3);

-- ==============================
-- Nuevas respuestas estilo IA
-- ==============================
INSERT INTO ia_respuestas_automaticas (id_categoria_ia, canal, scope_destino, intent, keywords, respuesta, idioma, tono, prioridad)
VALUES
  -- Saludo con voz de asistente IA
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'bienvenida'), 'general', 'cliente', 'saludo_ia',
   ARRAY['hola','asistente','ayuda','ia','inteligencia'], 'Hola, soy tu asistente virtual de Unite Speed Delivery. Puedo ayudarte a seguir tu pedido, recomendarte opciones según tus gustos o resolver un problema rápidamente. ¿Qué quieres que haga primero?', 'es', 'conversacional-ia', 1),

  -- Recomendación personalizada (simulada IA)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'promociones'), 'general', 'cliente', 'recomienda_personalizada',
   ARRAY['recomienda','sugerir','sugerencia','qué pido'], 'Puedo sugerirte platos populares cerca de ti basándome en pedidos similares. ¿Quieres que te muestre 3 opciones con buena calificación?', 'es', 'conversacional-ia', 2),

  -- Fallback con estilo IA que ofrece acción alternativa
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'fuera_tema'), 'general', 'cliente', 'fallback_ia_ofrecer_ia',
   NULL, 'No estoy seguro de entender eso, pero puedo usar mi asistente inteligente para buscar más información o derivar tu caso a soporte. ¿Cuál prefieres?', 'es', 'conversacional-ia', 3),

  -- Explicación amable y de apariencia inteligente sobre tiempos (estimación genérica)
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'tiempo_entrega'), 'general', 'cliente', 'estimacion_ia',
   ARRAY['estimación','tiempo','llegar','cuando'], 'Según condiciones actuales, estimo que tu pedido llegará en aproximadamente 20-35 minutos. Si quieres puedo vigilar la ruta y avisarte cuando esté a 5 minutos.', 'es', 'conversacional-ia', 2),

  -- Sugiere pasos cuando hay error en pago con tono guía IA
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'pago'), 'general', 'cliente', 'guia_pago_ia',
   ARRAY['pago','error','tarjeta','rechazado'], 'Veo que hubo un problema con el pago. Te guío paso a paso: primero revisa los datos de la tarjeta, luego prueba otro método o intenta reiniciar la app. ¿Quieres que te envíe las instrucciones completas?', 'es', 'conversacional-ia', 2),

  -- Agradecimiento más 'humano-IA'
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'agradecimiento'), 'general', 'cliente', 'agradecimiento_ia',
   ARRAY['gracias','gracias por'], 'Me alegra haber ayudado. Si quieres, puedo recordar tus preferencias para la próxima vez. ¿Deseas que lo haga?', 'es', 'conversacional-ia', 1),

  -- Mensaje que ofrece encolar la consulta cuando hay saturación
  ((SELECT id_categoria_ia FROM ia_categorias_respuesta WHERE nombre = 'fuera_tema'), 'general', 'cliente', 'encolar_ia',
   NULL, 'En este momento estoy recibiendo muchas consultas. Puedo encolar tu pedido y avisarte cuando haya respuesta detallada. ¿Te interesa que lo haga?', 'es', 'conversacional-ia', 3);


-- Usuarios de soporte dedicados
INSERT INTO soporte_usuarios (nombre, correo, contrasena_hash, activo)
VALUES
  ('Sofía Soporte', 'sofia.soporte@example.com', crypt('Soporte123!', gen_salt('bf', 10)), TRUE),
  ('Miguel Soporte', 'miguel.soporte@example.com', crypt('Soporte123!', gen_salt('bf', 10)), TRUE);

-- Respuestas predefinidas para soporte humano
INSERT INTO soporte_respuestas_predef (categoria, pregunta, respuesta, solo_cliente, solo_delivery, prioridad)
VALUES
  ('pagos', '¿Dónde consulto mi comprobante?', 'Puedes revisar tus comprobantes desde la sección Historial > Pedidos > Ver comprobante.', FALSE, FALSE, 10),
  ('delivery', 'No encuentro la dirección del cliente', 'Comunícate con el cliente desde el chat y verifica la referencia adicional en la ficha del pedido.', FALSE, TRUE, 15),
  ('cuenta', 'Quiero cambiar mi correo registrado', 'Por seguridad, nuestro equipo de soporte debe ayudarte. Envíanos el nuevo correo y lo actualizaremos.', TRUE, FALSE, 20);

-- Conversaciones de chat ejemplo entre cliente y delivery
WITH conv AS (
  INSERT INTO chat_conversaciones (id_cliente, id_delivery, canal, es_chatbot, activa)
  VALUES (
    (SELECT id_usuario FROM usuarios WHERE correo = 'carlos.cliente@example.com'),
    (SELECT id_usuario FROM usuarios WHERE correo = 'pablo.delivery@example.com'),
    'app', FALSE, TRUE
  ) RETURNING id_conversacion
)
INSERT INTO chat_mensajes (id_conversacion, id_remitente, id_destinatario, mensaje)
SELECT id_conversacion,
       (SELECT id_usuario FROM usuarios WHERE correo = 'carlos.cliente@example.com'),
       (SELECT id_usuario FROM usuarios WHERE correo = 'pablo.delivery@example.com'),
       'Hola Pablo, ¿cuánto falta para que llegue mi pedido?'
FROM conv;

WITH conv AS (
  SELECT id_conversacion FROM chat_conversaciones
  ORDER BY id_conversacion DESC LIMIT 1
)
INSERT INTO chat_mensajes (id_conversacion, id_remitente, id_destinatario, mensaje)
SELECT id_conversacion,
       (SELECT id_usuario FROM usuarios WHERE correo = 'pablo.delivery@example.com'),
       (SELECT id_usuario FROM usuarios WHERE correo = 'carlos.cliente@example.com'),
       'Hola Carlos, ya estoy a 5 minutos de tu casa.'
FROM conv;

-- Conversación cliente <-> chatbot
WITH bot_conv AS (
  INSERT INTO chat_conversaciones (id_cliente, canal, es_chatbot, activa)
  VALUES ((SELECT id_usuario FROM usuarios WHERE correo = 'diana.cliente@example.com'), 'bot', TRUE, TRUE)
  RETURNING id_conversacion
)
INSERT INTO chat_mensajes (id_conversacion, id_remitente, mensaje, tipo)
SELECT id_conversacion,
       (SELECT id_usuario FROM usuarios WHERE correo = 'diana.cliente@example.com'),
       'Bot, ¿qué métodos de pago aceptan?',
       'texto'
FROM bot_conv;

WITH bot_conv AS (
  SELECT id_conversacion FROM chat_conversaciones WHERE es_chatbot = TRUE ORDER BY id_conversacion DESC LIMIT 1
)
INSERT INTO chat_mensajes (id_conversacion, id_remitente, mensaje, tipo)
SELECT id_conversacion,
       NULL,
       'Aceptamos tarjetas, Yape y efectivo. ¿Te ayudo a elegir uno?',
       'bot'
FROM bot_conv;

-- Tickets de soporte con mensajes de ejemplo
WITH sop AS (
  INSERT INTO soporte_conversaciones (id_usuario, estado, canal, prioridad, permite_ia)
  VALUES ((SELECT id_usuario FROM usuarios WHERE correo = 'carlos.cliente@example.com'), 'asignada', 'app', 2, TRUE)
  RETURNING id_soporte_conv
)
INSERT INTO soporte_mensajes (id_soporte_conv, id_remitente, es_agente, mensaje)
SELECT id_soporte_conv,
       (SELECT id_usuario FROM usuarios WHERE correo = 'carlos.cliente@example.com'),
       FALSE,
       'Hola soporte, mi comprobante no se descarga.'
FROM sop;

WITH sop AS (
  SELECT id_soporte_conv FROM soporte_conversaciones ORDER BY id_soporte_conv DESC LIMIT 1
)
INSERT INTO soporte_mensajes (id_soporte_conv, id_remitente, es_agente, mensaje)
SELECT id_soporte_conv,
       NULL,
       TRUE,
       'Hola Carlos, revisa la sección Historial > Pedidos > Ver comprobante. Avísame si necesitas otra copia.'
FROM sop;

-- =====================================================
-- Datos de ejemplo para tracking eventos (Esmeraldas, Ecuador)
-- Se crea un pedido de ejemplo y se usan sus eventos de tracking
WITH nuevo_pedido AS (
  INSERT INTO pedidos (
    id_cliente,
    id_delivery,
    id_ubicacion,
    direccion_entrega,
    metodo_pago,
    estado,
    total
  ) VALUES (
    (SELECT id_usuario FROM usuarios WHERE correo = 'carlos.cliente@example.com'),
    (SELECT id_usuario FROM usuarios WHERE correo = 'pablo.delivery@example.com'),
    (SELECT id_ubicacion FROM ubicaciones WHERE descripcion = 'Casa - Carlos' LIMIT 1),
    'Av. Lima 123',
    'efectivo',
    'en camino',
    42.00
  )
  RETURNING id_pedido
)
INSERT INTO tracking_eventos (id_pedido, orden, latitud, longitud, descripcion)
SELECT id_pedido, v.orden, v.latitud, v.longitud, v.descripcion
FROM nuevo_pedido np
CROSS JOIN (
  VALUES
    (1, 0.9593, -79.6527, 'Pedido confirmado - Restaurante'),
    (2, 0.9580, -79.6520, 'Preparando pedido'),
    (3, 0.9570, -79.6510, 'Pedido listo - Repartidor asignado'),
    (4, 0.9560, -79.6500, 'En camino al cliente'),
    (5, 0.9550, -79.6490, 'Cerca del destino'),
    (6, 0.9540, -79.6480, 'Pedido entregado')
) AS v(orden, latitud, longitud, descripcion);

-- Opiniones de ejemplo para landing page
INSERT INTO opiniones (nombre, email, rating, comentario, plataforma)
VALUES
  ('María González', 'maria@example.com', 5, 'Excelente servicio, muy rápido y la comida llegó caliente', 'web'),
  ('Carlos Pérez', 'carlos@example.com', 4, 'Buena experiencia, solo tardó un poco más de lo esperado', 'web'),
  ('Ana López', 'ana@example.com', 5, 'Unite Speed es increíble, siempre puntuales', 'web'),
  ('José Martín', 'jose@example.com', 3, 'Regular, la comida estaba fría pero el repartidor fue amable', 'web'),
  ('Laura Silva', 'laura@example.com', 5, 'Perfecto! La mejor app de delivery que he usado', 'web');

-- Chat predefinido para landing page
INSERT INTO chat_web_predefinido (pregunta, respuesta, categoria, orden)
VALUES
  ('¿Cómo funciona Unite Speed?', 'Unite Speed es una plataforma de delivery que conecta restaurantes, repartidores y clientes. Puedes hacer pedidos desde nuestra app y seguir tu entrega en tiempo real.', 'general', 1),
  ('¿Cuáles son los métodos de pago?', 'Aceptamos tarjetas de crédito/débito, transferencias bancarias y pago en efectivo al momento de la entrega.', 'pagos', 2),
  ('¿Cuánto tiempo tarda la entrega?', 'El tiempo promedio de entrega es de 20-30 minutos, dependiendo de la distancia y disponibilidad del restaurante.', 'tiempos', 3),
  ('¿Hay costo de envío?', 'El costo de envío varía según la distancia. Muchos restaurantes ofrecen envío gratis en pedidos superiores a cierto monto.', 'costos', 4),
  ('¿Puedo cancelar mi pedido?', 'Sí, puedes cancelar tu pedido antes de que el repartidor lo recoja del restaurante. Después de eso, contacta a soporte.', 'cancelaciones', 5),
  ('¿Cómo me registro?', 'Descarga la app Unite Speed desde Google Play o App Store, crea tu cuenta con email y teléfono, y ¡listo para pedir!', 'registro', 6);

-- =====================================================
-- Índices recomendados para rendimiento
-- =====================================================

-- Usuarios
CREATE INDEX IF NOT EXISTS idx_usuarios_lower_correo ON usuarios (LOWER(correo));

-- Productos y categorías
CREATE INDEX IF NOT EXISTS idx_productos_negocio ON productos (id_negocio);
CREATE INDEX IF NOT EXISTS idx_productos_categoria ON productos (id_categoria);
CREATE INDEX IF NOT EXISTS idx_categorias_negocio ON categorias (id_negocio);

-- Ubicaciones
CREATE INDEX IF NOT EXISTS idx_ubicaciones_usuario ON ubicaciones (id_usuario);

-- Pedidos y detalle
CREATE INDEX IF NOT EXISTS idx_pedidos_cliente ON pedidos (id_cliente);
CREATE INDEX IF NOT EXISTS idx_pedidos_delivery ON pedidos (id_delivery);
CREATE INDEX IF NOT EXISTS idx_pedidos_ubicacion ON pedidos (id_ubicacion);
-- Estados de pedido (consultas por estado y dashboards)
CREATE INDEX IF NOT EXISTS idx_pedidos_estado ON pedidos (estado);
CREATE INDEX IF NOT EXISTS idx_pedidos_estado_created ON pedidos (estado, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_detalle_pedido ON detalle_pedidos (id_pedido);
CREATE INDEX IF NOT EXISTS idx_detalle_producto ON detalle_pedidos (id_producto);
CREATE INDEX IF NOT EXISTS idx_tracking_pedido ON tracking_ruta (id_pedido, registrado_en DESC);

-- Chat
CREATE INDEX IF NOT EXISTS idx_chatconv_cliente ON chat_conversaciones (id_cliente);
CREATE INDEX IF NOT EXISTS idx_chatconv_delivery ON chat_conversaciones (id_delivery);
CREATE INDEX IF NOT EXISTS idx_chatconv_pedido ON chat_conversaciones (id_pedido);
CREATE INDEX IF NOT EXISTS idx_chatmsg_conv_created ON chat_mensajes (id_conversacion, created_at);

-- Soporte
CREATE INDEX IF NOT EXISTS idx_soporte_usuario ON soporte_conversaciones (id_usuario);
CREATE INDEX IF NOT EXISTS idx_sopmsg_conv ON soporte_mensajes (id_soporte_conv, created_at);

-- Nuevas tablas
CREATE INDEX IF NOT EXISTS idx_opiniones_rating ON opiniones (rating);
CREATE INDEX IF NOT EXISTS idx_opiniones_estado ON opiniones (estado);
CREATE INDEX IF NOT EXISTS idx_tracking_eventos_pedido ON tracking_eventos (id_pedido, orden);
CREATE INDEX IF NOT EXISTS idx_password_resets_user_active ON password_resets(user_id) WHERE used_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_chat_web_categoria ON chat_web_predefinido (categoria, orden);

-- =====================================================
-- CEO y créditos del sistema
-- =====================================================
-- Sistema desarrollado bajo la dirección del CEO Michael Ortiz
-- Unite Speed Delivery - Delivery rápido, seguro y con IA
-- Versión: 1.0 - Producción
-- Fecha: Noviembre 2025

COMMIT;
