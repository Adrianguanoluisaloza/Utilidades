# 🔐 INFORMACIÓN DE FIRMA - CONFIDENCIAL

## ⚠️ ADVERTENCIA DE SEGURIDAD

Este archivo contiene información crítica de seguridad. **NO COMPARTIR PÚBLICAMENTE**.

---

## Credenciales del Keystore

### Archivo principal
- **Ruta**: `android/app/speed7delivery-release.keystore`
- **Tamaño**: ~2 KB
- **Creado**: 7 de noviembre de 2025

### Credenciales de acceso
```
Contraseña del keystore (storePassword): speed7delivery2025
Contraseña de la clave (keyPassword): speed7delivery2025
Alias de la clave (keyAlias): speed7delivery
```

### Detalles técnicos
```
Algoritmo: RSA
Tamaño de clave: 2048 bits
Algoritmo de firma: SHA384withRSA
Validez: 10,000 días (hasta ~2052)
Issuer: CN=Speed7Delivery, OU=Development, O=Speed7Delivery, L=Unknown, ST=Unknown, C=EC
```

---

## 📂 Ubicación de archivos

### Archivos que DEBEN guardarse:
1. `android/app/speed7delivery-release.keystore` - **ARCHIVO PRINCIPAL**
2. `android/key.properties` - Configuración de firma
3. Este documento - `CREDENCIALES_FIRMA.md`

### Copias de seguridad recomendadas:
- [ ] USB cifrado (almacenamiento físico)
- [ ] Gestor de contraseñas empresarial
- [ ] Google Drive/Dropbox (carpeta cifrada)
- [ ] Almacenamiento en la nube del equipo

---

## 🚨 Qué hacer en caso de pérdida

### Si se pierde el keystore:

1. **NO HAY RECUPERACIÓN POSIBLE**
   - Google no puede recuperar tu keystore
   - No hay forma de regenerarlo con los mismos datos

2. **Consecuencias:**
   - ❌ No podrás actualizar la app existente en Google Play
   - ❌ Tendrás que crear una nueva aplicación con diferente package name
   - ❌ Los usuarios deberán desinstalar y reinstalar
   - ❌ Se pierden todas las calificaciones y reseñas
   - ❌ Se pierde el historial de descargas

3. **Única solución:**
   - Crear nuevo keystore
   - Cambiar applicationId en `build.gradle.kts`
   - Publicar como nueva aplicación
   - Notificar a todos los usuarios

---

## ✅ Verificación del Keystore

### Comando para verificar información:
```bash
cd c:\Users\Adrian\Proyecto\sspeed\android\app
keytool -list -v -keystore speed7delivery-release.keystore -alias speed7delivery -storepass speed7delivery2025
```

### Salida esperada:
```
Alias name: speed7delivery
Creation date: 7 de noviembre de 2025
Entry type: PrivateKeyEntry
Certificate chain length: 1
Certificate[1]:
Owner: CN=Speed7Delivery, OU=Development, O=Speed7Delivery, L=Unknown, ST=Unknown, C=EC
Issuer: CN=Speed7Delivery, OU=Development, O=Speed7Delivery, L=Unknown, ST=Unknown, C=EC
Serial number: [número hexadecimal]
Valid from: [fecha] until: [fecha en 2052]
Certificate fingerprints:
    SHA1: [fingerprint]
    SHA256: [fingerprint]
Signature algorithm name: SHA384withRSA
Subject Public Key Algorithm: 2048-bit RSA key
```

---

## 🔄 Rotación de contraseñas (futuro)

Si necesitas cambiar las contraseñas del keystore:

### 1. Cambiar contraseña del keystore:
```bash
keytool -storepasswd -keystore speed7delivery-release.keystore
```

### 2. Cambiar contraseña de la clave:
```bash
keytool -keypasswd -alias speed7delivery -keystore speed7delivery-release.keystore
```

### 3. Actualizar `android/key.properties`:
```properties
storePassword=NUEVA_CONTRASEÑA
keyPassword=NUEVA_CONTRASEÑA
keyAlias=speed7delivery
storeFile=speed7delivery-release.keystore
```

---

## 👥 Compartir con el equipo

### Método seguro recomendado:

1. **Usar 1Password/Bitwarden Teams**
   - Crear vault compartido para el equipo
   - Subir keystore como archivo adjunto
   - Guardar contraseñas en campo seguro

2. **Alternativa: Carpeta cifrada compartida**
   - Usar Cryptomator o VeraCrypt
   - Compartir solo con miembros autorizados
   - Contraseña del contenedor por canal separado

3. **NO USAR:**
   - ❌ Email sin cifrar
   - ❌ WhatsApp/Telegram
   - ❌ Slack/Discord
   - ❌ Git/GitHub (aunque sea privado)
   - ❌ Google Drive sin cifrado

---

## 📋 Checklist de seguridad

Antes de publicar o compartir código:

- [ ] Verificar que `key.properties` está en `.gitignore`
- [ ] Verificar que `*.keystore` está en `.gitignore`
- [ ] Confirmar que keystore NO está en el repositorio
- [ ] Backup del keystore realizado en 3+ ubicaciones
- [ ] Contraseñas guardadas en gestor de contraseñas
- [ ] Equipo informado sobre ubicación del backup
- [ ] Documento de recuperación actualizado

---

## 📞 Responsables

### Acceso al keystore:
- Desarrollador principal: Adrian Guana Luis Aloza
- [Agregar otros miembros autorizados aquí]

### En caso de emergencia:
1. Contactar al desarrollador principal
2. Verificar backups en ubicaciones autorizadas
3. Si no hay recuperación, seguir "Plan de contingencia"

---

## 📅 Historial de cambios

| Fecha | Acción | Responsable |
|-------|--------|-------------|
| 2025-11-07 | Keystore creado | Adrian Guana |
| 2025-11-07 | Primera compilación exitosa v1.0.1 | Adrian Guana |
| | | |

---

**Última actualización**: 7 de noviembre de 2025  
**Versión del documento**: 1.0  
**Estado**: Activo

---

## 🔒 Nota final

Este keystore es la **identidad digital** de tu aplicación Speed7Delivery. Protégelo como protegerías la llave de tu casa o las contraseñas de tu banco.

**Recuerda**: Es más fácil prevenir que lamentar. Haz backup AHORA.
