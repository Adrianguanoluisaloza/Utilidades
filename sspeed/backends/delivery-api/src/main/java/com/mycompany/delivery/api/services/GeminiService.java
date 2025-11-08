package com.mycompany.delivery.api.services;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import io.github.cdimascio.dotenv.Dotenv;

/**
 * Servicio ligero que consume la API de Gemini (Generative Language) v1
 * empleando {@link java.net.http.HttpClient}. Construye un payload compatible
 * con el endpoint /v1/models/:generateContent.
 */
public final class GeminiService {

    private static final String DEFAULT_MODEL_NAME = "gemini-2.5-flash";
    private static final String API_URL_TEMPLATE =
            "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s";
    private static final String FALLBACK_MESSAGE =
            "Lo siento, mi cerebro (IA) no esta disponible en este momento. Por favor, contacta a soporte.";

    private static final Gson GSON = new Gson();
    private static final HttpClient HTTP_CLIENT = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    private static final Dotenv DOTENV;
    static {
        Dotenv env;
        try {
            env = Dotenv.configure().ignoreIfMissing().load();
        } catch (Throwable t) {
            env = null;
        }
        DOTENV = env;
    }

    private final String apiKey;
    private final String modelName; // compat: modelo por defecto

    // Enrutamiento dinámico (configurable por env)
    private final String primaryModel;   // para la mayoría de chats
    private final String fallbackModel;  // cuando hay límite o modo ahorro
    private final String heavyModel;     // prompts largos/complejos

    // Limitadores simples por minuto (RPM/TPM aproximado)
    private final RateLimiter primaryLimiter;
    private final RateLimiter fallbackLimiter;
    private final RateLimiter heavyLimiter;

    // Telemetría por-request (segura para concurrencia con hilos HTTP)
    private final ThreadLocal<String> lastModelUsed = new ThreadLocal<>();
    private final ThreadLocal<Integer> lastEstimatedTokens = new ThreadLocal<>();

    public GeminiService() {
        this.apiKey = resolveApiKey();
        this.modelName = resolveModelName();

        this.primaryModel = coalesce(readEnv("GEMINI_PRIMARY_MODEL"), "gemini-2.5-flash");
        this.fallbackModel = coalesce(readEnv("GEMINI_FALLBACK_MODEL"), "gemini-2.0-flash-lite");
        this.heavyModel = coalesce(readEnv("GEMINI_HEAVY_MODEL"), "gemini-2.5-pro");

        // RPM/TPM: valores conservadores por defecto; ajustables por env
        int primaryRpm = parseInt(readEnv("GEMINI_PRIMARY_RPM"), 8);
        int primaryTpm = parseInt(readEnv("GEMINI_PRIMARY_TPM"), 120_000);

        int fallbackRpm = parseInt(readEnv("GEMINI_FALLBACK_RPM"), 30);
        int fallbackTpm = parseInt(readEnv("GEMINI_FALLBACK_TPM"), 1_000_000);

        int heavyRpm = parseInt(readEnv("GEMINI_HEAVY_RPM"), 2);
        int heavyTpm = parseInt(readEnv("GEMINI_HEAVY_TPM"), 125_000);

        this.primaryLimiter = new RateLimiter(primaryRpm, primaryTpm);
        this.fallbackLimiter = new RateLimiter(fallbackRpm, fallbackTpm);
        this.heavyLimiter = new RateLimiter(heavyRpm, heavyTpm);
    }

    /**
     * Genera una respuesta a partir del prompt y la conversacion previa.
     *
     * @param prompt        Mensaje actual del usuario.
     * @param history       Historial de mensajes (cada elemento debe contener al menos
     *                      las claves "id_remitente" y "mensaje").
     * @param currentUserId Identificador del usuario actual (para determinar su rol).
     * @return Texto devuelto por Gemini o un mensaje alternativo si no fue posible.
     */
    public String generateReply(String prompt,
                                List<Map<String, Object>> history,
                                int currentUserId) {
        if (apiKey == null || apiKey.isBlank()) {
            return FALLBACK_MESSAGE;
        }

        final String safePrompt = prompt == null ? "" : prompt.trim();
        if (safePrompt.isEmpty()) {
            return "Podrias indicarme tu consulta?";
        }

        try {
            return generateReplyWithModel(this.modelName, safePrompt, history, currentUserId);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            System.err.println("Gemini interrumpido: " + e.getMessage());
            return FALLBACK_MESSAGE;
        } catch (IOException e) {
            System.err.println("Error al conectarse con Gemini: " + e.getMessage());
            return FALLBACK_MESSAGE;
        } catch (Exception e) {
            System.err.println("Error inesperado al procesar respuesta de Gemini: " + e.getMessage());
            return FALLBACK_MESSAGE;
        }
    }

    /**
     * Igual que generateReply, pero permitiendo especificar el modelo.
     */
    public String generateReplyWithModel(String model,
                                         String prompt,
                                         List<Map<String, Object>> history,
                                         int currentUserId) throws IOException, InterruptedException {
        JsonObject requestPayload = buildPayload(prompt, history, currentUserId);
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(String.format(API_URL_TEMPLATE, model, apiKey)))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(30))
                .POST(HttpRequest.BodyPublishers.ofString(GSON.toJson(requestPayload)))
                .build();

        HttpResponse<String> response = HTTP_CLIENT.send(
                request,
                HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            System.err.printf("Gemini API error %d: %s%n",
                    response.statusCode(), response.body());
            return FALLBACK_MESSAGE;
        }

        return extractReply(response.body());
    }

    /**
     * Selecciona modelo automáticamente según longitud y límites actuales
     * y hace fallback inteligente para cuidar las cuotas.
     */
    public String generateSmartReply(String prompt,
                                     List<Map<String, Object>> history,
                                     int currentUserId) {
        if (apiKey == null || apiKey.isBlank()) return FALLBACK_MESSAGE;

        final String safePrompt = prompt == null ? "" : prompt.trim();
        if (safePrompt.isEmpty()) return "Podrias indicarme tu consulta?";

    int estimatedTokens = estimateTokens(safePrompt, history);
    lastEstimatedTokens.set(estimatedTokens);
        int heavyTrigger = parseInt(readEnv("GEMINI_HEAVY_TRIGGER_TOKENS"), 2500);

        String chosen = this.primaryModel;
        RateLimiter limiter = this.primaryLimiter;
        if (estimatedTokens >= heavyTrigger) {
            chosen = this.heavyModel;
            limiter = this.heavyLimiter;
        }

        // Si el limitador rechaza (RPM/TPM), probar fallback
        if (!limiter.tryConsume(1, estimatedTokens)) {
            if (chosen.equals(this.heavyModel)) {
                // Segundo intento: usar primary si cabe
                if (primaryLimiter.tryConsume(1, estimatedTokens)) {
                    chosen = this.primaryModel;
                    limiter = this.primaryLimiter;
                } else if (fallbackLimiter.tryConsume(1, estimatedTokens)) {
                    chosen = this.fallbackModel;
                    limiter = this.fallbackLimiter;
                } else {
                    return "Estoy con mucha demanda ahora mismo. Inténtalo en unos segundos o contacta a soporte.";
                }
            } else {
                if (fallbackLimiter.tryConsume(1, estimatedTokens)) {
                    chosen = this.fallbackModel;
                    limiter = this.fallbackLimiter;
                } else if (heavyLimiter.tryConsume(1, estimatedTokens)) {
                    chosen = this.heavyModel;
                    limiter = this.heavyLimiter;
                } else {
                    return "Estoy con mucha demanda ahora mismo. Inténtalo en unos segundos o contacta a soporte.";
                }
            }
        }

        try {
            lastModelUsed.set(chosen);
            String text = generateReplyWithModel(chosen, safePrompt, history, currentUserId);
            logRouting(chosen, estimatedTokens, "primary/heavy");
            return text;
        } catch (Exception e) {
            System.err.println("Fallo con modelo " + chosen + ": " + e.getMessage());
            // Intento final: fallbackModel si no era el que usamos
            if (!chosen.equals(fallbackModel)) {
                try {
                    if (fallbackLimiter.tryConsume(1, estimatedTokens)) {
                        lastModelUsed.set(fallbackModel);
                        String text = generateReplyWithModel(fallbackModel, safePrompt, history, currentUserId);
                        logRouting(fallbackModel, estimatedTokens, "exception-fallback");
                        return text;
                    }
                } catch (Exception ignored) {}
            }
            return FALLBACK_MESSAGE;
        }
    }

    /**
     * Variante que devuelve además metadatos del enrutamiento (modelo y tokens estimados).
     */
    public Map<String, Object> generateSmartReplyWithInfo(String prompt,
                                                          List<Map<String, Object>> history,
                                                          int currentUserId) {
        String text = generateSmartReply(prompt, history, currentUserId);
        return java.util.Map.of(
                "text", text,
                "modelUsed", getLastModelUsed(),
                "estimatedTokens", getLastEstimatedTokens()
        );
    }

    public String getLastModelUsed() {
        return lastModelUsed.get();
    }

    public Integer getLastEstimatedTokens() {
        return lastEstimatedTokens.get();
    }

    private void logRouting(String model, int estimatedTokens, String stage) {
        try {
            String json = GSON.toJson(java.util.Map.of(
                    "event", "gemini_request",
                    "chosenModel", model,
                    "estimatedTokens", estimatedTokens,
                    "stage", stage,
                    "ts", System.currentTimeMillis()
            ));
            System.out.println(json);
        } catch (Throwable ignored) {}
    }

    private JsonObject buildPayload(String prompt,
                                    List<Map<String, Object>> history,
                                    int currentUserId) {
        JsonArray contents = new JsonArray();

        contents.add(content("user",
                "Eres CIA Bot, un asistente virtual amigable y servicial para una app de delivery. "
                        + "Ayuda con pedidos, dudas de la app y conversa de manera cordial y breve."));
        contents.add(content("model", "Entendido, listo para ayudar."));

        if (history != null && !history.isEmpty()) {
            int start = Math.max(0, history.size() - 12);
            for (int i = start; i < history.size(); i++) {
                Map<String, Object> message = history.get(i);
                if (message == null) {
                    continue;
                }
                Object textObj = message.get("mensaje");
                if (textObj == null) {
                    continue;
                }
                String text = textObj.toString();
                if (text.isBlank()) {
                    continue;
                }
                int senderId = -1;
                Object senderObj = message.get("id_remitente");
                if (senderObj instanceof Number number) {
                    senderId = number.intValue();
                }
                String role = (senderId == currentUserId) ? "user" : "model";
                contents.add(content(role, text));
            }
        }

        contents.add(content("user", prompt));

        JsonObject request = new JsonObject();
        request.add("contents", contents);
        return request;
    }

    private JsonObject content(String role, String text) {
        JsonObject content = new JsonObject();
        content.addProperty("role", role);
        JsonArray parts = new JsonArray();
        JsonObject part = new JsonObject();
        part.addProperty("text", text);
        parts.add(part);
        content.add("parts", parts);
        return content;
    }

    private String extractReply(String body) {
        JsonObject json = GSON.fromJson(body, JsonObject.class);
        JsonArray candidates = json != null ? json.getAsJsonArray("candidates") : null;
        if (candidates == null || candidates.isEmpty()) {
            return FALLBACK_MESSAGE;
        }

        JsonObject candidate = candidates.get(0).getAsJsonObject();
        JsonObject content = candidate.getAsJsonObject("content");
        if (content == null) {
            return FALLBACK_MESSAGE;
        }

        JsonArray parts = content.getAsJsonArray("parts");
        if (parts == null) {
            return FALLBACK_MESSAGE;
        }

        List<String> fragments = new ArrayList<>();
        for (JsonElement partEl : parts) {
            if (!partEl.isJsonObject()) {
                continue;
            }
            JsonObject part = partEl.getAsJsonObject();
            JsonElement textEl = part.get("text");
            if (textEl != null && !textEl.isJsonNull()) {
                String fragment = textEl.getAsString();
                if (!fragment.isBlank()) {
                    fragments.add(fragment.trim());
                }
            }
        }

        if (fragments.isEmpty()) {
            return FALLBACK_MESSAGE;
        }
        return String.join("\n", fragments);
    }

    private String resolveApiKey() {
        String key = readEnv("GEMINI_API_KEY");
        if (key != null && !key.isBlank()) {
            return key;
        }
        key = readEnv("GOOGLE_API_KEY"); // alias común en documentacion oficial
        if (key != null && !key.isBlank()) {
            return key;
        }
        return null;
    }

    private String resolveModelName() {
        String model = readEnv("GEMINI_MODEL");
        if (model != null && !model.isBlank()) {
            return model;
        }
        model = readEnv("GOOGLE_GEMINI_MODEL");
        if (model != null && !model.isBlank()) {
            return model;
        }
        return DEFAULT_MODEL_NAME;
    }

    private static String readEnv(String key) {
        try {
            String value = System.getenv(key);
            if (value != null && !value.isBlank()) {
                return value.trim();
            }
        } catch (Throwable ignored) {}

        try {
            String value = System.getProperty(key);
            if (value != null && !value.isBlank()) {
                return value.trim();
            }
        } catch (Throwable ignored) {}

        try {
            if (DOTENV != null) {
                String value = DOTENV.get(key);
                if (value != null && !value.isBlank()) {
                    return value.trim();
                }
            }
        } catch (Throwable ignored) {}

        return null;
    }

    private static String coalesce(String a, String b) {
        return (a != null && !a.isBlank()) ? a.trim() : b;
    }

    private static int parseInt(String v, int def) {
        try { return v == null ? def : Integer.parseInt(v.trim()); } catch (Exception e) { return def; }
    }

    private static int estimateTokens(String prompt, List<Map<String, Object>> history) {
        int chars = prompt == null ? 0 : prompt.length();
        if (history != null) {
            for (Map<String, Object> m : history) {
                Object t = m == null ? null : m.get("mensaje");
                if (t != null) chars += t.toString().length();
            }
        }
        // Aproximación: ~4 chars/token
        return Math.max(1, chars / 4);
    }

    /**
     * Rate limiter simple por ventana de 60s con control de requests y tokens.
     */
    private static final class RateLimiter {
        private final int maxRpm;
        private final int maxTpm;
        private long windowStartMs = System.currentTimeMillis();
        private int usedRequests = 0;
        private int usedTokens = 0;

        RateLimiter(int maxRpm, int maxTpm) {
            this.maxRpm = Math.max(1, maxRpm);
            this.maxTpm = Math.max(1000, maxTpm);
        }

        synchronized boolean tryConsume(int requests, int tokens) {
            rollWindow();
            if (usedRequests + requests > maxRpm) return false;
            if (usedTokens + tokens > maxTpm) return false;
            usedRequests += requests;
            usedTokens += tokens;
            return true;
        }

        private void rollWindow() {
            long now = System.currentTimeMillis();
            if (now - windowStartMs >= 60_000) {
                windowStartMs = now;
                usedRequests = 0;
                usedTokens = 0;
            }
        }
    }
}
