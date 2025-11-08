# 🚀 UNITE SPEED DELIVERY - GESTOR DE SISTEMA v2.0

## 📋 Descripción
Sistema completo de gestión para Unite Speed Delivery con **interfaz gráfica visual**.

### 🆕 NUEVA VERSIÓN GUI
Ahora incluye una **aplicación GUI completa** con interfaz visual moderna que permite:
- 🎨 Interfaz visual con pestañas organizadas
- 🧪 Prueba de **TODOS los endpoints** (35+) en tabla visual
- 🔑 Generación automática de tokens para todos los roles
- 📊 Resultados en tabla con códigos de colores (OK/FAIL)
- 💾 Exportar reportes a HTML
- 🔄 Gestión de API, BD, Logs desde GUI
- 📱 Portable - funciona en cualquier PC con Python

### Versiones Disponibles
- **GUI v2.0** (Recomendado): Interfaz visual completa → `EJECUTAR_GUI.bat`
- **CLI v1.0**: Línea de comandos → `EJECUTAR.bat`

## 🎯 Características GUI v2.0
✅ Interfaz visual moderna con Tkinter  
✅ Prueba automática de **35+ endpoints** organizados por categoría  
✅ Tokens automáticos para: cliente, admin, delivery, negocio, soporte  
✅ Tabla de resultados con colores: 🟢 OK / 🔴 FAIL  
✅ Exportar reportes a HTML con detalles completos  
✅ Reiniciar API, Health Check, Deploy desde GUI  
✅ Gestión de Base de Datos con queries visuales  
✅ Ver logs del contenedor en tiempo real  
✅ Configuración editable desde la aplicación  

## 📁 Estructura
```
UniteSpeed-Manager/
├── unite_speed_gui.py       # ⭐ NUEVA Aplicación GUI v2.0
├── gestor_unitespeed.py     # Aplicación CLI v1.0
├── config/
│   └── config.json          # Configuración centralizada
├── EJECUTAR_GUI.bat         # ⭐ NUEVO Launcher GUI
├── EJECUTAR.bat             # Launcher CLI
└── README.md                # Este archivo
```

## ⚙️ Configuración

### 1. Editar `config/config.json`
Todos los datos de acceso están en un solo archivo:
```json
{
  "aws": {
    "ec2": {
      "host": "18.217.51.221",
      "user": "ubuntu",
      "pem_path": "D:\\Users\\Adrian\\Downloads\\finalidad.pem"
    },
    "rds": {
      "host": "databasefinal.c9yhjq8aqnxz.us-east-2.rds.amazonaws.com",
      "user": "Michael",
      "password": "XxM7pYbQvtmOo3YdAbYs",
      "database": "final"
    }
  },
  "api": {
    "base_url": "http://18.217.51.221:7070/api",
    "docker_container": "delivery-api"
  },
  "test_users": {
    "cliente": {
      "email": "carlos.cliente@example.com",
      "password": "Cliente123!"
    },
    "admin": {
      "email": "ana.admin@example.com",
      "password": "Admin123!"
    },
    "delivery": {
      "email": "pablo.delivery@example.com",
      "password": "Delivery123!"
    }
  }
}
```

### 2. Verificar PuTTY/SSH
Asegúrate de tener instalado:
- **OpenSSH** (Windows 10+) o
- **PuTTY** con `plink.exe` en el PATH

## 🚀 Uso

### ⭐ Opción 1: GUI v2.0 (RECOMENDADO)
```bash
EJECUTAR_GUI.bat
```
Se abrirá la aplicación visual completa con todas las funciones.

### Opción 2: CLI v1.0
```bash
EJECUTAR.bat
```

### Opción 3: Verificar Base de Datos
```bash
VERIFICAR_BD.bat
```
Ejecuta scripts para verificar estructura y datos de prueba en PostgreSQL.

### Opción 4: Ejecutar con Python directamente
```bash
# GUI
python unite_speed_gui.py

# CLI
python gestor_unitespeed.py
```

## 📖 Funciones GUI v2.0

### 🧪 Pestaña: Pruebas de Endpoints
**35+ endpoints organizados en tabla visual:**

#### Autenticación (4)
- POST /auth/login - Login
- POST /auth/registro - Registro
- POST /auth/reset/generar - Reset Password
- PUT /auth/cambiar-password - Cambiar Password

#### Health (1)
- GET /health - Health Check

#### Productos (3)
- GET /productos - Listar Productos
- GET /productos/{id} - Detalle Producto
- POST /admin/productos - Crear Producto

#### Pedidos (4)
- GET /pedidos/cliente/{id} - Pedidos de Cliente
- GET /pedidos/negocio/{id} - Pedidos de Negocio
- GET /pedidos/delivery/{id} - Pedidos de Delivery
- POST /pedidos - Crear Pedido

#### Ubicaciones (2)
- GET /ubicaciones/usuario/{id} - Ubicaciones de Usuario
- POST /ubicaciones - Crear Ubicación

#### Tracking (2)
- GET /tracking/pedido/{id} - Tracking de Pedido
- GET /tracking/pedido/{id}/ruta - Ruta de Pedido

#### Chat (2)
- POST /chat/bot/mensajes - Chat Bot IA
- GET /chat/conversaciones/{id} - Conversaciones

#### Usuarios (2)
- GET /usuarios/{id} - Detalle de Usuario
- GET /usuarios - Listar Usuarios

#### Recomendaciones (1)
- POST /recomendaciones/productos - Recomendaciones IA

**Controles:**
- 🔑 Selector de rol (cliente/admin/delivery/negocio/soporte)
- 🔑 Botón "Obtener Token" - Genera token automáticamente
- ▶️ Botón "Probar TODOS" - Ejecuta todas las pruebas
- 💾 Botón "Exportar" - Guarda reporte HTML

**Resultados en Tabla:**
- Columnas: #, Método, Endpoint, Descripción, Status, Resultado, Tiempo
- Colores: 🟢 Verde (OK) | 🔴 Rojo (FAIL) | 🟡 Amarillo (SKIP)
- Tiempos de respuesta en milisegundos

### 🔄 Pestaña: API & Deploy
- 🔄 Reiniciar Contenedor Docker
- ❤️ Health Check visual
- 🚀 Deploy Completo
- 📋 Salida de logs en tiempo real

### 🗄️ Pestaña: Base de Datos
- 📋 Ver Tablas
- 👥 Ver Usuarios
- 📦 Ver Productos
- 🛍️ Ver Pedidos
- ▶️ Ejecutar queries SQL personalizados
- Resultados en consola visual

### 📋 Pestaña: Logs
- 📄 Últimas 50 líneas
- 📜 Últimas 200 líneas
- 🔄 Actualizar en tiempo real
- Vista con colores de terminal

### ⚙️ Pestaña: Configuración
- Ver configuración JSON actual
- 🔄 Recargar config.json
- 📝 Editar archivo directamente

## 🔧 Requisitos Técnicos

### Software Necesario
- Python 3.8+
- Librería `requests`: `pip install requests`
- SSH client (OpenSSH o PuTTY)
- Tkinter (incluido con Python en Windows)

### Accesos Requeridos
- Archivo PEM para EC2: `finalidad.pem`
- Credenciales de RDS configuradas en `config.json`
- Acceso SSH al servidor EC2

## 📝 Ejemplos de Uso GUI

### Probar Todos los Endpoints
```
1. Ejecutar EJECUTAR_GUI.bat
2. Ir a pestaña "🧪 Pruebas de Endpoints"
3. Seleccionar rol (ej: cliente)
4. Clic en "🔑 Obtener Token"
5. Clic en "▶ Probar TODOS los Endpoints"
6. Ver resultados en tabla con colores
7. Clic en "💾 Exportar Resultados" para guardar HTML
```

### Reiniciar API desde GUI
```
1. Ir a pestaña "🔄 API & Deploy"
2. Clic en "🔄 Reiniciar Contenedor Docker"
3. Esperar confirmación
4. Clic en "❤️ Health Check" para verificar
```

### Consultar Base de Datos
```
1. Ir a pestaña "🗄️ Base de Datos"
2. Clic en "👥 Ver Usuarios" o escribir query custom
3. Clic en "▶ Ejecutar Query"
4. Ver resultados en consola
```

### Ver Logs del Sistema
```
1. Ir a pestaña "📋 Logs"
2. Clic en "📄 Últimas 50 líneas"
3. Ver logs con colores
4. Clic en "🔄 Actualizar" para refrescar
```

## 🎨 Códigos de Colores GUI
- 🟢 **Verde**: Endpoint OK (200-299)
- 🔴 **Rojo**: Endpoint FAIL (400+)
- 🟡 **Amarillo**: Skip/Advertencia
- 🔵 **Azul**: Información
- ⚫ **Gris oscuro**: Fondo de consolas

## 🔒 Seguridad
⚠️ **IMPORTANTE**:
- NO subir `config.json` a repositorios públicos
- Mantener `finalidad.pem` privado
- Las contraseñas están en texto plano solo para desarrollo

## 📞 Soporte
Si tienes problemas:
1. Verificar que Python está instalado
2. Verificar acceso SSH al servidor
3. Verificar que el archivo PEM tiene permisos correctos
4. Revisar los logs del sistema
5. Ejecutar con Python directamente para ver errores

## 🆕 Changelog
### v2.0.0 (2024) - GUI COMPLETA
- ⭐ **NUEVO**: Interfaz gráfica completa con Tkinter
- ⭐ **NUEVO**: Prueba de 35+ endpoints en tabla visual
- ⭐ **NUEVO**: Tokens automáticos para todos los roles
- ⭐ **NUEVO**: Exportar reportes a HTML
- ⭐ **NUEVO**: Gestión visual de API, BD, Logs
- ⭐ **NUEVO**: Configuración editable desde GUI

### v1.0.0 (2024) - CLI
- ✅ Gestión completa del API por CLI
- ✅ Pruebas automáticas de endpoints
- ✅ Gestión de base de datos
- ✅ Visualización de logs
- ✅ Configuración centralizada

## 🛠️ Instalación

### 1. Instalar Python 3.7+
Si no tienes Python, descárgalo de [python.org](https://www.python.org/)

### 2. Instalar dependencias
```cmd
pip install requests
```

### 3. Configurar claves SSH
Copia tu archivo `.pem` a la ruta configurada en `config/config.json`:
```
D:\Users\Adrian\Downloads\finalidad.pem
```

O edita `config/config.json` y ajusta la ruta a donde tengas tu clave.

### 4. Instalar cliente SSH
- **Windows:** Instala OpenSSH o usa PuTTY
- **Linux/Mac:** Ya incluido

## 🚀 Uso

### Ejecutar desde cualquier ubicación

```cmd
python D:\Users\Adrian\Proyecto\UniteSpeed-Manager\gestor_unitespeed.py
```

O navega a la carpeta y ejecuta:

```cmd
cd D:\Users\Adrian\Proyecto\UniteSpeed-Manager
python gestor_unitespeed.py
```

### Menú principal

```
╔═══════════════════════════════════════════════════════════╗
║     UNITE SPEED DELIVERY - GESTOR UNIFICADO v1.0         ║
╚═══════════════════════════════════════════════════════════╝

1. 🔄 Reiniciar API
2. 🧪 Probar Endpoints
3. 🚀 Deploy API a AWS
4. 🗄️  Gestionar Base de Datos
5. 📋 Ver Logs del API
6. ⚙️  Ver Configuración
0. ❌ Salir
```

## 📁 Estructura

```
UniteSpeed-Manager/
├── gestor_unitespeed.py   # Aplicación principal
├── config/
│   └── config.json         # Configuración centralizada
├── scripts/                # Scripts auxiliares
├── logs/                   # Logs guardados
└── reportes/               # Reportes de pruebas
```

## ⚙️ Configuración

El archivo `config/config.json` contiene todas las credenciales y configuraciones:

```json
{
  "aws": {
    "ec2": {
      "host": "18.217.51.221",
      "user": "ubuntu",
      "pem_path": "D:\\Users\\Adrian\\Downloads\\finalidad.pem"
    },
    "rds": {
      "host": "databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com",
      "user": "Michael",
      "password": "XxM7pYbQvtmOo3YdAbYs",
      "database": "databasefinal"
    }
  },
  "test_users": {
    "cliente": {
      "email": "carlos.cliente@example.com",
      "password": "Cliente123!"
    }
  }
}
```

**Ventaja:** Puedes copiar esta carpeta a cualquier PC, ajustar solo la ruta del `.pem` y funcionará inmediatamente.

## 📋 Funciones

### 1. Reiniciar API
- Reinicia el contenedor Docker `delivery-api` en EC2
- Espera 8 segundos para estabilización
- Verifica que el servicio esté activo

### 2. Probar Endpoints
- Obtiene token JWT automáticamente
- Prueba endpoints clave (health, productos, pedidos, chat bot)
- Genera reporte con timestamp
- Muestra OK/FAIL en colores

### 3. Deploy API
- (En desarrollo) Compilará con Maven y subirá JAR a EC2
- Reiniciará el contenedor automáticamente

### 4. Gestionar BD
- Ver tablas de la base de datos
- Ejecutar queries SQL personalizados
- Backup/Restore (en desarrollo)
- Conectar con MySQL CLI interactivo

### 5. Ver Logs
- Últimas 50/200 líneas del contenedor
- Seguir logs en tiempo real
- Guardar logs a archivo

### 6. Ver Configuración
- Muestra todas las credenciales cargadas
- Verifica rutas de archivos
- Info de conexiones

## 🔐 Seguridad

- **NO subir** `config.json` a Git (ya está en `.gitignore`)
- Las credenciales se cargan automáticamente desde el archivo
- La clave `.pem` debe tener permisos seguros

## 🌐 Uso desde otra PC

1. Copia la carpeta `UniteSpeed-Manager/` completa
2. Ajusta `config/config.json`:
   - Cambia `pem_path` a la ruta de tu `.pem`
3. Ejecuta `python gestor_unitespeed.py`

¡Listo! No necesitas recordar IPs, usuarios, contraseñas, etc.

## 📝 Notas

- Requiere conexión SSH a la instancia EC2
- Requiere acceso a internet para probar endpoints
- Los reportes se guardan automáticamente en `reportes/`

## 🆘 Troubleshooting

### "No module named 'requests'"
```cmd
pip install requests
```

### "Permission denied (publickey)"
Verifica que la ruta del `.pem` en `config.json` sea correcta.

### "Connection timeout"
Verifica que la instancia EC2 esté activa y el grupo de seguridad permita SSH (puerto 22).

---

**Versión:** 1.0  
**Fecha:** Noviembre 2025  
**Autor:** Unite Speed Team
