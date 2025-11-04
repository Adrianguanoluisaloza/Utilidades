package com.mycompany.delivery.api.util;

import java.util.Objects;
import java.util.regex.Pattern;

/**
 * Utilidades simples para validar entradas en endpoints.
 * Arrojan ApiException(400) con mensajes claros cuando la validación falla.
 */
public final class RequestValidator {
    private static final Pattern EMAIL_RE = Pattern.compile("^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$", Pattern.CASE_INSENSITIVE);

    private RequestValidator() {}

    public static String requireNonBlank(String value, String message) {
        if (value == null || value.trim().isEmpty()) {
            throw new ApiException(400, message);
        }
        return value.trim();
    }

    public static String requireEmail(String email, String fieldName) {
        String v = requireNonBlank(email, fieldName + " es obligatorio");
        if (!EMAIL_RE.matcher(v).matches()) {
            throw new ApiException(400, fieldName + " no tiene formato válido");
        }
        return v.toLowerCase();
    }

    public static int requirePositiveInt(Integer value, String fieldName) {
        if (value == null || value <= 0) {
            throw new ApiException(400, fieldName + " debe ser un entero positivo");
        }
        return value;
    }

    public static long requirePositiveLong(Long value, String fieldName) {
        if (value == null || value <= 0) {
            throw new ApiException(400, fieldName + " debe ser un entero positivo");
        }
        return value;
    }

    public static <T> T requireNonNull(T value, String fieldName) {
        return Objects.requireNonNullElseGet(value, () -> {
            throw new ApiException(400, fieldName + " es obligatorio");
        });
    }

    public static void requireMinLength(String value, int min, String fieldName) {
        String v = requireNonBlank(value, fieldName + " es obligatorio");
        if (v.length() < min) {
            throw new ApiException(400, fieldName + " debe tener al menos " + min + " caracteres");
        }
    }

    public static void requireRangeInt(int value, int min, int max, String fieldName) {
        if (value < min || value > max) {
            throw new ApiException(400, fieldName + " debe estar entre " + min + " y " + max);
        }
    }

    /**
     * Valida que el cuerpo parseado no sea nulo para evitar NullPointerException.
     */
    public static <T> T requireBody(T body, String name) {
        if (body == null) {
            throw new ApiException(400, "Cuerpo de solicitud ('" + name + "') es obligatorio");
        }
        return body;
    }
}
