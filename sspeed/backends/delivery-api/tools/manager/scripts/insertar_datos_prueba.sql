-- ===============================================
-- SCRIPT DE INSERCIÓN DE DATOS DE PRUEBA
-- Unite Speed Delivery - PostgreSQL
-- Ejecutar solo si faltan datos de prueba
-- ===============================================

-- 1. Insertar roles si no existen
INSERT INTO roles (nombre) VALUES ('cliente')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO roles (nombre) VALUES ('delivery')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO roles (nombre) VALUES ('negocio')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO roles (nombre) VALUES ('admin')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO roles (nombre) VALUES ('soporte')
ON CONFLICT (nombre) DO NOTHING;

-- 2. Insertar usuarios de prueba si no existen
-- NOTA: Las contraseñas deben estar hasheadas con BCrypt en el backend
-- Estos son ejemplos, el backend debe crearlos con /registro

-- 3. Insertar negocio de prueba
INSERT INTO negocios (nombre_comercial, email, telefono, direccion, activo)
VALUES ('Restaurante Test', 'restaurante@test.com', '0999999999', 'Av. Principal #123', TRUE)
ON CONFLICT DO NOTHING;

-- 4. Insertar productos de prueba
INSERT INTO productos (id_negocio, nombre, descripcion, precio, disponible, stock, imagen_url)
VALUES 
(1, 'Hamburguesa Clásica', 'Hamburguesa con carne, lechuga, tomate y queso', 5.50, TRUE, 100, 'https://unitespeed-landing-2025.s3.us-east-2.amazonaws.com/productos/hamburguesa.jpg'),
(1, 'Pizza Margarita', 'Pizza con tomate, mozzarella y albahaca', 8.00, TRUE, 50, 'https://unitespeed-landing-2025.s3.us-east-2.amazonaws.com/productos/pizza.jpg'),
(1, 'Papas Fritas', 'Papas fritas crujientes', 2.50, TRUE, 200, 'https://unitespeed-landing-2025.s3.us-east-2.amazonaws.com/productos/papas.jpg'),
(1, 'Gaseosa 500ml', 'Bebida gaseosa', 1.50, TRUE, 150, 'https://unitespeed-landing-2025.s3.us-east-2.amazonaws.com/productos/gaseosa.jpg'),
(1, 'Ensalada César', 'Ensalada fresca con pollo y aderezo césar', 6.00, TRUE, 30, 'https://unitespeed-landing-2025.s3.us-east-2.amazonaws.com/productos/ensalada.jpg')
ON CONFLICT DO NOTHING;

-- 5. Insertar categorías IA para chatbot
INSERT INTO ia_categorias_respuesta (nombre, descripcion) VALUES
('saludo', 'Saludos y presentaciones'),
('pedido', 'Información sobre pedidos'),
('producto', 'Consultas sobre productos'),
('ubicacion', 'Consultas sobre ubicación y delivery'),
('pago', 'Métodos de pago'),
('problema', 'Reportes de problemas'),
('despedida', 'Despedidas')
ON CONFLICT (nombre) DO NOTHING;

-- 6. Verificar inserciones
SELECT 'Roles insertados:' as mensaje, COUNT(*) as cantidad FROM roles;
SELECT 'Negocios insertados:' as mensaje, COUNT(*) as cantidad FROM negocios WHERE activo = TRUE;
SELECT 'Productos insertados:' as mensaje, COUNT(*) as cantidad FROM productos WHERE disponible = TRUE;
SELECT 'Categorías IA insertadas:' as mensaje, COUNT(*) as cantidad FROM ia_categorias_respuesta;
