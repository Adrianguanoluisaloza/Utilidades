# Backend API - Unite Speed 7 Delivery

API REST desarrollada con Java Spring Boot para el sistema de delivery.

## 🔧 Tecnologías

- Java 17
- Spring Boot 3.2
- MySQL 8.0
- Maven 3.6+
- Gemini AI API

## 📋 Requisitos

- JDK 17 o superior
- Maven 3.6+
- MySQL 8.0+
- Cuenta de Gemini AI (para chat bot)

## ⚙️ Configuración

### 1. Variables de Entorno

Copiar `.env.example` a `.env` y configurar:

```bash
cp .env.example .env
```

Editar `.env` con tus credenciales:

```properties
DB_HOST=localhost
DB_PORT=3306
DB_NAME=delivery_db
DB_USER=tu_usuario
DB_PASSWORD=tu_password
GEMINI_API_KEY=tu_api_key_gemini
```

### 2. Base de Datos

Crear base de datos:

```sql
CREATE DATABASE delivery_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Ejecutar schema:

```bash
mysql -u root -p delivery_db < database/SCHEMA_COMPLETO_UNIFICADO.sql
```

### 3. Configuración de application.properties

Editar `src/main/resources/application.properties`:

```properties
server.port=7070

spring.datasource.url=jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASSWORD}

gemini.api.key=${GEMINI_API_KEY}
```

## 🚀 Compilación y Ejecución

### Desarrollo

```bash
mvn clean install
mvn spring-boot:run
```

### Producción

```bash
mvn clean package
java -jar target/delivery-api-1.0-SNAPSHOT.jar
```

### Docker

```bash
docker build -t delivery-api .
docker run -p 7070:7070 --env-file .env delivery-api
```

## 📡 Endpoints Principales

### Autenticación
- `POST /auth/login` - Iniciar sesión
- `POST /auth/registro` - Registrar usuario

### Productos
- `GET /productos` - Listar productos
- `GET /productos/{id}` - Detalle de producto
- `POST /productos` - Crear producto (Admin)
- `PUT /productos/{id}` - Actualizar producto (Admin)

### Pedidos
- `GET /pedidos` - Listar pedidos
- `POST /pedidos` - Crear pedido
- `PUT /pedidos/{id}/estado` - Actualizar estado

### Chat
- `POST /chat/bot/mensajes` - Chat con IA
- `POST /soporte/mensaje` - Chat con soporte

### Ubicaciones
- `GET /ubicacion/usuario/{id}` - Ubicaciones de usuario
- `POST /ubicacion` - Guardar ubicación

## 🔐 Seguridad

- Autenticación JWT
- Validación de roles
- Sanitización de inputs
- Rate limiting

## 📊 Estructura del Proyecto

```
src/main/java/com/mycompany/delivery/api/
├── config/          # Configuración
├── controller/      # Controladores REST
├── model/           # Modelos de datos
├── repository/      # Acceso a datos
├── services/        # Lógica de negocio
└── util/            # Utilidades
```

## 🧪 Testing

```bash
mvn test
```

## 📝 Notas

- El puerto por defecto es 7070
- La API requiere MySQL corriendo
- Gemini API Key es necesaria para el chat bot
- Los logs se guardan en `logs/`

## 🐛 Troubleshooting

### Error de conexión a MySQL
```bash
# Verificar que MySQL esté corriendo
systemctl status mysql

# Verificar credenciales en .env
```

### Error de Gemini API
```bash
# Verificar API key en .env
# Verificar cuota de API en Google Cloud Console
```

## 📄 Licencia

Proyecto privado - Unite Speed © 2024
