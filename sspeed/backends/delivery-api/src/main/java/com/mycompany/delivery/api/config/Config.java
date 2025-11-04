package com.mycompany.delivery.api.config;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

/**
 * Cargador simple de application.properties desde el classpath.
 * Prioridad recomendada en uso: System properties/env > .env > application.properties.
 */
public final class Config {
    private static final Properties PROPS = new Properties();

    static {
        try (InputStream in = Config.class.getClassLoader().getResourceAsStream("application.properties")) {
            if (in != null) {
                PROPS.load(in);
                System.out.println("ℹ️  application.properties cargado del classpath");
            } else {
                System.out.println("ℹ️  application.properties no encontrado; se usarán ENV/.env");
            }
        } catch (IOException e) {
            System.err.println("⚠️  No se pudo cargar application.properties: " + e.getMessage());
        }
    }

    private Config() {}

    public static String get(String key) {
        return PROPS.getProperty(key);
    }

    public static String getOrDefault(String key, String fallback) {
        String v = get(key);
        return (v == null || v.isBlank()) ? fallback : v.trim();
    }
}
