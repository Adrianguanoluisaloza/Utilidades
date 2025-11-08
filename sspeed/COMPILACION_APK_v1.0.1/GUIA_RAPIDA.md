# 🔧 Guía Rápida de Compilación

## Comandos esenciales

### 1. Compilar APK release (completo)
```bash
cd c:\Users\Adrian\Proyecto\sspeed
flutter clean
flutter build apk --release
```

### 2. Compilar APK sin limpiar (más rápido)
```bash
cd c:\Users\Adrian\Proyecto\sspeed
flutter build apk --release
```

### 3. Ver APKs generados
```bash
cd c:\Users\Adrian\Proyecto\sspeed\build\app\outputs\flutter-apk
dir *.apk
```

---

## Ubicación de los APKs

Después de compilar, los APKs están en:
```
c:\Users\Adrian\Proyecto\sspeed\build\app\outputs\flutter-apk\
```

### Archivos generados:
- `app-release.apk` → APK universal (todos los dispositivos)
- `app-arm64-v8a-release.apk` → Solo ARM 64-bit (dispositivos modernos)
- `app-armeabi-v7a-release.apk` → Solo ARM 32-bit (dispositivos antiguos)
- `app-x86_64-release.apk` → Solo x86 64-bit (emuladores)

---

## Solución de problemas comunes

### Error: "Cannot find Java installation"
**Solución**: Ya está configurado para Java 21. Asegúrate de tener JDK instalado.

### Error: "Paquete no es válido"
**Solución**: Ya está configurado con firma de release. El APK debería instalar correctamente.

### Error: Gradle se queda sin memoria
**Solución**: Ya configurado con `-Xmx8G` en `gradle.properties`

---

## Actualizar versión

Edita `pubspec.yaml`:
```yaml
version: 1.0.2+3  # Formato: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

Luego recompila:
```bash
flutter build apk --release
```

---

## Instalar APK en dispositivo

### Vía USB (ADB):
```bash
adb install build\app\outputs\flutter-apk\app-release.apk
```

### Vía cable USB (manual):
1. Conectar dispositivo Android
2. Copiar `app-release.apk` al teléfono
3. Abrir archivo en el dispositivo
4. Permitir instalación de fuentes desconocidas
5. Instalar

---

## Generar Android App Bundle (para Google Play)

```bash
flutter build appbundle --release
```

El archivo se genera en:
```
build\app\outputs\bundle\release\app-release.aab
```

---

## Verificar firma del APK

```bash
cd c:\Users\Adrian\Proyecto\sspeed\android\app
keytool -list -v -keystore speed7delivery-release.keystore -alias speed7delivery -storepass speed7delivery2025
```

---

## Scripts de compilación

### Windows Batch Script

Crea `BUILD_APK.bat` en la raíz:
```batch
@echo off
echo ================================
echo   Compilando Speed7Delivery
echo ================================
cd c:\Users\Adrian\Proyecto\sspeed
echo.
echo Limpiando proyecto...
call flutter clean
echo.
echo Compilando APK release...
call flutter build apk --release
echo.
echo ================================
echo   Compilacion completada!
echo ================================
echo.
echo APKs generados en:
echo build\app\outputs\flutter-apk\
echo.
pause
```

Luego solo ejecuta: `BUILD_APK.bat`

---

**Fecha**: 7 de noviembre de 2025  
**Versión**: 1.0.1
