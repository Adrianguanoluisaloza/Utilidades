# 🚀 INSTRUCCIONES DE USO - DEPLOY COMPLETO

## 📋 Descripción

`DEPLOY_COMPLETO.bat` es un script unificado e interactivo que te permite gestionar todo el ciclo de deploy del backend Unite Speed Delivery API.

## ⚙️ Configuración

El script está preconfigurado con:
- **Proyecto**: `c:\Users\Adrian\Proyecto\sspeed\backends\delivery-api`
- **Llave SSH**: `C:\Users\Adrian\Videos\finalidad.pem`
- **Servidor AWS**: `ubuntu@18.217.51.221`
- **Base de Datos RDS**: `databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com`
- **Usuario DB**: `Michael`
- **Contraseña DB**: `Unidos2025!`

## 🎮 Cómo Usar

### Ejecutar el script

```bash
cd c:\Users\Adrian\Proyecto\sspeed\backends\delivery-api
deploy\DEPLOY_COMPLETO.bat
```

### Menú de Opciones

#### 🔵 DEPLOY
- **[1] Deploy Completo**: Compila el proyecto, sube el JAR a AWS, reinicia el contenedor y verifica el estado
- **[2] Solo Compilar**: Ejecuta `mvn clean package` sin subir a AWS
- **[3] Solo Subir a AWS**: Sube el JAR ya compilado y reinicia el contenedor

#### 🗄️ BASE DE DATOS
- **[7] Aplicar Schema Completo**: Ejecuta `SCHEMA_COMPLETO_UNIFICADO.sql` en RDS (⚠️ BORRA TODOS LOS DATOS)
- **[8] Insertar Datos de Ejemplo**: Inserta respuestas de soporte, tracking, opiniones y datos completos
- **[9] Crear Usuario Admin**: Crea un usuario administrador interactivamente

#### 📊 MONITOREO
- **[4] Verificar Estado**: Prueba `/health`, `/productos` y estado del contenedor Docker
- **[5] Ver Logs del Contenedor**: Muestra los últimos 50 logs en tiempo real
- **[6] Mover JAR antiguos**: Mueve los JAR del target a `old/` con fecha

#### 🚪 SALIR
- **[0] Salir**: Cierra el script

## 📝 Flujo de Trabajo Recomendado

### 1️⃣ Primer Deploy (proyecto nuevo)
```
1. Ejecutar [7] - Aplicar Schema Completo (crea todas las tablas)
2. Ejecutar [8] - Insertar Datos de Ejemplo (pobla las tablas)
3. Ejecutar [9] - Crear Usuario Admin (crear tu usuario)
4. Ejecutar [1] - Deploy Completo (compilar y subir)
```

### 2️⃣ Deploy Regular (cambios en código)
```
1. Ejecutar [6] - Mover JAR antiguos (opcional, mantener backup)
2. Ejecutar [1] - Deploy Completo
3. Ejecutar [4] - Verificar Estado (confirmar que funciona)
```

### 3️⃣ Solo Actualizar Base de Datos
```
1. Ejecutar [7] - Aplicar Schema Completo (si cambió la estructura)
   O
   Ejecutar [8] - Insertar Datos (si solo necesitas datos nuevos)
```

### 4️⃣ Debugging
```
1. Ejecutar [4] - Verificar Estado (ver si responde)
2. Ejecutar [5] - Ver Logs (revisar errores)
```

## 🔧 Scripts Organizados

Los scripts antiguos se movieron a:
- `scripts/DEPLOY_NUEVO.bat` - Deploy antiguo sin AWS
- `scripts/update_server_old.bat` - Script AWS antiguo

**Recomendación**: Usa solo `DEPLOY_COMPLETO.bat` para evitar confusión.

## ⚠️ Advertencias Importantes

### Base de Datos
- ⚠️ **[7] Aplicar Schema Completo** ELIMINA TODOS LOS DATOS. Usa con cuidado en producción.
- ✅ **[8] Insertar Datos** es seguro, usa `ON CONFLICT DO NOTHING` para evitar duplicados.
- ✅ **[9] Crear Usuario Admin** es idempotente, actualiza si ya existe.

### Deploy
- 🔑 Asegúrate de que la llave SSH `finalidad.pem` esté en `C:\Users\Adrian\Videos\`
- 🌐 Verifica que puedas conectarte a AWS: `ssh -i C:\Users\Adrian\Videos\finalidad.pem ubuntu@18.217.51.221`
- ☕ La compilación de Maven toma ~10 segundos
- 🚀 El reinicio del contenedor toma ~5 segundos

### JAR
- 📦 El JAR se genera en: `target/delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar`
- 💾 Los JARs antiguos se guardan en: `old/delivery-api-*.jar` con fecha
- 🗂️ Usa la opción [6] antes de compilar para mantener backups

## 🔍 Verificación de Éxito

### Deploy Exitoso
Deberías ver:
```
✅ Compilación exitosa
✅ JAR subido correctamente
✅ Contenedor reiniciado
{"uptimeMs":..., "db":{"connected":true}, "status":"UP"}
```

### Base de Datos Exitosa
```
✅ Schema aplicado correctamente
✅ Datos completos insertados
✅ Usuario administrador creado exitosamente
```

## 🆘 Solución de Problemas

### Error: "No se encontró el JAR"
**Solución**: Ejecuta primero la opción [2] para compilar

### Error: "Falló la subida del JAR"
**Solución**: Verifica la conexión SSH: `ssh -i C:\Users\Adrian\Videos\finalidad.pem ubuntu@18.217.51.221 echo OK`

### Error: "No se pudo actualizar el contenedor"
**Solución**: Conéctate manualmente y reinicia:
```bash
ssh -i C:\Users\Adrian\Videos\finalidad.pem ubuntu@18.217.51.221
sudo docker restart delivery-api
```

### Error: "Database connection refused"
**Solución**: Verifica que el RDS esté activo y las credenciales sean correctas

### Los logs no se actualizan
**Solución**: Presiona `Ctrl+C` en la opción [5] y vuelve al menú

## 📚 Archivos SQL Incluidos

### Database (Schema)
- `database/SCHEMA_COMPLETO_UNIFICADO.sql` - Schema completo (usada en opción 7)
- `database/TRACKING_SETUP.sql` - Setup de tracking GPS
- `database/OPINIONES_SETUP.sql` - Setup de opiniones/reviews
- `database/DATOS_COMPLETOS_SETUP.sql` - Datos de ejemplo completos

### SQL (Seeds y Utilities)
- `sql/insert_respuestas_soporte.sql` - Respuestas predefinidas de soporte
- `sql/seed_usuario_adrian.sql` - Crear usuario admin (usada en opción 9)
- `sql/rebuild_database.sql` - Rebuild completo (alternativa a schema)
- `sql/test_chatbot.sql` - Tests del chatbot con IA

## 🌐 Endpoints de la API

Después del deploy, la API estará disponible en:
- Health: `http://18.217.51.221:7070/health`
- Productos: `http://18.217.51.221:7070/productos`
- Chat Bot: `http://18.217.51.221:7070/chat/bot/mensajes`
- Conversaciones: `http://18.217.51.221:7070/chat/conversaciones/{id}/mensajes`

## 📞 Contacto

- **CEO**: Michael Ortiz
- **Developer**: Adrian
- **Proyecto**: Unite Speed Delivery
- **Repo**: github.com/Adrianguanoluisaloza/sspeed

---

**Última actualización**: 8 de noviembre de 2025
