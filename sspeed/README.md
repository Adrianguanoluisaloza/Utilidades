# 🚀 Unite Speed 7 Delivery

Sistema completo de delivery con IA para Esmeraldas, Ecuador.

## 📦 Componentes del Sistema

### 1. App Móvil Flutter (Este Repositorio)
- Flutter/Dart multiplataforma
- Android & iOS
- Chat con IA (Gemini)
- Tracking GPS en tiempo real
- 5 roles: Cliente, Delivery, Negocio, Admin, Soporte

### 2. Backend API
- Java Spring Boot
- MySQL en AWS RDS
- API REST completa
- Integración con Gemini AI
- **URL:** http://18.217.51.221:7070

### 3. Landing Page
- HTML/CSS/JavaScript puro
- GitHub Pages
- Carruseles de productos y opiniones
- **URL:** https://unitesspeed7delivery.netlify.app

## 🔧 Instalación

### Requisitos
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / Xcode
- Dispositivo Android/iOS o emulador

### Configuración

```bash
# Clonar repositorio
git clone [URL_REPOSITORIO_PRIVADO]
cd sspeed

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Compilar APK release
flutter build apk --split-per-abi
```

## 📱 Características Principales

### Para Clientes
- Explorar productos con carrusel optimizado
- Agregar al carrito y realizar pedidos
- Chat con IA para recomendaciones
- Tracking de pedidos en tiempo real
- Calificar productos y delivery

### Para Delivery
- Ver pedidos disponibles
- Aceptar y gestionar entregas
- GPS tracking automático
- Chat con clientes
- Estadísticas de entregas

### Para Negocios
- Gestionar productos
- Ver pedidos recibidos
- Estadísticas de ventas
- Chat con clientes

### Para Admin
- Panel de control completo
- Gestión de usuarios
- Monitoreo del sistema
- Reportes y métricas

### Para Soporte
- Atención a usuarios
- Chat con respuestas predefinidas
- Gestión de tickets

## 🌐 Endpoints API

- **Base URL:** http://18.217.51.221:7070
- **Auth:** `/auth/login`, `/auth/registro`
- **Productos:** `/productos/*`
- **Pedidos:** `/pedidos/*`
- **Chat IA:** `/chat/bot/mensajes`
- **Soporte:** `/soporte/mensaje`
- **GPS:** `/ubicacion/*`

## 👥 Credenciales de Prueba

```
Cliente:  cliente@test.com / 123456
Delivery: delivery@test.com / 123456
Negocio:  negocio@test.com / 123456
Admin:    admin@test.com / admin123
Soporte:  soporte@test.com / 123456
```

## 🚀 Compilación Release

```bash
# APKs optimizados por arquitectura
flutter build apk --split-per-abi

# Salida en: build/app/outputs/flutter-apk/
# - app-armeabi-v7a-release.apk (20.1 MB)
# - app-arm64-v8a-release.apk (22.2 MB) ← Recomendado
# - app-x86_64-release.apk (23.4 MB)
```

## 📊 Optimizaciones Implementadas

- **Carrusel:** Timeout 3s, animaciones 200ms, cache optimizado
- **GPS:** Tracking cada 2 horas (ahorro de batería)
- **Imágenes:** Cache con S3 bucket AWS
- **Backend:** Cache 5 minutos en endpoints destacados
- **Performance:** 500x mejora en consultas frecuentes

## 🗂️ Estructura del Proyecto

```
lib/
├── screen/           # Pantallas principales
│   ├── home_screen.dart
│   ├── chat_screen.dart
│   ├── product_detail_screen.dart
│   ├── checkout_screen.dart
│   └── ...
├── delivery/         # Módulo delivery
├── negocio/          # Módulo negocios
├── admin/            # Módulo admin
├── soporte/          # Módulo soporte
└── main.dart         # Entry point
```

## 🔐 Seguridad

- Autenticación JWT
- Roles y permisos
- Validación de datos
- Comunicación HTTPS
- Tokens en SharedPreferences

## 📝 Testing

```bash
# Tests unitarios
flutter test

# Tests de integración
flutter test integration_test/

# Análisis de código
flutter analyze
```

## 🐛 Troubleshooting

### Error de conexión API
- Verificar que el backend esté corriendo en http://18.217.51.221:7070
- Revisar conexión a internet

### Imágenes no cargan
- Verificar acceso a S3: http://unitespeed-landing-2025.s3-website.us-east-2.amazonaws.com

### GPS no funciona
- Activar permisos de ubicación en el dispositivo
- Solo funciona en dispositivos físicos (no emuladores sin GPS)

## 📄 Documentación Completa

Ver carpeta `DOCUMENTACION_FINAL/` en el proyecto principal para:
- Diagramas de arquitectura
- Guías de deployment
- Credenciales AWS
- Flujos de pedidos
- Manual de usuario

## 📞 Soporte

- **Email:** soporte@unitespeed.com
- **Chat:** Dentro de la app
- **Documentación:** Ver `DOCUMENTACION_FINAL/`

## 📄 Licencia

Proyecto privado - Unite Speed © 2024

---

**Versión:** 1.0.0  
**Última actualización:** 2024  
**Desarrollado para:** Esmeraldas, Ecuador
