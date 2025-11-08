# APKs Release - Unite Speed

**Versión:** 1.0.0  
**Fecha de compilación:** 8 de noviembre de 2025  
**Commit:** bc10ddd  
**Branch:** main

## 📦 Archivos incluidos

- `app-arm64-v8a-release.apk` - Recomendado para dispositivos modernos (64-bit ARM)
- `app-armeabi-v7a-release.apk` - Para dispositivos antiguos (32-bit ARM)
- `app-x86_64-release.apk` - Para emuladores/tablets x86
- `app-release.apk` - APK universal (más grande, compatibilidad máxima)

## 🔐 Verificación de integridad

Para verificar los APKs descargados, ejecuta:

```cmd
certutil -hashfile app-arm64-v8a-release.apk SHA256
```

**Hashes SHA256:**
- app-arm64-v8a-release.apk: `1ba5a4628c861ac48f9b6d4d0d994b90a18d9d457c1a65f2141a3a1193be3c24`
- app-armeabi-v7a-release.apk: `ae34ca016d476efa6f53bb9f9985e7506339365f4f42084c9a7de53a7bb303a8`
- app-x86_64-release.apk: `1f685143a92f70b298ce29ec788dc86753da969aa2bad5827b2484c2f7506cbc`
- app-release.apk: `956ca8d69bf4825514493eee7fb6dc6b9d2289dc2b17138346c787e5fa696059`

## 📝 Cambios en esta versión

- ✅ Flujo de pago corregido: ahora regresa al inicio tras confirmar pedido
- ✅ Build exitoso sin errores
- ✅ Backend revisado y validado (Javalin + PostgreSQL)

## 📥 Instalación

1. Descarga el APK apropiado para tu dispositivo
2. Habilita "Instalar apps de fuentes desconocidas" en Android
3. Abre el APK y sigue las instrucciones

**Recomendado:** `app-arm64-v8a-release.apk` para la mayoría de dispositivos modernos.

## ⚙️ Requisitos

- Android 5.0 (API 21) o superior
- Conexión a internet
- Permisos: Ubicación, Almacenamiento

---

**Desarrollado para:** Esmeraldas, Ecuador  
**Soporte:** [GitHub Issues](https://github.com/Adrianguanoluisaloza/sspeed/issues)
