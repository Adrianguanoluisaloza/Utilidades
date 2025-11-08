package com.mycompany.delivery.api.config;

import java.sql.Connection;
import java.sql.SQLException;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

/**
 * Gestiona el pool HikariCP reutilizado por toda la API.
 * Centralizar aquí la reconexión evita fugas de conexiones y mejora la estabilidad.
 */
public final class Database {

    private static final Object LOCK = new Object();
    private static HikariDataSource dataSource;

    static {
        initialiseDataSource();
    }

    private Database() {
    }

    private static void initialiseDataSource() {
        HikariConfig config = new HikariConfig();
        // Importante: no incluir credenciales reales como valores por defecto.
        // Usa variables de entorno o un .env (ver README_dotenv.txt).
        String jdbcUrl = getEnv("DB_URL", "jdbc:postgresql://localhost:5432/postgres");
        String username = getEnv("DB_USER", "postgres");
        String password = getEnv("DB_PASSWORD", "");

        config.setJdbcUrl(jdbcUrl);
        config.setUsername(username);
        config.setPassword(password);

        // Pool tuning seguro por defecto; configurable por ENV
        int maxPool = parseInt(getEnv("DB_POOL_SIZE", "10"), 10);
        int minIdle = parseInt(getEnv("DB_MIN_IDLE", "2"), 2);
        long connTimeoutMs = parseLong(getEnv("DB_CONN_TIMEOUT_MS", "10000"), 10000);
        long idleTimeoutMs = parseLong(getEnv("DB_IDLE_TIMEOUT_MS", "600000"), 600000);      // 10 min
        long maxLifetimeMs = parseLong(getEnv("DB_MAX_LIFETIME_MS", "1800000"), 1800000);    // 30 min

        config.setMaximumPoolSize(maxPool);
        config.setMinimumIdle(minIdle);
        config.setConnectionTimeout(connTimeoutMs);
        config.setIdleTimeout(idleTimeoutMs);
        config.setMaxLifetime(maxLifetimeMs);

        // Optimización de prepared statements
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");

        if (dataSource != null) {
            dataSource.close();
        }

        dataSource = new HikariDataSource(config);
        System.out.println("✅ Pool de conexiones inicializado/reiniciado correctamente.");
    }

    private static String getEnv(String key, String fallback) {
        // Prioridad: System properties > ENV > application.properties > fallback
        String v = System.getProperty(key);
        if (v != null && !v.isBlank()) return v.trim();
        v = System.getenv(key);
        if (v != null && !v.isBlank()) return v.trim();
        v = Config.get(key);
        if (v != null && !v.isBlank()) return v.trim();
        return fallback;
    }

    private static int parseInt(String value, int fallback) {
        try { return Integer.parseInt(value); } catch (Exception ignored) { return fallback; }
    }

    private static long parseLong(String value, long fallback) {
        try { return Long.parseLong(value); } catch (Exception ignored) { return fallback; }
    }

    private static void ensureDataSource() {
        synchronized (LOCK) {
            if (dataSource == null || dataSource.isClosed()) {
                // Intentamos reconstruir el pool si se cerró o falló.
                initialiseDataSource();
            }
        }
    }

    /**
     * Obtiene una conexión válida del pool.
     */
    public static Connection getConnection() throws SQLException {
        ensureDataSource();
        return dataSource.getConnection();
    }

    /**
     * Verifica el estado de la conexión para detectar fallos tempranamente.
     */
    public static void ping() {
        try (Connection connection = getConnection()) {
            if (!connection.isValid(5)) {
                throw new SQLException("Conexión devuelta por el pool no es válida");
            }
        } catch (SQLException e) {
            System.err.println("❌ Fallo al verificar la base de datos: " + e.getMessage());
            throw new RuntimeException("No se pudo establecer conexión estable con PostgreSQL", e);
        }
    }
}
