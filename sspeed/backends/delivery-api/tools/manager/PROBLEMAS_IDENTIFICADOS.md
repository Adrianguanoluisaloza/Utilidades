# 🚨 PROBLEMAS IDENTIFICADOS EN SISTEMA INTEGRADO

## ❌ **Problema 1: Credenciales Inconsistentes**

### Base de Datos RDS PostgreSQL
**Credenciales REALES (las que funcionan):**
```
Host: databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com
Port: 5432
User: Michael
Password: Unidos2025!
Database: databasefinal
```

### Archivos con credenciales CORRECTAS ✅:
1. `tools/manager/config/config.json` ✅
2. `tools/manager/scripts/actualizar_rol_soporte.py` ✅

### Archivos con credenciales INCORRECTAS ❌:
1. `tools/manager/VERIFICAR_BD.bat` → Usa password: `XxM7pYbQvtmOo3YdAbYs` (INCORRECTA)
2. `src/main/resources/application.properties` → Usa localhost, no RDS (INCORRECTA)

---

## ❌ **Problema 2: Comandos MySQL en lugar de PostgreSQL**

### Archivo: `tools/manager/gestor_unitespeed.py`

**LÍNEAS INCORRECTAS:**
```python
# Línea 223 - usa 'mysql' en lugar de 'psql'
cmd = f"mysql -h {rds['host']} -u {rds['user']} -p{rds['password']} {rds['database']} -e 'SHOW TABLES;'"

# Línea 238 - usa 'mysql'
cmd = f"mysql -h {rds['host']} -u {rds['user']} -p{rds['password']} {rds['database']} -e \"{query}\""

# Línea 251 - usa 'mysql'
cmd = f"mysql -h {rds['host']} -u {rds['user']} -p{rds['password']} {rds['database']}"

# Línea 204 - texto dice "MySQL CLI"
print(f"{Color.BOLD}4.{Color.ENDC} Conectar con MySQL CLI")
```

**DEBE SER:**
```python
# PostgreSQL usa 'psql' y sintaxis diferente
cmd = f"PGPASSWORD={rds['password']} psql -h {rds['host']} -U {rds['user']} -d {rds['database']} -c '\\dt'"

# Query custom
cmd = f"PGPASSWORD={rds['password']} psql -h {rds['host']} -U {rds['user']} -d {rds['database']} -c \"{query}\""

# CLI interactivo
cmd = f"PGPASSWORD={rds['password']} psql -h {rds['host']} -U {rds['user']} -d {rds['database']}"
```

---

## ❌ **Problema 3: Sintaxis SQL Incorrecta**

### MySQL vs PostgreSQL:

| Comando | MySQL | PostgreSQL |
|---------|-------|------------|
| Ver tablas | `SHOW TABLES;` | `\dt` o `SELECT * FROM pg_tables WHERE schemaname='public';` |
| Describir tabla | `DESCRIBE tabla;` | `\d tabla` o `SELECT * FROM information_schema.columns WHERE table_name='tabla';` |
| Ver bases de datos | `SHOW DATABASES;` | `\l` o `SELECT datname FROM pg_database;` |
| Conectar | `mysql -h host -u user -ppassword db` | `PGPASSWORD=pass psql -h host -U user -d db` |

---

## ❌ **Problema 4: Scripts de Usuario**

### `tools/manager/scripts/crear_usuarios_completo.py`
- ✅ Usa requests para llamar API (CORRECTO)
- ❌ Pero la API backend usa localhost, no RDS

### `tools/manager/scripts/crear_usuarios_api.py`
- ❌ No existe en el proyecto
- ❌ Referenciado pero no implementado

---

## ✅ **SOLUCIONES REQUERIDAS**

### 1. Corregir `VERIFICAR_BD.bat`
```bat
set PGPASSWORD=Unidos2025!
```

### 2. Corregir `gestor_unitespeed.py`
- Reemplazar todos los comandos `mysql` por `psql`
- Cambiar sintaxis SQL de MySQL a PostgreSQL
- Actualizar mensajes de "MySQL" a "PostgreSQL"

### 3. Corregir `application.properties`
```properties
DB_URL=jdbc:postgresql://databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com:5432/databasefinal
DB_USER=Michael
DB_PASSWORD=Unidos2025!
```

### 4. Crear `.env` para el backend
```env
PORT=7070
DB_URL=jdbc:postgresql://databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com:5432/databasefinal
DB_USER=Michael
DB_PASSWORD=Unidos2025!
JWT_SECRET=demo-secret
```

---

## 📋 **PRIORIDADES DE CORRECCIÓN**

1. **CRÍTICO** - `gestor_unitespeed.py` (Base de datos no funciona en GUI)
2. **CRÍTICO** - `VERIFICAR_BD.bat` (Password incorrecta)
3. **ALTO** - `application.properties` (Backend usa localhost)
4. **MEDIO** - Crear `.env` para producción
5. **BAJO** - Documentación actualizada

---

## 🧪 **PRUEBAS POST-CORRECCIÓN**

### Test 1: Conexión Directa
```cmd
set PGPASSWORD=Unidos2025!
psql -h databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com -U Michael -d databasefinal -c "SELECT 1;"
```

### Test 2: Ver Tablas
```cmd
set PGPASSWORD=Unidos2025!
psql -h databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com -U Michael -d databasefinal -c "\dt"
```

### Test 3: Ver Usuarios
```cmd
set PGPASSWORD=Unidos2025!
psql -h databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com -U Michael -d databasefinal -c "SELECT email, rol FROM usuarios LIMIT 5;"
```

### Test 4: API Health Check
```cmd
curl http://18.217.51.221:7070/api/health
```

---

## 📊 **ESTADO ACTUAL**

| Componente | Estado | Problema |
|------------|--------|----------|
| GUI Manager | ❌ | Comandos MySQL en lugar de psql |
| VERIFICAR_BD.bat | ❌ | Password incorrecta |
| Backend API | ⚠️ | Usa localhost (pero funciona en AWS por Docker) |
| Config JSON | ✅ | Credenciales correctas |
| Scripts Python | ⚠️ | Algunos correctos, otros no |
| Documentación | ⚠️ | Mezcla MySQL y PostgreSQL |

---

## 🎯 **SIGUIENTE PASO**

Aplicar las correcciones en este orden:
1. `gestor_unitespeed.py` - Cambiar mysql a psql
2. `VERIFICAR_BD.bat` - Corregir password
3. `application.properties` - Apuntar a RDS
4. Crear `.env` con variables de entorno
5. Probar todo el sistema
