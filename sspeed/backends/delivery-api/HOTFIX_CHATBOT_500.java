// HOTFIX para POST /chat/bot/mensajes - Reemplazar en DeliveryApi.java línea ~1070

app.post("/chat/bot/mensajes", ctx -> {
    System.err.println("🔵 DEBUG: Entrando al handler del chatbot");
    
    try {
        // 1. Validar request body
        var req = ctx.bodyAsClass(Payloads.ChatBotRequest.class);
        if (req == null) {
            throw new ApiException(400, "Request body es obligatorio");
        }
        
        // 2. Validar campos obligatorios
        if (req.idRemitente == null || req.idRemitente <= 0) {
            throw new ApiException(400, "idRemitente es obligatorio y debe ser > 0");
        }
        if (req.mensaje == null || req.mensaje.trim().isEmpty()) {
            throw new ApiException(400, "mensaje es obligatorio y no puede estar vacío");
        }
        
        System.err.println("🔵 DEBUG: Validación OK - idRemitente=" + req.idRemitente + ", mensaje=" + req.mensaje);

        // 3. Obtener o crear conversación con manejo de errores
        long idConversacion;
        try {
            idConversacion = (req.idConversacion != null && req.idConversacion > 0) 
                ? req.idConversacion
                : CHAT_REPOSITORY.ensureBotConversationForUser(req.idRemitente);
            System.err.println("🔵 DEBUG: idConversacion=" + idConversacion);
        } catch (SQLException e) {
            System.err.println("❌ Error SQL al crear conversación: " + e.getMessage());
            throw new ApiException(500, "Error al crear conversación de chat", e);
        }

        // 4. Guardar mensaje del usuario con manejo de errores
        try {
            System.err.println("🔵 DEBUG: Guardando mensaje del usuario...");
            CHAT_REPOSITORY.insertMensaje(idConversacion, req.idRemitente, null, req.mensaje.trim());
            System.err.println("🔵 DEBUG: Mensaje guardado");
        } catch (SQLException e) {
            System.err.println("❌ Error SQL al guardar mensaje: " + e.getMessage());
            throw new ApiException(500, "Error al guardar mensaje", e);
        }

        // 5. Obtener historial con manejo de null
        List<Map<String, Object>> history;
        try {
            System.err.println("🔵 DEBUG: Obteniendo historial...");
            history = CHAT_REPOSITORY.listarMensajes(idConversacion);
            if (history == null) {
                history = new ArrayList<>();
                System.err.println("⚠️ DEBUG: Historial era null, usando lista vacía");
            }
            System.err.println("🔵 DEBUG: Historial obtenido, " + history.size() + " mensajes");
        } catch (SQLException e) {
            System.err.println("❌ Error SQL al obtener historial: " + e.getMessage());
            history = new ArrayList<>(); // Fallback a lista vacía
        }

        // 6. Generar respuesta del bot con manejo de errores
        String botReply;
        try {
            System.err.println("🔵 DEBUG: Generando respuesta del bot...");
            botReply = CHATBOT_RESPONDER.generateReply(req.mensaje.trim(), history, req.idRemitente);
            if (botReply == null || botReply.trim().isEmpty()) {
                botReply = "Estoy aquí para ayudarte con tu pedido. ¿En qué puedo asistirte?";
                System.err.println("⚠️ DEBUG: Bot reply era null/vacío, usando fallback");
            }
            System.err.println("🔵 DEBUG: Bot reply generado: " + botReply);
        } catch (Exception e) {
            System.err.println("❌ Error al generar respuesta del bot: " + e.getMessage());
            e.printStackTrace();
            botReply = "Lo siento, tengo problemas técnicos. Por favor contacta a soporte.";
        }

        // 7. Guardar respuesta del bot
        try {
            System.err.println("🔵 DEBUG: Guardando respuesta del bot...");
            long botUserId = CHAT_REPOSITORY.ensureBotUser();
            CHAT_REPOSITORY.insertMensaje(idConversacion, botUserId, req.idRemitente.longValue(), botReply);
            System.err.println("🔵 DEBUG: Respuesta del bot guardada");
        } catch (SQLException e) {
            System.err.println("❌ Error SQL al guardar respuesta del bot: " + e.getMessage());
            // No lanzar excepción aquí, ya tenemos la respuesta generada
        }

        // 8. Preparar respuesta con telemetría
        String modelUsed = GEMINI_SERVICE.getLastModelUsed();
        if (modelUsed != null && !modelUsed.isBlank()) {
            ctx.header("X-LLM-Model", modelUsed);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("id_conversacion", idConversacion);
        result.put("bot_reply", botReply);
        result.put("model_used", (modelUsed != null && !modelUsed.isBlank()) ? modelUsed : "predefinido");
        
        System.err.println("✅ DEBUG: Respuesta exitosa");
        handleResponse(ctx, ApiResponse.success(201, "Respuesta generada", result));
        
    } catch (ApiException e) {
        // Re-lanzar ApiException para que sea manejada por el handler global
        throw e;
    } catch (Exception e) {
        System.err.println("❌ Error general en chatbot: " + e.getMessage());
        e.printStackTrace();
        throw new ApiException(500, "Error interno del chatbot: " + e.getMessage(), e);
    }
});