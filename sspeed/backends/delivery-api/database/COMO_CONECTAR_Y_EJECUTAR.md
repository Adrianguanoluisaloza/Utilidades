# 🗄️ GUÍA DE CONEXIÓN Y EJECUCIÓN DE SCRIPTS SQL

## 📋 Requisitos Previos

1. **PostgreSQL instalado** (versión 12 o superior)
2. **Credenciales de la base de datos** (del archivo `.env`)
3. **Cliente SQL** (pgAdmin, DBeaver, o psql en terminal)

---

## 🔐 Credenciales de Conexión

Según tu archivo `.env`, las credenciales son:

```
Host: localhost (o la IP de tu servidor)
Puerto: 5432 (puerto por defecto de PostgreSQL)
Base de datos: delivery_db
Usuario: postgres
Contraseña: [la que configuraste en DB_PASSWORD]
```

---

## 🚀 Método 1: Usando psql (Terminal)

### Windows:

```bash
# 1. Abrir CMD o PowerShell
cd C:\Users\Adrian\Proyecto\sspeed\backends\delivery-api\database

# 2. Conectar a PostgreSQL
psql -U postgres -d delivery_db

# 3. Ejecutar el script
\i TRACKING_SETUP.sql

# 4. Verificar que se creó la tabla
\dt tracking_eventos

# 5. Ver los datos insertados
SELECT * FROM tracking_eventos WHERE id_pedido = 1 ORDER BY orden;

# 6. Salir
\q
```

### Linux/Mac:

```bash
# 1. Navegar al directorio
cd ~/Proyecto/sspeed/backends/delivery-api/database

# 2. Conectar y ejecutar
psql -U postgres -d delivery_db -f TRACKING_SETUP.sql

# 3. Verificar
psql -U postgres -d delivery_db -c "SELECT * FROM tracking_eventos WHERE id_pedido = 1 ORDER BY orden;"
```

---

## 🖥️ Método 2: Usando pgAdmin (GUI)

1. **Abrir pgAdmin**
2. **Conectar al servidor PostgreSQL**
   - Click derecho en "Servers" → "Create" → "Server"
   - Name: `Unite Speed DB`
   - Host: `localhost`
   - Port: `5432`
   - Database: `delivery_db`
   - Username: `postgres`
   - Password: [tu contraseña]

3. **Ejecutar el script**
   - Navegar a: `Servers` → `Unite Speed DB` → `Databases` → `delivery_db`
   - Click derecho en `delivery_db` → "Query Tool"
   - Abrir archivo: `File` → `Open` → Seleccionar `TRACKING_SETUP.sql`
   - Presionar `F5` o click en el botón "Execute"

4. **Verificar resultados**
   - En el panel inferior verás los mensajes de éxito
   - Ejecutar: `SELECT * FROM tracking_eventos WHERE id_pedido = 1 ORDER BY orden;`

---

## 🔧 Método 3: Usando DBeaver (GUI)

1. **Abrir DBeaver**
2. **Nueva conexión**
   - Click en "Nueva Conexión" (ícono de enchufe)
   - Seleccionar "PostgreSQL"
   - Host: `localhost`
   - Port: `5432`
   - Database: `delivery_db`
   - Username: `postgres`
   - Password: [tu contraseña]
   - Click "Test Connection" → "Finish"

3. **Ejecutar script**
   - Click derecho en la conexión → "SQL Editor" → "Open SQL Script"
   - Seleccionar `TRACKING_SETUP.sql`
   - Click en "Execute SQL Script" (ícono de play)

4. **Verificar**
   - Navegar a: `delivery_db` → `Schemas` → `public` → `Tables`
   - Deberías ver `tracking_eventos`
   - Click derecho → "View Data"

---

## ✅ Verificación de Instalación Exitosa

Ejecuta esta consulta para confirmar que todo funciona:

```sql
-- Debe devolver 6 filas con las coordenadas de la ruta
SELECT 
    orden,
    latitud,
    longitud,
    descripcion
FROM tracking_eventos
WHERE id_pedido = 1
ORDER BY orden;
```

**Resultado esperado:**
```
orden | latitud  | longitud  | descripcion
------|----------|-----------|---------------------------
  1   | 0.970362 | -79.652557| Saliendo del negocio
  2   | 0.970524 | -79.655029| Avanzando por Av. Principal
  3   | 0.976980 | -79.654840| Pasando por el parque
  4   | 0.983438 | -79.655182| A 2 cuadras del destino
  5   | 0.984854 | -79.657457| A 1 cuadra del destino
  6   | 0.988033 | -79.659094| Llegando al destino
```

---

## 🔄 Cómo Agregar Más Rutas de Tracking

Para agregar tracking a otros pedidos:

```sql
-- Ejemplo: Ruta para pedido #2
INSERT INTO tracking_eventos (id_pedido, orden, latitud, longitud, descripcion) VALUES
(2, 1, 0.971000, -79.653000, 'Inicio pedido 2'),
(2, 2, 0.975000, -79.654000, 'En camino'),
(2, 3, 0.980000, -79.656000, 'Llegando');
```

---

## 🧹 Cómo Limpiar/Resetear Datos

```sql
-- Eliminar todos los datos de tracking
TRUNCATE TABLE tracking_eventos;

-- Eliminar solo tracking de un pedido específico
DELETE FROM tracking_eventos WHERE id_pedido = 1;

-- Eliminar la tabla completa (cuidado!)
DROP TABLE IF EXISTS tracking_eventos CASCADE;
```

---

## 🐛 Solución de Problemas

### Error: "relation tracking_eventos already exists"
**Solución:** La tabla ya existe. Puedes:
- Eliminarla primero: `DROP TABLE tracking_eventos CASCADE;`
- O simplemente insertar datos nuevos

### Error: "permission denied"
**Solución:** Asegúrate de usar el usuario correcto:
```bash
psql -U postgres -d delivery_db
```

### Error: "database delivery_db does not exist"
**Solución:** Crear la base de datos primero:
```sql
CREATE DATABASE delivery_db;
```

### Error: "password authentication failed"
**Solución:** Verifica la contraseña en tu archivo `.env` (variable `DB_PASSWORD`)

---

## 📊 Consultas Útiles para Monitoreo

```sql
-- Ver todos los pedidos con tracking
SELECT DISTINCT id_pedido FROM tracking_eventos;

-- Contar puntos por pedido
SELECT id_pedido, COUNT(*) as total_puntos 
FROM tracking_eventos 
GROUP BY id_pedido;

-- Ver último punto registrado de cada pedido
SELECT DISTINCT ON (id_pedido) 
    id_pedido, 
    orden, 
    latitud, 
    longitud, 
    descripcion,
    fecha_evento
FROM tracking_eventos
ORDER BY id_pedido, orden DESC;

-- Ver tracking de las últimas 24 horas
SELECT * FROM tracking_eventos 
WHERE fecha_evento > NOW() - INTERVAL '24 hours'
ORDER BY fecha_evento DESC;
```

---

## 🔗 Integración con la API

Una vez ejecutado el script, estos endpoints funcionarán:

- **GET** `http://18.217.51.221:7070/tracking/pedido/1/ruta`
  - Devuelve todos los puntos de tracking del pedido #1

- **GET** `http://18.217.51.221:7070/tracking/pedido/1`
  - Devuelve la ubicación actual del repartidor

- **PUT** `http://18.217.51.221:7070/ubicaciones/repartidor/{idRepartidor}`
  - Actualiza la posición GPS del repartidor

---

## 📱 Prueba desde la App Flutter

1. Ejecuta el script SQL
2. Reinicia el backend (si está corriendo)
3. En la app, ve a "Historial de Pedidos"
4. Selecciona un pedido
5. Click en "Ver Tracking"
6. Deberías ver el mapa con la ruta animada

---

## 📝 Notas Importantes

- ✅ El script usa `ON CONFLICT DO NOTHING` para evitar duplicados
- ✅ Los datos de ejemplo son para Esmeraldas, Ecuador
- ✅ La tabla se elimina automáticamente si se borra un pedido (CASCADE)
- ✅ Los timestamps se guardan automáticamente
- ✅ Los índices optimizan las consultas de tracking

---

## 🆘 Soporte

Si tienes problemas:
1. Verifica que PostgreSQL esté corriendo: `pg_ctl status`
2. Revisa los logs del backend en `delivery-api/logs/`
3. Confirma las credenciales en `.env`
4. Prueba la conexión: `psql -U postgres -d delivery_db -c "SELECT 1;"`
