# Configuración de la API

## URLs Configuradas

### Desarrollo (localhost)
- **Uso**: Para desarrollo local con el backend corriendo en tu máquina
- **URL**: `http://localhost:7070` o `http://10.0.2.2:7070` (Android emulator)

### Producción (AWS EC2)
- **Uso**: Para conectar a tu servidor desplegado en AWS
- **URL**: `http://18.217.51.221:7070`

---

## Cómo usar cada entorno

### Opción 1: Cambiar manualmente en código (temporal)

En `main.dart`, antes de `runApp()`:

```dart
// Para conectar a AWS
AppConfig.overrideBaseUrl('http://18.217.51.221:7070');

// Para volver a localhost
AppConfig.overrideBaseUrl(null);
```

### Opción 2: Compilar con variables de entorno

#### Para desarrollo (localhost):
```bash
flutter run
```

#### Para producción (AWS):
```bash
flutter run --dart-define=APP_ENV=production
```

#### Con URL personalizada:
```bash
flutter run --dart-define=API_BASE_URL=http://18.217.51.221:7070
```

---

## Verificar configuración actual

La app mostrará en consola al iniciar:
```
📋 Configuración Actual de API
   Entorno: development/production
   Base URL: http://...
```

---

## Para dispositivos físicos Android/iOS

Si usas un dispositivo físico en la misma red WiFi que tu PC:

1. Obtén la IP de tu PC:
   - Windows: `ipconfig` (busca IPv4)
   - Mac/Linux: `ifconfig` (busca inet)

2. Ejecuta:
```bash
flutter run --dart-define=LOCAL_IP=192.168.X.X
```

---

## Notas importantes

- ✅ El backend AWS está en: `http://18.217.51.221:7070`
- ✅ Para producción, considera usar HTTPS con un dominio y certificado SSL
- ✅ El puerto 7070 debe estar abierto en el Security Group de EC2
