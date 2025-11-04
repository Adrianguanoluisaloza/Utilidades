package com.mycompany.delivery.api.util;

import java.time.LocalTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import com.mycompany.delivery.api.model.Pedido;
import com.mycompany.delivery.api.repository.PedidoRepository;
import com.mycompany.delivery.api.services.GeminiService;

public final class ChatBotResponder {

    private final GeminiService geminiService;
    private final PedidoRepository pedidoRepository;
    private final com.mycompany.delivery.api.repository.ChatRepository chatRepository;
    private final com.mycompany.delivery.api.repository.RespuestaSoporteRepository respuestaSoporteRepo;

    public ChatBotResponder(GeminiService geminiService, PedidoRepository pedidoRepository, com.mycompany.delivery.api.repository.ChatRepository chatRepository) {
        this.geminiService = geminiService;
        this.pedidoRepository = pedidoRepository;
        this.chatRepository = chatRepository;
        this.respuestaSoporteRepo = new com.mycompany.delivery.api.repository.RespuestaSoporteRepository();
    }

    /**
     * Genera una respuesta dinámica para el chatbot.
     * PRIORIDAD: 1) Respuestas predefinidas BOT, 2) Lógica de pedidos con IA, 3) Fallback simple.
     *
     * @param rawMessage El mensaje del usuario.
     * @param history    El historial de la conversación.
     * @param idUsuario  El ID del usuario que envía el mensaje.
     * @return Una respuesta generada (preferentemente predefinida, IA solo si es necesario).
     */
    public String generateReply(String rawMessage, List<Map<String, Object>> history, int idUsuario) {
        String message = rawMessage == null ? "" : rawMessage.trim().toLowerCase();

        if (message.isBlank()) {
            return "Hola, puedo ayudarte con tu pedido. Cuéntame tu consulta.";
        }

        // ============================================================
        // PASO 1: Intentar respuesta predefinida del BOT (SIN IA)
        // ============================================================
        try {
            String respuestaBot = respuestaSoporteRepo.buscarRespuestaBot(message);
            if (respuestaBot != null && !respuestaBot.isBlank()) {
                System.out.println("✅ BOT: Respuesta predefinida encontrada para: " + message.substring(0, Math.min(message.length(), 30)));
                return respuestaBot;
            }
        } catch (Exception e) {
            System.err.println("⚠️ Error buscando respuesta bot predefinida: " + e.getMessage());
        }

        // ============================================================
        // PASO 2: Si pregunta por pedido, usar IA con contexto
        // ============================================================
        if (isOrderStatusQuery(message)) {
            try {
                Optional<Pedido> pedidoOpt = pedidoRepository.obtenerPedidoMasRecientePorCliente(idUsuario);
                String prompt = buildPromptForGemini(message, history, pedidoOpt);
                String iaReply = geminiService.generateSmartReply(prompt, history, idUsuario);
                System.out.println("🤖 BOT: Usando IA para consulta de pedido");
                return iaReply;
            } catch (Exception e) {
                System.err.println("❌ Error al procesar respuesta con IA: " + e.getMessage());
                return "Puedes revisar el estado actual en la pantalla 'Mis pedidos'. Te avisaremos cuando cambie a 'en camino'.";
            }
        }

        // ============================================================
        // PASO 3: Fallback simple (sin IA, respuestas hardcodeadas)
        // ============================================================
        System.out.println("ℹ️ BOT: Usando fallback simple para: " + message.substring(0, Math.min(message.length(), 30)));
        return getSimpleFallbackReply(message);
    }

    private boolean isOrderStatusQuery(String message) {
        return message.contains("pedido") || message.contains("orden") || message.contains("dónde está")
                || message.contains("estado de mi") || message.contains("cuando llega");
    }

    private String buildPromptForGemini(String userMessage, List<Map<String, Object>> history,
            Optional<Pedido> pedidoOpt) {
        StringBuilder prompt = new StringBuilder();
        prompt.append(
                "Eres un asistente virtual de un servicio de delivery llamado 'Unite Speed Delivery'. Tu nombre es CIA Bot. Responde de forma breve y amigable.\n");
        prompt.append("Historial de la conversación:\n");
        for (Map<String, Object> msg : history) {
            String role = (boolean) msg.getOrDefault("es_bot", false) ? "model" : "user";
            prompt.append(role).append(": ").append(msg.get("mensaje")).append("\n");
        }

        prompt.append("Pregunta actual del usuario: '").append(userMessage).append("'\n");

        if (pedidoOpt.isPresent()) {
            Pedido pedido = pedidoOpt.get();
            prompt.append(
                    "Usa la siguiente información para responder: El usuario tiene un pedido activo (ID: ")
                    .append(pedido.getIdPedido())
                    .append(") con estado '").append(pedido.getEstado())
                    .append("' que será entregado en '").append(pedido.getDireccionEntrega()).append("'.");
        } else {
            prompt.append(
                    "Usa la siguiente información para responder: El usuario no tiene ningún pedido activo en este momento. Invítalo a realizar uno.");
        }

        return prompt.toString();
    }

    private String getSimpleFallbackReply(String message) {
        if (message.contains("hola") || message.contains("buenos dias") || message.contains("buenas tardes")) {
            return saludo();
        }
        if (message.contains("cancelar")) {
            return "Si deseas cancelar, usa el botón 'Cancelar' dentro del detalle del pedido mientras siga en preparación.";
        }
        if (message.contains("gracias") || message.contains("thank")) {
            return "¡Con gusto! Si necesitas algo más, no dudes en preguntar.";
        }
        return "Estoy aquí para ayudarte con tu compra. Puedes preguntarme sobre el estado de tu pedido, tiempos de entrega o cómo cancelar.";
    }

    private static String saludo() {
        int hour = LocalTime.now().getHour();
        if (hour < 12) {
            return "¡Buenos días! ¿En qué puedo ayudarte con tu entrega?";
        }
        if (hour < 19) {
            return "¡Hola! Estoy pendiente de tu pedido. ¿Qué necesitas saber?";
        }
        return "¡Buenas noches! Si quieres revisar el estado o reportar un problema, dime y te ayudo.";
    }
}
