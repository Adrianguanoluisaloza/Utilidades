-- ============================================================
-- RESPUESTAS PREDEFINIDAS PARA SOPORTE (SIN IA)
-- ============================================================

INSERT INTO soporte_respuestas_predef (categoria, pregunta, respuesta, solo_cliente, solo_delivery, prioridad)
VALUES
  -- PEDIDOS Y TRACKING
  ('pedidos', '¿Dónde está mi pedido?', 'Puedes revisar el estado de tu pedido en la sección "Mis Pedidos" de la app. Allí verás el tracking en tiempo real.', TRUE, FALSE, 5),
  ('pedidos', 'No llega mi pedido', 'Lo sentimos. Verifica el tracking en "Mis Pedidos". Si hay demora, te recomendamos contactar al delivery asignado desde el chat.', TRUE, FALSE, 8),
  ('pedidos', 'Cuánto demora', 'El tiempo de entrega varía según la distancia. Puedes ver el tiempo estimado en el tracking de tu pedido.', TRUE, FALSE, 10),
  ('pedidos', 'Cancelar pedido', 'Solo puedes cancelar un pedido si está en estado "pendiente". Ve a "Mis Pedidos" y presiona el botón cancelar.', TRUE, FALSE, 12),
  
  -- PAGOS Y COMPROBANTES
  ('pagos', '¿Dónde está mi comprobante?', 'Puedes revisar tus comprobantes desde la sección Historial > Pedidos > Ver comprobante.', FALSE, FALSE, 10),
  ('pagos', 'No me llegó el comprobante', 'Los comprobantes están disponibles en tu historial de pedidos. También puedes solicitarlo al correo del soporte.', TRUE, FALSE, 15),
  ('pagos', 'Métodos de pago', 'Aceptamos efectivo contra entrega, tarjetas de crédito/débito y transferencias bancarias.', TRUE, FALSE, 18),
  ('pagos', 'Cambiar método de pago', 'Puedes cambiar el método de pago antes de confirmar tu pedido. Una vez confirmado, no es posible modificarlo.', TRUE, FALSE, 20),
  
  -- CUENTA Y PERFIL
  ('cuenta', 'Cambiar mi correo', 'Por seguridad, nuestro equipo de soporte debe ayudarte. Envíanos tu nuevo correo y lo actualizaremos.', TRUE, FALSE, 20),
  ('cuenta', 'Olvidé mi contraseña', 'Usa la opción "Recuperar contraseña" en la pantalla de inicio de sesión. Te enviaremos un código a tu correo.', FALSE, FALSE, 5),
  ('cuenta', 'Cambiar mi contraseña', 'Ve a Perfil > Configuración > Cambiar contraseña. Necesitarás tu contraseña actual.', FALSE, FALSE, 8),
  ('cuenta', 'Actualizar mis datos', 'Puedes actualizar tu nombre, teléfono y direcciones desde tu perfil en la app.', FALSE, FALSE, 12),
  
  -- DELIVERY (Solo para repartidores)
  ('delivery', 'No encuentro la dirección', 'Comunícate con el cliente desde el chat y verifica la referencia adicional en la ficha del pedido.', FALSE, TRUE, 15),
  ('delivery', 'Cliente no responde', 'Intenta llamar al número registrado. Si no hay respuesta en 5 minutos, contacta a soporte para marcar el pedido.', FALSE, TRUE, 18),
  ('delivery', 'Problema con la app', 'Si la app presenta fallas, ciérrala completamente y vuelve a abrirla. Si persiste, reinstálala.', FALSE, TRUE, 20),
  
  -- PRODUCTOS
  ('productos', 'Producto agotado', 'Si un producto aparece como "agotado", lamentablemente no está disponible en este momento. Te sugerimos revisar productos similares.', TRUE, FALSE, 15),
  ('productos', 'Precios incorrectos', 'Los precios son actualizados por los negocios. Si encuentras un error, repórtalo para que lo verifiquemos.', TRUE, FALSE, 18),
  ('productos', 'Imágenes no cargan', 'Verifica tu conexión a internet. Si el problema persiste, cierra y vuelve a abrir la app.', FALSE, FALSE, 20),
  
  -- DIRECCIONES
  ('direcciones', 'Agregar nueva dirección', 'Ve a Perfil > Mis Direcciones > Agregar Nueva. Puedes usar el mapa o escribir la dirección manualmente.', TRUE, FALSE, 10),
  ('direcciones', 'No encuentra mi dirección', 'Usa el mapa para señalar tu ubicación exacta. Agrega una referencia clara para el delivery.', TRUE, FALSE, 12),
  ('direcciones', 'Eliminar dirección', 'Ve a Perfil > Mis Direcciones, selecciona la dirección y presiona el ícono de eliminar.', TRUE, FALSE, 15),
  
  -- NEGOCIOS
  ('negocios', 'Registrar mi negocio', 'Ve a Perfil > Convertirse en Negocio. Completa el formulario con tu RUC, nombre comercial y datos de contacto.', TRUE, FALSE, 10),
  ('negocios', 'Agregar productos', 'Desde el panel de negocio, ve a Mis Productos > Agregar Producto. Completa la información y sube una imagen.', FALSE, FALSE, 12),
  ('negocios', 'Ver mis ventas', 'En el panel de negocio encontrarás estadísticas de tus ventas, productos más vendidos y ganancias.', FALSE, FALSE, 15),
  
  -- GENERAL
  ('general', 'Hola', '¡Hola! 👋 Soy el asistente de soporte. ¿En qué puedo ayudarte hoy?', FALSE, FALSE, 1),
  ('general', 'Ayuda', 'Estoy aquí para ayudarte. Puedes preguntarme sobre pedidos, pagos, tu cuenta, direcciones o cualquier problema técnico.', FALSE, FALSE, 2),
  ('general', 'Gracias', '¡De nada! 😊 Si necesitas más ayuda, no dudes en escribirme.', FALSE, FALSE, 3),
  ('general', 'Horario de atención', 'Estoy disponible 24/7 para respuestas automáticas. Para atención personalizada, nuestro equipo está disponible de lunes a sábado de 8:00 AM a 10:00 PM.', FALSE, FALSE, 8)

ON CONFLICT DO NOTHING;

-- Verificar respuestas insertadas
SELECT categoria, COUNT(*) as total
FROM soporte_respuestas_predef
GROUP BY categoria
ORDER BY categoria;
