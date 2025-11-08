-- ============================================================================
-- DATOS COMPLETOS PARA UNITE SPEED DELIVERY
-- ============================================================================
-- Este script agrega todos los datos físicos necesarios para que la app funcione al 100%
-- Ejecutar después de SOPORTE_SETUP.sql
-- ============================================================================

-- ============================================================================
-- 1. NEGOCIOS (para asociar productos)
-- ============================================================================
INSERT INTO negocios (id_usuario, nombre_comercial, email, direccion, telefono, activo) VALUES
(3, 'Pizza Palace', 'pizza@unitespeed.com', 'Av. Principal 123, Esmeraldas', '0999111111', true),
(3, 'Sushi Express', 'sushi@unitespeed.com', 'Calle Comercio 456, Esmeraldas', '0999222222', true),
(3, 'Café Andino', 'cafe@unitespeed.com', 'Plaza Central 789, Esmeraldas', '0999333333', true),
(3, 'Burger Station', 'burger@unitespeed.com', 'Zona Rosa 321, Esmeraldas', '0999444444', true)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 2. CATEGORÍAS (para organizar productos)
-- ============================================================================
INSERT INTO categorias (id_negocio, nombre, descripcion) VALUES
(1, 'Pizzas', 'Pizzas artesanales con ingredientes frescos'),
(2, 'Makis', 'Sushi y makis preparados al momento'),
(3, 'Bebidas', 'Bebidas calientes y frías'),
(4, 'Hamburguesas', 'Hamburguesas gourmet con carne premium')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 3. ACTUALIZAR PRODUCTOS EXISTENTES (asociar con negocios y categorías)
-- ============================================================================
UPDATE productos SET 
    id_negocio = 1, 
    id_categoria = 1
WHERE nombre = 'Pizza Margarita';

UPDATE productos SET 
    id_negocio = 2, 
    id_categoria = 2
WHERE nombre = 'Maki Acevichado';

UPDATE productos SET 
    id_negocio = 3, 
    id_categoria = 3
WHERE nombre = 'Latte Andino';

UPDATE productos SET 
    id_negocio = 4, 
    id_categoria = 4
WHERE nombre = 'Burger Station Clásica';

-- ============================================================================
-- 4. PRODUCTOS ADICIONALES (más variedad)
-- ============================================================================
INSERT INTO productos (id_negocio, id_categoria, nombre, descripcion, precio, disponible, imagen_url) VALUES
-- Pizza Palace
(1, 1, 'Pizza Pepperoni', 'Pepperoni italiano con queso mozzarella', 28.5, true, 'https://example.com/pizza-pepperoni.png'),
(1, 1, 'Pizza Hawaiana', 'Jamón, piña y queso mozzarella', 30.0, true, 'https://example.com/pizza-hawaiana.png'),
(1, 1, 'Pizza Vegetariana', 'Vegetales frescos y queso', 26.0, true, 'https://example.com/pizza-veggie.png'),

-- Sushi Express  
(2, 2, 'Maki California', 'Cangrejo, palta y pepino', 24.5, true, 'https://example.com/maki-california.png'),
(2, 2, 'Maki Spicy Tuna', 'Atún picante con salsa especial', 32.0, true, 'https://example.com/maki-spicy.png'),
(2, 2, 'Sashimi Salmón', 'Salmón fresco en láminas', 35.0, true, 'https://example.com/sashimi-salmon.png'),

-- Café Andino
(3, 3, 'Cappuccino Tradicional', 'Espresso con leche espumada', 12.0, true, 'https://example.com/cappuccino.png'),
(3, 3, 'Té Chai Latte', 'Té especiado con leche', 10.5, true, 'https://example.com/chai-latte.png'),
(3, 3, 'Chocolate Caliente', 'Chocolate artesanal con marshmallows', 8.5, true, 'https://example.com/chocolate.png'),

-- Burger Station
(4, 4, 'Burger BBQ', 'Carne a la parrilla con salsa BBQ', 22.0, true, 'https://example.com/burger-bbq.png'),
(4, 4, 'Burger Vegana', 'Hamburguesa 100% vegetal', 20.0, true, 'https://example.com/burger-vegan.png'),
(4, 4, 'Burger Doble', 'Doble carne con queso cheddar', 28.0, true, 'https://example.com/burger-double.png')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 5. USUARIOS ADICIONALES (más variedad para testing)
-- ============================================================================
INSERT INTO usuarios (nombre, correo, contrasena, telefono, id_rol, activo) VALUES
-- Clientes
('María González', 'maria@test.com', 'Cliente123!', '0987654321', 1, true),
('Juan Pérez', 'juan@test.com', 'Cliente123!', '0976543210', 1, true),
('Ana López', 'ana.lopez@test.com', 'Cliente123!', '0965432109', 1, true),

-- Deliveries
('Carlos Repartidor', 'carlos.delivery@test.com', 'Delivery123!', '0954321098', 2, true),
('Luis Motorizado', 'luis.delivery@test.com', 'Delivery123!', '0943210987', 2, true),
('Pedro Express', 'pedro.delivery@test.com', 'Delivery123!', '0932109876', 2, true),

-- Negocios
('Restaurant El Buen Sabor', 'sabor@test.com', 'Negocio123!', '0921098765', 3, true),
('Comida Rápida Flash', 'flash@test.com', 'Negocio123!', '0910987654', 3, true),

-- Soporte
('Agente Soporte 1', 'soporte1@unitespeed.com', 'Soporte123!', '0909876543', 5, true),
('Agente Soporte 2', 'soporte2@unitespeed.com', 'Soporte123!', '0898765432', 5, true)
ON CONFLICT (correo) DO NOTHING;

-- ============================================================================
-- 6. UBICACIONES ADICIONALES (para testing)
-- ============================================================================
INSERT INTO ubicaciones (id_usuario, latitud, longitud, direccion, descripcion, activa) VALUES
-- Ubicaciones para clientes
(12, 0.985123, -79.658456, 'Av. Libertad 456, Esmeraldas', 'Casa de María', true),
(13, 0.982789, -79.661234, 'Calle 10 de Agosto 789, Esmeraldas', 'Casa de Juan', true),
(14, 0.990456, -79.655678, 'Barrio Las Flores 123, Esmeraldas', 'Casa de Ana', true),

-- Ubicaciones para deliveries (puntos de partida)
(15, 0.970362, -79.652557, 'Centro de Distribución Norte', 'Base Carlos', true),
(16, 0.975123, -79.654890, 'Centro de Distribución Sur', 'Base Luis', true),
(17, 0.978456, -79.656123, 'Centro de Distribución Este', 'Base Pedro', true),

-- Ubicaciones de negocios
(18, 0.972456, -79.653789, 'Local Comercial Plaza Norte', 'El Buen Sabor', true),
(19, 0.976789, -79.657012, 'Food Court Mall Central', 'Comida Flash', true)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 7. PEDIDOS DE EJEMPLO (para demostrar funcionalidad)
-- ============================================================================
INSERT INTO pedidos (id_cliente, id_delivery, id_ubicacion, direccion_entrega, metodo_pago, estado, total) VALUES
(12, 15, 12, 'Av. Libertad 456, Esmeraldas', 'efectivo', 'pendiente', 45.50),
(13, NULL, 13, 'Calle 10 de Agosto 789, Esmeraldas', 'tarjeta', 'pendiente', 32.00),
(14, 16, 14, 'Barrio Las Flores 123, Esmeraldas', 'efectivo', 'en_camino', 28.50)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 8. DETALLES DE PEDIDOS
-- ============================================================================
INSERT INTO detalle_pedidos (id_pedido, id_producto, cantidad, precio_unitario, subtotal) VALUES
-- Pedido 2 (María)
(2, 1, 1, 32.50, 32.50),  -- Pizza Margarita
(2, 9, 1, 12.00, 12.00),  -- Cappuccino
-- Pedido 3 (Juan)  
(3, 5, 1, 28.50, 28.50),  -- Pizza Pepperoni
-- Pedido 4 (Ana)
(4, 3, 2, 14.00, 28.00)   -- Latte Andino x2
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 9. RECOMENDACIONES DE PRODUCTOS
-- ============================================================================
INSERT INTO recomendaciones (id_producto, id_usuario, puntuacion, comentario) VALUES
(1, 12, 5, 'Excelente pizza, muy recomendada'),
(1, 13, 4, 'Buena calidad, llegó caliente'),
(2, 12, 5, 'El mejor maki de la ciudad'),
(3, 14, 4, 'Café delicioso, perfecto para la tarde'),
(4, 13, 5, 'Hamburguesa increíble, muy sabrosa'),
(5, 12, 4, 'Pizza pepperoni clásica, muy buena')
ON CONFLICT (id_producto, id_usuario) DO NOTHING;

-- ============================================================================
-- 10. CONVERSACIONES DE CHAT (ejemplos)
-- ============================================================================
INSERT INTO chat_conversaciones (id_cliente, id_delivery, id_pedido, es_bot) VALUES
(12, 15, 2, false),  -- Chat cliente-delivery
(13, NULL, NULL, true),  -- Chat con bot
(14, 16, 4, false)   -- Chat cliente-delivery
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 11. MENSAJES DE CHAT (ejemplos)
-- ============================================================================
INSERT INTO chat_mensajes (id_conversacion, id_remitente, id_destinatario, mensaje) VALUES
-- Conversación 1 (cliente-delivery)
(1, 12, 15, 'Hola, ¿ya saliste con mi pedido?'),
(1, 15, 12, 'Sí, ya estoy en camino. Llego en 10 minutos.'),
(1, 12, 15, 'Perfecto, gracias'),

-- Conversación 2 (cliente-bot)
(2, 13, 1, 'Hola, ¿cuánto demora mi pedido?'),
(2, 1, 13, 'Hola! Tu pedido está siendo preparado. El tiempo estimado es de 25-30 minutos.'),

-- Conversación 3 (cliente-delivery)
(3, 14, 16, '¿Dónde estás?'),
(3, 16, 14, 'Estoy a 2 cuadras de tu casa')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 12. TRACKING ADICIONAL (más rutas de ejemplo)
-- ============================================================================
INSERT INTO tracking_eventos (id_pedido, orden, latitud, longitud, descripcion) VALUES
-- Ruta para pedido #2
(2, 1, 0.972456, -79.653789, 'Recogiendo pedido en Pizza Palace'),
(2, 2, 0.975123, -79.655012, 'Saliendo del negocio'),
(2, 3, 0.980456, -79.657234, 'En ruta hacia el cliente'),
(2, 4, 0.985123, -79.658456, 'Llegando al destino'),

-- Ruta para pedido #4  
(4, 1, 0.976789, -79.657012, 'Recogiendo en Café Andino'),
(4, 2, 0.982345, -79.659123, 'En camino'),
(4, 3, 0.988567, -79.660234, 'Cerca del destino'),
(4, 4, 0.990456, -79.655678, 'Entregado')
ON CONFLICT (id_pedido, orden) DO NOTHING;

-- ============================================================================
-- 13. RESPUESTAS AUTOMÁTICAS ADICIONALES
-- ============================================================================
INSERT INTO soporte_respuestas_automaticas (categoria, pregunta, respuesta, keywords, activo) VALUES
('delivery', '¿Cómo ser repartidor?', 
 'Para ser repartidor: 1) Regístrate con rol "delivery", 2) Completa tu perfil con foto y datos de contacto, 3) Espera la aprobación del administrador, 4) Descarga la app de repartidor y comienza a recibir pedidos.', 
 ARRAY['repartidor', 'delivery', 'trabajar', 'empleo'], true),

('productos', '¿Qué productos tienen?', 
 'Tenemos una gran variedad: Pizzas artesanales, Sushi fresco, Bebidas calientes y frías, Hamburguesas gourmet, y mucho más. Revisa nuestro catálogo en la app.', 
 ARRAY['productos', 'menu', 'comida', 'catalogo'], true),

('ubicacion', '¿A dónde entregan?', 
 'Entregamos en toda la ciudad de Esmeraldas. Solo necesitas registrar tu dirección en la app y verificaremos si está en nuestra zona de cobertura.', 
 ARRAY['ubicacion', 'direccion', 'entregar', 'zona'], true),

('promociones', '¿Tienen descuentos?', 
 'Sí! Tenemos promociones especiales para nuevos usuarios, descuentos por volumen y ofertas de temporada. Mantente atento a las notificaciones de la app.', 
 ARRAY['descuento', 'promocion', 'oferta', 'barato'], true)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- VERIFICACIÓN DE DATOS
-- ============================================================================
-- Contar registros insertados
SELECT 
    'negocios' as tabla, COUNT(*) as total FROM negocios
UNION ALL SELECT 
    'categorias' as tabla, COUNT(*) as total FROM categorias  
UNION ALL SELECT
    'productos' as tabla, COUNT(*) as total FROM productos
UNION ALL SELECT
    'usuarios' as tabla, COUNT(*) as total FROM usuarios
UNION ALL SELECT
    'ubicaciones' as tabla, COUNT(*) as total FROM ubicaciones
UNION ALL SELECT
    'pedidos' as tabla, COUNT(*) as total FROM pedidos
UNION ALL SELECT
    'detalle_pedidos' as tabla, COUNT(*) as total FROM detalle_pedidos
UNION ALL SELECT
    'recomendaciones' as tabla, COUNT(*) as total FROM recomendaciones
UNION ALL SELECT
    'chat_conversaciones' as tabla, COUNT(*) as total FROM chat_conversaciones
UNION ALL SELECT
    'chat_mensajes' as tabla, COUNT(*) as total FROM chat_mensajes
UNION ALL SELECT
    'tracking_eventos' as tabla, COUNT(*) as total FROM tracking_eventos
ORDER BY tabla;

-- ============================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ============================================================================
SELECT '✅ DATOS COMPLETOS INSERTADOS EXITOSAMENTE' as status;
SELECT '🎯 La app ahora tiene todos los datos necesarios para funcionar al 100%' as mensaje;

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================