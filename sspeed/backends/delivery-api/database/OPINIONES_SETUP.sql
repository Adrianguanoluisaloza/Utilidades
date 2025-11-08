-- Tabla de opiniones de clientes para Unite Speed
-- Compatible con PostgreSQL

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

-- Índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_opiniones_rating ON opiniones(rating);
CREATE INDEX IF NOT EXISTS idx_opiniones_clasificacion ON opiniones(clasificacion);
CREATE INDEX IF NOT EXISTS idx_opiniones_estado ON opiniones(estado);
CREATE INDEX IF NOT EXISTS idx_opiniones_created ON opiniones(created_at);

-- Vista rápida para admin por clasificacion
CREATE OR REPLACE VIEW vw_opiniones_resumen AS
SELECT 
  clasificacion,
  COUNT(*) AS total,
  ROUND(AVG(rating::numeric),2) AS rating_promedio,
  SUM(CASE WHEN estado='aprobada' THEN 1 ELSE 0 END) AS aprobadas,
  SUM(CASE WHEN estado='pendiente' THEN 1 ELSE 0 END) AS pendientes,
  SUM(CASE WHEN estado='rechazada' THEN 1 ELSE 0 END) AS rechazadas
FROM opiniones
GROUP BY clasificacion;

-- Insertar datos de ejemplo
INSERT INTO opiniones (nombre, email, rating, comentario, plataforma) VALUES
('María González', 'maria@email.com', 5, 'Excelente servicio, muy rápido y la comida llegó caliente. Definitivamente volveré a pedir.', 'web'),
('Carlos Rodríguez', 'carlos@email.com', 4, 'Muy buen servicio, solo tardó un poco más de lo esperado pero la calidad es buena.', 'app'),
('Ana López', 'ana@email.com', 5, 'Increíble experiencia! El repartidor fue muy amable y la comida deliciosa.', 'web'),
('Pedro Martín', 'pedro@email.com', 4, 'Buena aplicación, fácil de usar. La entrega fue puntual.', 'app'),
('Laura Sánchez', 'laura@email.com', 5, 'El mejor servicio de delivery que he usado. Muy recomendado!', 'web'),
('José García', 'jose@email.com', 3, 'Servicio regular, puede mejorar en los tiempos de entrega.', 'app');

-- Consultas útiles comentadas
-- Últimas 20 opiniones aprobadas:
-- SELECT * FROM opiniones WHERE estado='aprobada' ORDER BY created_at DESC LIMIT 20;

-- Opiniones por clasificacion (admin):
-- SELECT * FROM opiniones WHERE clasificacion IN ('mala','regular','buena','excelente') ORDER BY created_at DESC LIMIT 50;

-- Estadísticas generales:
-- SELECT * FROM vw_opiniones_resumen;