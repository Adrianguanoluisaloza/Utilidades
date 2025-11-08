# SCHEMA COMPLETO UNIFICADO - UNITE SPEED DELIVERY

## CEO: Michael Ortiz

## RESUMEN

Este script SQL unifica TODAS las tablas, índices, funciones y datos de ejemplo del sistema Unite Speed Delivery en un solo archivo ejecutable.

---

## CONTENIDO DEL SCRIPT

### 1. TABLAS PRINCIPALES (11 tablas)
- roles
- usuarios
- negocios
- categorias
- productos
- ubicaciones
- pedidos
- detalle_pedidos
- recomendaciones
- password_resets

### 2. TRACKING (2 tablas)
- tracking_ruta (histórico GPS)
- tracking_eventos (puntos predefinidos)

### 3. CHAT E IA (4 tablas)
- chat_conversaciones
- chat_mensajes
- ia_categorias_respuesta
- ia_respuestas_automaticas

### 4. SOPORTE (4 tablas)
- soporte_conversaciones
- soporte_mensajes
- soporte_respuestas_predef
- soporte_usuarios

### 5. FUNCIONES
- set_updated_at() - Actualiza timestamps
- trg_hash_password() - Hashea contraseñas con BCrypt
- fn_chatbot_match_predef() - Matching de respuestas IA

### 6. ÍNDICES (20+ índices)
- Optimizados para consultas frecuentes
- Índices en foreign keys
- Índices compuestos para dashboards

---

## CÓMO EJECUTAR

### Opción 1: Desde terminal (psql)

```bash
cd C:\Users\Adrian\Proyecto\sspeed\backends\delivery-api\database
psql -U postgres -d delivery_db -f SCHEMA_COMPLETO_UNIFICADO.sql
```

### Opción 2: Desde pgAdmin

1. Abrir pgAdmin
2. Conectar a delivery_db
3. Tools → Query Tool
4. File → Open → Seleccionar SCHEMA_COMPLETO_UNIFICADO.sql
5. Ejecutar (F5)

### Opción 3: Crear BD desde cero

```bash
# Crear base de datos
createdb delivery_db

# Ejecutar script
psql -U postgres -d delivery_db -f SCHEMA_COMPLETO_UNIFICADO.sql
```

---

## ADVERTENCIA

Este script ejecuta `DROP SCHEMA IF EXISTS public CASCADE` que ELIMINA TODOS LOS DATOS EXISTENTES.

Solo ejecutar en:
- Base de datos nueva
- Ambiente de desarrollo
- Después de hacer backup

---

## VERIFICACIÓN POST-EJECUCIÓN

```sql
-- Ver todas las tablas
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

-- Contar registros
SELECT COUNT(*) FROM usuarios;
SELECT COUNT(*) FROM tracking_eventos;
SELECT COUNT(*) FROM ia_respuestas_automaticas;

-- Verificar funciones
SELECT proname FROM pg_proc WHERE proname LIKE '%chatbot%';
```

---

## DATOS DE EJEMPLO INCLUIDOS

### Usuarios (4)
- carlos@test.com (cliente)
- pablo@test.com (delivery)
- nelson@test.com (negocio)
- ana@test.com (admin)

Contraseñas: Ver script (todas terminan en 123!)

### Tracking
- 6 puntos GPS para pedido #1 (Esmeraldas, Ecuador)

### IA
- 5 categorías de respuestas
- 3 respuestas automáticas básicas

---

## DIFERENCIAS CON SCRIPTS ANTERIORES

### Incluye TODO de:
- rebuild_database.sql (tablas principales)
- TRACKING_SETUP.sql (tracking_eventos)
- 20251102_password_reset.sql (password_resets)
- Mejoras de MEJORAS_BASE_DATOS.md

### Mejoras adicionales:
- Índices optimizados
- Comentarios en español
- Datos de ejemplo listos
- Verificación automática al final

---

## TABLAS POR MÓDULO

### AUTENTICACIÓN
- usuarios
- roles
- password_resets

### CATÁLOGO
- negocios
- categorias
- productos

### PEDIDOS
- pedidos
- detalle_pedidos
- ubicaciones

### TRACKING
- tracking_ruta
- tracking_eventos

### CHAT
- chat_conversaciones
- chat_mensajes
- ia_categorias_respuesta
- ia_respuestas_automaticas

### SOPORTE
- soporte_conversaciones
- soporte_mensajes
- soporte_respuestas_predef
- soporte_usuarios

### OTROS
- recomendaciones

---

## RELACIONES PRINCIPALES

```
usuarios (1) ──▶ (N) pedidos
usuarios (1) ──▶ (N) ubicaciones
negocios (1) ──▶ (N) productos
pedidos (1) ──▶ (N) detalle_pedidos
pedidos (1) ──▶ (N) tracking_eventos
```

---

## PRÓXIMOS PASOS

1. Ejecutar este script en BD limpia
2. Verificar que todas las tablas se crearon
3. Probar endpoints de la API
4. Agregar más datos de ejemplo si es necesario

---

## BACKUP ANTES DE EJECUTAR

```bash
# Hacer backup de BD actual
pg_dump -U postgres -d delivery_db > backup_antes_unificado_$(date +%Y%m%d).sql

# Restaurar si algo sale mal
psql -U postgres -d delivery_db < backup_antes_unificado_20250115.sql
```

---

## CONTACTO

CEO: Michael Ortiz
Proyecto: Unite Speed Delivery
Versión: 1.0
Año: 2025
