# 🚀 UNITE SPEED DELIVERY - SISTEMA INTEGRADO

## 📦 Estructura Completa

```
backends/delivery-api/
├── deploy/
│   ├── DEPLOY_COMPLETO.bat          ⭐ Script de deploy con menú
│   ├── INSTRUCCIONES_USO.md          📖 Guía de deploy
│   ├── ANALISIS_UNITESPEED_MANAGER.md 📊 Análisis de integración
│   └── README.md                     📄 README deploy
│
├── tools/
│   ├── LAUNCHER_INTEGRADO.bat        🎯 LAUNCHER PRINCIPAL ⭐⭐⭐
│   ├── config_correcto.json          ⚙️ Config master
│   └── manager/                      📁 UniteSpeed Manager GUI
│       ├── unite_speed_gui.py        🎨 GUI principal (Tkinter)
│       ├── gestor_unitespeed.py      📟 CLI alternativo
│       ├── EJECUTAR_GUI.bat          🚀 Launcher GUI
│       ├── config/
│       │   └── config.json           ⚙️ Config actualizado
│       ├── scripts/                  📜 Scripts auxiliares
│       ├── reportes/                 📊 Reportes generados
│       └── README.md                 📖 Documentación GUI
│
├── config/
│   └── gui_config.json               ⚙️ Config alternativo
│
├── src/                              💻 Código fuente API
├── target/                           📦 JARs compilados
└── old/                              🗄️ Backups de JARs
```

---

## 🎯 CÓMO USAR EL SISTEMA INTEGRADO

### 🌟 OPCIÓN 1: LAUNCHER INTEGRADO (RECOMENDADO)

```bash
cd c:\Users\Adrian\Proyecto\sspeed\backends\delivery-api\tools
LAUNCHER_INTEGRADO.bat
```

**Menú:**
- **[1] GUI Manager**: Interfaz gráfica para pruebas, BD, logs
- **[2] Deploy Completo**: Script de deploy con base de datos
- **[3] Ambos**: Abre GUI + Deploy simultáneamente
- **[0] Salir**

---

### 🎨 OPCIÓN 2: GUI MANAGER (Pruebas y Gestión)

```bash
cd c:\Users\Adrian\Proyecto\sspeed\backends\delivery-api\tools\manager
EJECUTAR_GUI.bat
```

O ejecutar directamente:
```bash
python unite_speed_gui.py
```

**Características del GUI:**
- ✅ **Pruebas de Endpoints**: 35+ endpoints con tokens automáticos
- 🗄️ **Gestión de BD**: Queries, ver tablas, usuarios, pedidos
- 📋 **Ver Logs**: Logs del contenedor en tiempo real
- 🔄 **Gestión API**: Reiniciar contenedor, health check
- ⚙️ **Configuración**: Ver y editar config.json

---

### 🚀 OPCIÓN 3: DEPLOY COMPLETO (Compilar y Subir)

```bash
cd c:\Users\Adrian\Proyecto\sspeed\backends\delivery-api\deploy
DEPLOY_COMPLETO.bat
```

**Menú de Deploy:**
- **[1]** Deploy Completo (Compilar + Subir a AWS)
- **[2]** Solo Compilar
- **[3]** Solo Subir a AWS
- **[7]** Aplicar Schema de Base de Datos
- **[8]** Insertar Datos de Ejemplo
- **[9]** Crear Usuario Admin
- **[4]** Verificar Estado
- **[5]** Ver Logs
- **[6]** Mover JARs Antiguos

---

## 🔧 CONFIGURACIÓN

### ✅ Config Actualizado y Corregido

Archivo: `tools/manager/config/config.json`

```json
{
  "aws": {
    "ec2": {
      "host": "18.217.51.221",
      "user": "ubuntu",
      "pem_path": "C:\\Users\\Adrian\\Videos\\finalidad.pem"  ✅ CORREGIDO
    },
    "rds": {
      "host": "databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com",
      "port": 5432,  ✅ CORREGIDO (PostgreSQL)
      "user": "Michael",
      "password": "Unidos2025!",  ✅ CORREGIDO
      "database": "databasefinal"
    }
  },
  "api": {
    "base_url": "http://18.217.51.221:7070",  ✅ CORREGIDO (sin /api)
    "docker_container": "delivery-api"
  },
  "paths": {
    "project_dir": "c:\\Users\\Adrian\\Proyecto\\sspeed\\backends\\delivery-api",
    "deploy_script": "c:\\Users\\Adrian\\Proyecto\\sspeed\\backends\\delivery-api\\deploy\\DEPLOY_COMPLETO.bat"
  },
  "test_users": {
    "cliente": { "email": "carlos.cliente@example.com", "password": "Cliente123!" },
    "admin": { "email": "adrian@admin.com", "password": "Admin123!" },  ✅ ACTUALIZADO
    "delivery": { "email": "delivery1@example.com", "password": "Delivery123!" },
    "negocio": { "email": "negocio1@example.com", "password": "Negocio123!" },
    "soporte": { "email": "soporte@example.com", "password": "Soporte123!" }
  }
}
```

---

## 🎨 CARACTERÍSTICAS DEL GUI MANAGER

### 📑 Pestaña 1: Pruebas de Endpoints

**35+ Endpoints Organizados:**
- 🔐 Autenticación (4): login, registro, reset password, cambiar password
- ❤️ Health (1): health check
- 📦 Productos (3): listar, detalle, crear
- 🛍️ Pedidos (4): por cliente, negocio, delivery, crear
- 📍 Ubicaciones (2): listar, crear
- 🗺️ Tracking (2): pedido, ruta
- 💬 Chat (3): bot IA, iniciar, conversaciones
- 👥 Usuarios (2): detalle, listar
- 🤖 Recomendaciones (1): productos IA

**Controles:**
- Selector de rol (cliente/admin/delivery/negocio/soporte)
- Botón "Obtener Token" → genera JWT automático
- Botón "Probar TODOS" → ejecuta todas las pruebas
- Botón "Exportar" → guarda reporte HTML
- Tabla con colores: ✅ Verde (OK) | ❌ Rojo (FAIL)

### 📑 Pestaña 2: API & Deploy

- 🔄 Reiniciar Contenedor Docker
- ❤️ Health Check Visual
- 🚀 Deploy Completo (integrado)
- 📋 Logs en Tiempo Real

### 📑 Pestaña 3: Base de Datos

- 📋 Ver Tablas
- 👥 Ver Usuarios
- 📦 Ver Productos
- 🛍️ Ver Pedidos
- ▶️ Ejecutar Queries SQL Personalizados
- 📊 Resultados en Consola Visual

### 📑 Pestaña 4: Logs

- 📄 Últimas 50 líneas
- 📜 Últimas 200 líneas
- 🔄 Actualizar en Tiempo Real
- 🖥️ Vista con Colores de Terminal

### 📑 Pestaña 5: Configuración

- 👀 Ver Configuración JSON Actual
- 🔄 Recargar config.json
- 📝 Editar Archivo Directamente

---

## 🚀 FLUJO DE TRABAJO RECOMENDADO

### 🆕 Primer Deploy (Proyecto Nuevo)

```bash
1. LAUNCHER_INTEGRADO.bat → [2] Deploy Completo
2. Seleccionar [7] - Aplicar Schema BD
3. Seleccionar [8] - Insertar Datos
4. Seleccionar [9] - Crear Usuario Admin
5. Seleccionar [1] - Deploy Completo

6. LAUNCHER_INTEGRADO.bat → [1] GUI Manager
7. Pestaña "Pruebas de Endpoints"
8. Obtener token y probar todos los endpoints
```

### 🔄 Deploy Regular (Cambios en Código)

```bash
1. LAUNCHER_INTEGRADO.bat → [2] Deploy Completo
2. Seleccionar [6] - Mover JARs Antiguos (backup)
3. Seleccionar [1] - Deploy Completo
4. Seleccionar [4] - Verificar Estado

5. LAUNCHER_INTEGRADO.bat → [1] GUI Manager
6. Health Check para confirmar
```

### 🧪 Pruebas de Endpoints

```bash
1. LAUNCHER_INTEGRADO.bat → [1] GUI Manager
2. Pestaña "Pruebas de Endpoints"
3. Seleccionar rol (ej: cliente)
4. Click "Obtener Token"
5. Click "Probar TODOS los Endpoints"
6. Ver resultados en tabla
7. Click "Exportar Resultados" para guardar HTML
```

### 🗄️ Gestión de Base de Datos

```bash
1. LAUNCHER_INTEGRADO.bat → [2] Deploy Completo
2. Seleccionar [7] - Aplicar Schema (si cambia estructura)
   O
   Seleccionar [8] - Insertar Datos (datos nuevos)

3. LAUNCHER_INTEGRADO.bat → [1] GUI Manager
4. Pestaña "Base de Datos"
5. Ver tablas o ejecutar queries
```

### 🔍 Debugging

```bash
1. LAUNCHER_INTEGRADO.bat → [1] GUI Manager
2. Pestaña "API & Deploy" → Health Check
3. Pestaña "Logs" → Ver últimos logs
4. Si hay error → Pestaña "API & Deploy" → Reiniciar Contenedor
```

---

## 📊 VENTAJAS DEL SISTEMA INTEGRADO

1. ✅ **Todo en un Lugar**: GUI + Deploy + BD en un solo sistema
2. ✅ **Configuración Unificada**: Un solo config.json corregido
3. ✅ **Launcher Central**: Acceso rápido a todas las herramientas
4. ✅ **Pruebas Automatizadas**: 35+ endpoints con reportes
5. ✅ **Deploy Robusto**: Script con base de datos incluida
6. ✅ **Portable**: Copiar carpeta y funciona en cualquier PC
7. ✅ **Documentación Completa**: Guías paso a paso

---

## 🛠️ REQUISITOS

### Software Necesario

- ✅ Python 3.8+
- ✅ `pip install requests` (para GUI)
- ✅ Maven 3.9.11 (para compilar)
- ✅ JDK 21 (para compilar)
- ✅ SSH Client (OpenSSH o PuTTY)
- ✅ Tkinter (incluido con Python en Windows)

### Accesos Requeridos

- ✅ Llave SSH: `C:\Users\Adrian\Videos\finalidad.pem`
- ✅ Acceso a EC2: `ubuntu@18.217.51.221`
- ✅ Acceso a RDS: `databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com:5432`
- ✅ Credenciales de BD: Usuario `Michael`, Password `Unidos2025!`

---

## 🆘 SOLUCIÓN DE PROBLEMAS

### "No module named 'requests'"
```bash
pip install requests
```

### "Permission denied (publickey)"
Verificar ruta de `.pem` en `config.json`:
```bash
"pem_path": "C:\\Users\\Adrian\\Videos\\finalidad.pem"
```

### "Connection timeout"
Verificar que EC2 esté activa:
```bash
ssh -i C:\Users\Adrian\Videos\finalidad.pem ubuntu@18.217.51.221
```

### "No se encontró el JAR"
Ejecutar primero la compilación:
```bash
DEPLOY_COMPLETO.bat → [2] Solo Compilar
```

### "Database connection refused"
Verificar credenciales RDS en `config.json`:
```json
{
  "port": 5432,
  "password": "Unidos2025!"
}
```

---

## 📚 DOCUMENTACIÓN ADICIONAL

- 📖 **Deploy**: `deploy/INSTRUCCIONES_USO.md`
- 📖 **GUI**: `tools/manager/README.md`
- 📊 **Análisis**: `deploy/ANALISIS_UNITESPEED_MANAGER.md`
- 🔐 **Permisos**: `tools/manager/MATRIZ_PERMISOS_ROLES.md`

---

## 🎉 RESUMEN

Este sistema integra:
- 🎨 **GUI Manager** (UniteSpeed-Manager) → Pruebas, BD, Logs, Gestión
- 🚀 **Deploy Completo** (DEPLOY_COMPLETO.bat) → Compilar, Subir, BD
- 🎯 **Launcher Central** (LAUNCHER_INTEGRADO.bat) → Acceso unificado

**Todo configurado, corregido y listo para usar!** 🚀

---

**Fecha**: 8 de noviembre de 2025  
**Versión**: 2.0 Integrado  
**Autor**: Unite Speed Team  
**Proyecto**: Unite Speed Delivery
