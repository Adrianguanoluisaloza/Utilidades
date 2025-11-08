// HOTFIX para ChatBotResponder.generateReply() - Reemplazar método completo

public String generateReply(String rawMessage, List<Map<String, Object>> history, int idUsuario) {
    // Validación de entrada
    if (rawMessage == null) {
        System.err.println("⚠️ ChatBot: rawMessage es null");
        return "Hola, puedo ayudarte con tu pedido. Cuéntame tu consulta.";
    }
    
    if (history == null) {
        System.err.println("⚠️ ChatBot: history es null, usando lista vacía");
        history = new ArrayList<>();
    }
    
    String message = rawMessage.trim().toLowerCase();
    if (message.isEmpty()) {
        return "Hola, puedo ayudarte con tu pedido. Cuéntame tu consulta.";
    }

    try {
        // Intentar buscar respuesta predefinida con manejo de errores
        try {
            Optional<String> predefinedResponse = chatRepository.buscarRespuestaPredefinida(message, "cliente");
            if (predefinedResponse != null && predefinedResponse.isPresent()) {
                return predefinedResponse.get();
            }
        } catch (Exception e) {
            System.err.println("⚠️ Error al buscar respuesta predefinida: " + e.getMessage());
            // Continuar con el flujo normal
        }

        // Detección de intención con validación
        if (isOrderStatusQuery(message)) {
            try {
                // Buscar pedido con manejo de null
                Optional<Pedido> pedidoOpt = null;
                try {
                    pedidoOpt = pedidoRepository.obtenerPedidoMasRecientePorCliente(idUsuario);
                } catch (Exception e) {
                    System.err.println("⚠️ Error al obtener pedido: " + e.getMessage());
                    pedidoOpt = Optional.empty();
                }
                
                if (pedidoOpt == null) {
                    pedidoOpt = Optional.empty();
                }

                // Construir prompt con validación
                String prompt = buildPromptForGemini(message, history, pedidoOpt);
                if (prompt == null || prompt.trim().isEmpty()) {
                    return "Puedes revisar el estado actual en la pantalla 'Mis pedidos'.";
                }

                // Llamar a Gemini con manejo de errores
                try {
                    String geminiResponse = geminiService.generateSmartReply(prompt, history, idUsuario);
                    if (geminiResponse != null && !geminiResponse.trim().isEmpty()) {
                        return geminiResponse;
                    }
                } catch (Exception e) {
                    System.err.println("⚠️ Error al llamar Gemini: " + e.getMessage());
                    // Continuar con fallback
                }

                // Fallback específico para consultas de pedido
                return "Puedes revisar el estado actual en la pantalla 'Mis pedidos'. Te avisaremos cuando cambie a 'en camino'.";

            } catch (Exception e) {
                System.err.println("❌ Error al procesar consulta de pedido: " + e.getMessage());
                return "Puedes revisar el estado actual en la pantalla 'Mis pedidos'.";
            }
        }

        // Fallback a respuestas simples
        return getSimpleFallbackReply(message);
        
    } catch (Exception e) {
        System.err.println("❌ Error general en generateReply: " + e.getMessage());
        e.printStackTrace();
        return "Estoy aquí para ayudarte con tu compra. Puedes preguntarme sobre el estado de tu pedido, tiempos de entrega o cómo cancelar.";
    }
}

// Método auxiliar mejorado
private String buildPromptForGemini(String userMessage, List<Map<String, Object>> history, Optional<Pedido> pedidoOpt) {
    try {
        StringBuilder prompt = new StringBuilder();
        prompt.append("Eres un asistente virtual de un servicio de delivery llamado 'Unite Speed Delivery'. Tu nombre es CIA Bot. Responde de forma breve y amigable.\n");
        
        // Validar history antes de usar
        if (history != null && !history.isEmpty()) {
            prompt.append("Historial de la conversación:\n");
            for (Map<String, Object> msg : history) {
                if (msg != null) {
                    Object esBot = msg.get("es_bot");
                    String role = (esBot != null && (Boolean) esBot) ? "model" : "user";
                    Object mensaje = msg.get("mensaje");
                    if (mensaje != null) {
                        prompt.append(role).append(": ").append(mensaje.toString()).append("\n");
                    }
                }
            }
        }

        prompt.append("Pregunta actual del usuario: '").append(userMessage != null ? userMessage : "").append("'\n");

        // Validar pedidoOpt antes de usar
        if (pedidoOpt != null && pedidoOpt.isPresent()) {
            Pedido pedido = pedidoOpt.get();
            if (pedido != null) {
                prompt.append("Usa la siguiente información para responder: El usuario tiene un pedido activo (ID: ")
                      .append(pedido.getIdPedido())
                      .append(") con estado '").append(pedido.getEstado() != null ? pedido.getEstado() : "desconocido")
                      .append("' que será entregado en '").append(pedido.getDireccionEntrega() != null ? pedido.getDireccionEntrega() : "dirección no especificada").append("'.");
            }
        } else {
            prompt.append("Usa la siguiente información para responder: El usuario no tiene ningún pedido activo en este momento. Invítalo a realizar uno.");
        }

        return prompt.toString();
    } catch (Exception e) {
        System.err.println("❌ Error al construir prompt: " + e.getMessage());
        return "Responde de forma amigable a: " + (userMessage != null ? userMessage : "consulta del usuario");
    }
}