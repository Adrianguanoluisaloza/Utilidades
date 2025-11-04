# 🚀 Unite Speed 7 Delivery

Sistema completo de delivery con IA para Esmeraldas, Ecuador.

## 📦 Componentes

### App Móvil Flutter
- Flutter/Dart multiplataforma (Android & iOS)
- Chat con IA integrada
- Tracking GPS en tiempo real
- Sistema de roles: Cliente, Delivery, Negocio, Admin, Soporte

### Backend API
- Java Spring Boot
- MySQL Database
- API REST completa
- Integración con IA para recomendaciones

### Landing Page
- HTML/CSS/JavaScript
- Responsive design
- Carruseles optimizados

## 🔧 Instalación

### Requisitos
- Flutter SDK 3.0+
- Java 17+
- MySQL 8.0+
- Maven 3.6+

### App Flutter

```bash
cd sspeed
flutter pub get
flutter run
```

### Backend API

```bash
cd sspeed/backends/delivery-api
mvn clean package
java -jar target/delivery-api-1.0.jar
```

### Configuración Base de Datos

```sql
CREATE DATABASE delivery_db;
-- Importar schema desde: sspeed/backends/delivery-api/schema.sql
```

## 📱 Características

### Clientes
- Explorar productos con carrusel
- Carrito de compras
- Realizar pedidos
- Chat con IA
- Tracking de pedidos
- Calificar productos

### Delivery
- Ver pedidos disponibles
- Aceptar entregas
- GPS tracking automático
- Chat con clientes
- Estadísticas

### Negocios
- Gestionar productos
- Ver pedidos
- Estadísticas de ventas

### Admin
- Panel de control
- Gestión de usuarios
- Monitoreo del sistema

### Soporte
- Atención a usuarios
- Chat con respuestas predefinidas

## 🚀 Compilación

### APK Android

```bash
cd sspeed
flutter build apk --split-per-abi
```

Genera 3 APKs optimizados:
- `app-armeabi-v7a-release.apk` (dispositivos antiguos)
- `app-arm64-v8a-release.apk` (recomendado)
- `app-x86_64-release.apk` (emuladores)

### Backend JAR

```bash
cd sspeed/backends/delivery-api
mvn clean package
```

Genera: `target/delivery-api-1.0.jar`

## 🗂️ Estructura

```
sspeed/
├── lib/                    # Código Flutter
│   ├── screen/            # Pantallas
│   ├── delivery/          # Módulo delivery
│   ├── negocio/           # Módulo negocios
│   ├── admin/             # Módulo admin
│   └── soporte/           # Módulo soporte
├── backends/
│   └── delivery-api/      # Backend Spring Boot
├── assets/                # Recursos
└── android/ios/           # Configuración nativa
```

## ⚙️ Configuración

### Backend (application.properties)

```properties
server.port=7070
spring.datasource.url=jdbc:mysql://localhost:3306/delivery_db
spring.datasource.username=TU_USUARIO
spring.datasource.password=TU_PASSWORD
```

### Flutter (lib/main.dart)

```dart
// Cambiar URL base de la API
static const String baseUrl = 'http://TU_SERVIDOR:7070';
```

## 📊 Optimizaciones

- Carrusel: Timeout 3s, animaciones 200ms
- GPS: Tracking optimizado cada 2 horas
- Cache: 5 minutos en endpoints frecuentes
- Imágenes: Sistema de cache optimizado

## 🔐 Seguridad

- Autenticación JWT
- Roles y permisos
- Validación de datos
- Comunicación segura

## 📝 Testing

```bash
# Flutter
flutter test

# Backend
mvn test
```

## 🐛 Troubleshooting

### Error de conexión
- Verificar que el backend esté corriendo
- Revisar URL en configuración

### GPS no funciona
- Activar permisos de ubicación
- Solo funciona en dispositivos físicos

## 📄 Licencia

Proyecto privado - Unite Speed © 2024

---

**Versión:** 1.0.0  
**Desarrollado para:** Esmeraldas, Ecuador
