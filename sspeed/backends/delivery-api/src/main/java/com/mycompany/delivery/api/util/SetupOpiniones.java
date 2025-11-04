package com.mycompany.delivery.api.util;

import com.mycompany.delivery.api.config.Database;
import java.sql.Connection;
import java.sql.Statement;

/**
 * Utilidad para crear la tabla de opiniones si no existe
 */
public class SetupOpiniones {
    
    public static void main(String[] args) {
        try {
            System.out.println("🔧 Configurando tabla de opiniones...");
            
            String createTableSQL = """
                CREATE TABLE IF NOT EXISTS opiniones (
                  id_opinion       SERIAL PRIMARY KEY,
                  id_usuario       INTEGER NULL,
                  nombre           VARCHAR(150) NULL,
                  email            VARCHAR(160) NULL,
                  rating           SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
                  comentario       TEXT NOT NULL,
                  clasificacion    VARCHAR(20) GENERATED ALWAYS AS (
                                      CASE 
                                        WHEN rating <= 2 THEN 'mala'
                                        WHEN rating = 3 THEN 'regular'
                                        WHEN rating = 4 THEN 'buena'
                                        ELSE 'excelente'
                                      END
                                    ) STORED,
                  plataforma       VARCHAR(40) NULL DEFAULT 'web',
                  estado           VARCHAR(20) NOT NULL DEFAULT 'aprobada' CHECK (estado IN ('pendiente','aprobada','rechazada')),
                  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  updated_at       TIMESTAMP NULL DEFAULT NULL
                );
            """;
            
            String createIndexesSQL = """
                CREATE INDEX IF NOT EXISTS idx_opiniones_rating ON opiniones(rating);
                CREATE INDEX IF NOT EXISTS idx_opiniones_clasificacion ON opiniones(clasificacion);
                CREATE INDEX IF NOT EXISTS idx_opiniones_estado ON opiniones(estado);
                CREATE INDEX IF NOT EXISTS idx_opiniones_created ON opiniones(created_at);
            """;
            
            String insertDataSQL = """
                INSERT INTO opiniones (nombre, email, rating, comentario, plataforma) VALUES
                ('María González', 'maria@email.com', 5, 'Excelente servicio, muy rápido y la comida llegó caliente. Definitivamente volveré a pedir.', 'web'),
                ('Carlos Rodríguez', 'carlos@email.com', 4, 'Muy buen servicio, solo tardó un poco más de lo esperado pero la calidad es buena.', 'app'),
                ('Ana López', 'ana@email.com', 5, 'Increíble experiencia! El repartidor fue muy amable y la comida deliciosa.', 'web'),
                ('Pedro Martín', 'pedro@email.com', 4, 'Buena aplicación, fácil de usar. La entrega fue puntual.', 'app'),
                ('Laura Sánchez', 'laura@email.com', 5, 'El mejor servicio de delivery que he usado. Muy recomendado!', 'web'),
                ('José García', 'jose@email.com', 3, 'Servicio regular, puede mejorar en los tiempos de entrega.', 'app')
                ON CONFLICT DO NOTHING;
            """;
            
            try (Connection conn = Database.getConnection();
                 Statement stmt = conn.createStatement()) {
                
                // Crear tabla
                stmt.execute(createTableSQL);
                System.out.println("✅ Tabla 'opiniones' creada/verificada");
                
                // Crear índices
                stmt.execute(createIndexesSQL);
                System.out.println("✅ Índices creados/verificados");
                
                // Insertar datos de ejemplo
                int rows = stmt.executeUpdate(insertDataSQL);
                System.out.println("✅ Datos de ejemplo insertados: " + rows + " filas");
                
                System.out.println("🎉 Configuración de opiniones completada exitosamente!");
                
            }
            
        } catch (Exception e) {
            System.err.println("❌ Error al configurar opiniones: " + e.getMessage());
            e.printStackTrace();
        }
    }
}