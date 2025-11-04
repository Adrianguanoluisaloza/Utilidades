package com.mycompany.delivery.api.util;

import io.github.cdimascio.dotenv.Dotenv;

/**
 * Feature flags centralizados. Mantiene compatibilidad con entornos sin .env.
 */
public final class FeatureFlags {

    private static final Dotenv DOTENV;
    static {
        Dotenv env;
        try { env = Dotenv.load(); } catch (Throwable t) { env = null; }
        DOTENV = env;
    }

    private FeatureFlags() {}

    public static boolean isGpt5Enabled() {
        String v = getEnv("FEATURE_GPT5_ENABLED");
        if (v == null || v.isBlank()) {
            // Habilitado por requerimiento: "Enable GPT-5 for all clients"
            return true;
        }
        return v.equalsIgnoreCase("1") || v.equalsIgnoreCase("true") || v.equalsIgnoreCase("yes");
    }

    private static String getEnv(String key) {
        try {
            String sys = System.getenv(key);
            if (sys != null) return sys;
        } catch (Throwable ignored) {}
        try {
            String prop = System.getProperty(key);
            if (prop != null) return prop;
        } catch (Throwable ignored) {}
        try {
            if (DOTENV != null) return DOTENV.get(key);
        } catch (Throwable ignored) {}
        return null;
    }
}
