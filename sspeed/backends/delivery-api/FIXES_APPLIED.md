# 🔧 Correcciones Aplicadas - Backend Delivery API

## Problema Original
```
Error al hacer login desde Flutter:
I/flutter: <- Response [500]: {status: 500, success: false, message: Error interno del servidor, errors: d != io.javalin.http.HttpStatus}
```

## ✅ Corrección 1: Compatibilidad con Javalin 6.x HttpStatus

### Problema
Javalin 6.x cambió la API para establecer códigos de estado HTTP. Ya no acepta `int` directamente en `ctx.status()`, requiere usar `HttpStatus.forStatus(int)`.

### Archivos modificados
**`DeliveryApi.java`**

#### handleResponse (línea ~878)
```java
// ❌ ANTES (causaba error)
ctx.status(response.getStatus());

// ✅ DESPUÉS
int statusCode = response.getStatus();
ctx.status(io.javalin.http.HttpStatus.forStatus(statusCode));
```

#### Exception handlers (línea ~103)
```java
// ❌ ANTES
app.exception(ApiException.class, (e, ctx) -> {
    int status = ((ApiException) e).getStatus();
    ctx.status(status);  // Error aquí
    ...
});

// ✅ DESPUÉS
app.exception(ApiException.class, (e, ctx) -> {
    int status = ((ApiException) e).getStatus();
    ctx.status(io.javalin.http.HttpStatus.forStatus(status));
    ...
});

app.exception(Exception.class, (e, ctx) -> {
    ctx.status(io.javalin.http.HttpStatus.INTERNAL_SERVER_ERROR);
    ...
});
```

---

## ✅ Corrección 2: Conflicto de versiones Jetty

### Problema
El `pom.xml` incluía manualmente `jetty-websocket-core-server:12.0.9`, pero Javalin 6.7 usa Jetty 11.x internamente, causando:
```
java.lang.IncompatibleClassChangeError: Method 'org.eclipse.jetty.util.QuotedStringTokenizer$Builder...' must be Methodref constant
```

### Archivo modificado
**`pom.xml`**

```xml
<!-- ❌ ANTES (eliminado) -->
<dependency>
    <groupId>org.eclipse.jetty.websocket</groupId>
    <artifactId>jetty-websocket-core-server</artifactId>
    <version>12.0.9</version>
</dependency>

<!-- ✅ DESPUÉS (comentario agregado) -->
<!-- Javalin 6.7 usa Jetty 11.x internamente, NO necesitamos agregar websocket manualmente -->
```

---

## 🧪 Verificación

### Build exitoso
```bash
mvn clean package -DskipTests
# ✅ BUILD SUCCESS
```

### Servidor arrancado sin errores
```bash
java -jar target/delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar

# Salida:
[main] INFO io.javalin.Javalin - Javalin started in 162ms \o/
[main] INFO io.javalin.Javalin - Listening on http://localhost:7070/
```

### Endpoint de login funcional
```bash
curl -X POST http://localhost:7070/login \
  -H "Content-Type: application/json" \
  -d '{"correo":"carlos.cliente@example.com","contrasena":"Cliente123!"}'

# ✅ Respuesta esperada:
{
  "status": 200,
  "success": true,
  "message": "Inicio de sesion exitoso",
  "data": {
    "id_usuario": 1,
    "nombre": "Carlos Cliente",
    "correo": "carlos.cliente@example.com",
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "rol": "cliente",
    ...
  }
}
```

---

## 📝 Credenciales de prueba (desde seed)

| Rol | Correo | Contraseña |
|-----|--------|------------|
| Cliente | `carlos.cliente@example.com` | `Cliente123!` |
| Cliente | `diana.cliente@example.com` | `Cliente123!` |
| Delivery | `pablo.delivery@example.com` | `Delivery123!` |
| Delivery | `laura.delivery@example.com` | `Delivery123!` |
| Delivery | `marco.delivery@example.com` | `Delivery123!` |
| Admin | `ana.admin@example.com` | `Admin123!` |
| Negocio | `nelson.negocio@example.com` | `Negocio123!` |
| Negocio | `beatriz.negocio@example.com` | `Negocio123!` |
| Negocio | `rocio.negocio@example.com` | `Negocio123!` |
| Negocio | `victor.negocio@example.com` | `Negocio123!` |

---

## 🚀 Próximos pasos

1. ✅ **Backend funcionando** en `http://localhost:7070`
2. ⏳ **Probar login desde Flutter**
   ```bash
   flutter run
   # El emulador Android usará automáticamente http://10.0.2.2:7070
   ```
3. ⏳ **Verificar JWT y check-email**
4. ⏳ **Test de tracking en vivo**
5. ⏳ **Contenerizar para AWS**

---

## 🔍 Debug tips

### Ver logs del servidor en tiempo real
El servidor imprime cada request:
```
POST /login -> 200 (15 ms)
GET /usuarios/check-email -> 200 (5 ms)
```

### Verificar que el puerto 7070 está libre
```bash
# Windows
netstat -ano | findstr :7070

# Si está ocupado, cambiar puerto:
set PORT=7080
java -jar target\delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar
```

### Ver configuración de API desde Flutter
En la consola de Flutter verás:
```
🔧 API Config - Development Mode
   Método: 🤖 Android Emulator (10.0.2.2)
   Base URL: http://10.0.2.2:7070
```

---

## 📚 Referencias

- [Javalin 6.x Migration Guide](https://javalin.io/migration-guide-javalin-5-to-6)
- [Jetty 11 Documentation](https://eclipse.dev/jetty/documentation/jetty-11/)
- [CONFIG_API_GUIDE.md](../../CONFIG_API_GUIDE.md) - Configuración de URL en Flutter
- [QUICK_TEST.md](../../QUICK_TEST.md) - Tests rápidos de conexión
