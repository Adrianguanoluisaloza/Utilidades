# 🔐 Autenticación JWT – delivery-api

Este backend usa JSON Web Tokens (JWT) con HMAC256. La configuración se toma desde variables de entorno (o un archivo `.env` en desarrollo) y se aplica en `JwtUtil.java`.

Archivo: `src/main/java/com/mycompany/delivery/api/util/JwtUtil.java`

---

## ⚙️ Variables de entorno

- `JWT_SECRET` (requerida en producción)
  - Clave secreta para firmar y verificar tokens.
  - En desarrollo, si no se define, usa `dev-secret-change-me` (solo para pruebas).
- `JWT_ISSUER` (opcional)
  - Emisor del token. Default: `delivery-api`.
- `JWT_EXPIRES_HOURS` (opcional)
  - Validez del token en horas. Default: `168` (7 días).

Ejemplo `.env` (desarrollo):
```
JWT_SECRET=dev-secret-change-me
JWT_ISSUER=delivery-api
JWT_EXPIRES_HOURS=168
```

---

## 🪪 Buenas prácticas

- Producción: definir SIEMPRE `JWT_SECRET` con un valor largo y aleatorio (32+ bytes).
- Rotación: planificar rotación de secretos y expiración acorde a riesgo.
- Scope: incluir sólo claims necesarios (`sub`, `email`, `rol`, `nombre`).
- Transporte: siempre sobre HTTPS.

Generar un secreto fuerte (ejemplos):
- PowerShell
```
[Convert]::ToBase64String((1..48 | ForEach-Object {Get-Random -Maximum 256}))
```
- Linux/Mac
```
head -c 48 /dev/urandom | base64
```

---

## 🪟 Windows – cómo configurar

### CMD (sesión actual)
```
set JWT_SECRET=pon-tu-secreto-aqui
set JWT_ISSUER=delivery-api
set JWT_EXPIRES_HOURS=168
```

### PowerShell (sesión actual)
```
$env:JWT_SECRET="pon-tu-secreto-aqui"
$env:JWT_ISSUER="delivery-api"
$env:JWT_EXPIRES_HOURS="168"
```

### Archivo `.env` (desarrollo)
Colócalo en la raíz del módulo `delivery-api`.

---

## ☑️ Prueba rápida

1) Inicia el backend con el `.env` configurado.
2) Realiza login/registro que emita JWT.
3) Verifica el token en jwt.io (no subas secretos; sólo validar estructura y claims).

Si `JWT_SECRET` no está definido, se usará `dev-secret-change-me` (no recomendado fuera de local).

---

## 📎 Referencias
- Clase utilitaria: `JwtUtil.java`
- Librería: `com.auth0:java-jwt`
- Carga de variables: `io.github.cdimascio:dotenv-java`
