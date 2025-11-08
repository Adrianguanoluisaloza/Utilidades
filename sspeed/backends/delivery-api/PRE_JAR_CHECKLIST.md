# ✅ CHECKLIST PRE-CONVERSIÓN A JAR - API REST

**Fecha**: 2 de noviembre de 2025  
**Objetivo**: Preparar el backend Java para empaquetar como JAR ejecutable

---

## 🎯 ESTADO ACTUAL DEL BACKEND

### ✅ **Aspectos Bien Implementados**

#### 1. **Manejo de Excepciones**
- ✅ Clase `ApiException` personalizada para errores HTTP
- ✅ Handler global de excepciones en Javalin
- ✅ Validaciones consistentes con `RequestValidator`
- ✅ Códigos de estado HTTP correctos (400, 401, 404, 500)
- ✅ Mensajes de error descriptivos

#### 2. **Estructura del Proyecto**
- ✅ Separación por capas: Controllers, Services, Repositories, Models
- ✅ Uso de DTOs (Payloads) para entrada/salida
- ✅ Configuración mediante variables de entorno (.env)
- ✅ Logging básico de requests/responses

#### 3. **Seguridad**
- ✅ Autenticación JWT
- ✅ Middleware de autorización
- ✅ Validación de entrada en todos los endpoints
- ✅ Contraseñas hasheadas con bcrypt (en BD)

---

## ⚠️ MEJORAS NECESARIAS ANTES DE EMPAQUETAR

### 🔴 **CRÍTICO - Manejo de Excepciones**

#### **Problema 1: Excepciones SQL sin manejo**
Varios métodos lanzan `SQLException` sin try-catch, lo que puede causar que el servidor explote.

**Ubicaciones detectadas**:
```java
// DeliveryApi.java líneas 607-608
} catch (SQLException e) {
    throw new ApiException(500, "No se pudo iniciar la conversacion de soporte", e);
}
```

**✅ Solución**: Envolver todas las operaciones de BD en try-catch con `ApiException`

#### **Problema 2: Nullpointer potenciales**
No hay validación de nulos antes de usar objetos.

**Ejemplo detectado**:
```java
// Si el body es null, se lanza NullPointerException
Producto prod = ctx.bodyAsClass(Producto.class);
if (prod.getIdNegocio() == null) // NPE si prod es null
```

**✅ Solución**: Validar nulos primero

---

### 🟡 **IMPORTANTE - Configuración**

#### **Problema 3: Puerto hardcodeado**
El puerto se resuelve pero puede fallar silenciosamente.

**Código actual**:
```java
private static int resolvePort() {
    String portStr = System.getenv("PORT");
    if (portStr != null && !portStr.isBlank()) {
        try { return Integer.parseInt(portStr.trim()); } catch (NumberFormatException ignored) {}
    }
    return 8080; // Default
}
```

**✅ Solución**: Agregar logging cuando usa puerto por defecto

#### **Problema 4: Variables de entorno faltantes**
Si falta .env, el app puede arrancar con configuración parcial.

**✅ Solución**: Validar variables críticas al inicio

---

### 🟢 **RECOMENDADO - Performance**

#### **Problema 5: Sin pool de conexiones explícito**
Las conexiones a BD se abren/cierran por request.

**✅ Solución**: Verificar que PostgreSQL Driver use pool interno o implementar HikariCP

#### **Problema 6: Sin límite de rate limiting**
Endpoints sin protección contra ataques de fuerza bruta.

**✅ Solución**: Agregar rate limiting en endpoints sensibles (login, registro)

---

## 🛠️ MEJORAS A IMPLEMENTAR

### **1. Handler Global de Errores Mejorado**

**Archivo**: `DeliveryApi.java`

**Antes**:
```java
app.exception(ApiException.class, (e, ctx) -> {
    int status = ((ApiException) e).getStatus();
    Object details = ((ApiException) e).getDetails();
    ctx.status(status).json(Map.of(
        "error", true,
        "message", e.getMessage(),
        "details", details != null ? details : Map.of()
    ));
});
```

**Después** (Mejorado):
```java
// Handler para ApiException
app.exception(ApiException.class, (e, ctx) -> {
    ApiException apiEx = (ApiException) e;
    int status = apiEx.getStatus();
    Object details = apiEx.getDetails();
    
    // Log error para monitoreo
    System.err.printf("[ApiException] %d - %s%n", status, e.getMessage());
    if (apiEx.getCause() != null) {
        apiEx.getCause().printStackTrace();
    }
    
    ctx.status(status).json(Map.of(
        "error", true,
        "message", e.getMessage(),
        "details", details != null ? details : Map.of(),
        "timestamp", System.currentTimeMillis()
    ));
});

// Handler para excepciones SQL no capturadas
app.exception(SQLException.class, (e, ctx) -> {
    System.err.println("[SQLException] Error de base de datos:");
    e.printStackTrace();
    ctx.status(500).json(Map.of(
        "error", true,
        "message", "Error interno del servidor (BD)",
        "timestamp", System.currentTimeMillis()
    ));
});

// Handler para NullPointerException
app.exception(NullPointerException.class, (e, ctx) -> {
    System.err.println("[NullPointerException] Error inesperado:");
    e.printStackTrace();
    ctx.status(500).json(Map.of(
        "error", true,
        "message", "Error interno del servidor (null)",
        "timestamp", System.currentTimeMillis()
    ));
});

// Handler genérico para otras excepciones
app.exception(Exception.class, (e, ctx) -> {
    System.err.println("[Exception] Error no manejado:");
    e.printStackTrace();
    ctx.status(500).json(Map.of(
        "error", true,
        "message", "Error interno del servidor",
        "timestamp", System.currentTimeMillis()
    ));
});
```

---

### **2. Validación de Variables de Entorno**

**Nuevo método en `DeliveryApi.java`**:
```java
private static void validateEnvironment() {
    List<String> missing = new ArrayList<>();
    
    // Variables críticas
    String[] required = {
        "DB_URL",
        "DB_USER", 
        "DB_PASSWORD",
        "JWT_SECRET"
    };
    
    for (String var : required) {
        if (System.getenv(var) == null || System.getenv(var).isBlank()) {
            missing.add(var);
        }
    }
    
    if (!missing.isEmpty()) {
        System.err.println("❌ Variables de entorno faltantes:");
        missing.forEach(v -> System.err.println("   - " + v));
        System.err.println("\n⚠️ El servidor puede no funcionar correctamente.");
        System.err.println("💡 Crea un archivo .env o configura las variables del sistema.\n");
        // NO lanzar excepción, solo advertir
    } else {
        System.out.println("✅ Variables de entorno validadas correctamente");
    }
}
```

**Llamar en `main()` antes de crear Javalin**:
```java
public static void main(String[] args) {
    Dotenv.load();
    validateEnvironment(); // AGREGAR AQUÍ
    
    final int port = resolvePort();
    Javalin app = Javalin.create(config -> {
        // ... resto del código
    }).start(port);
}
```

---

### **3. Validación de Body Nulo**

**Crear helper en `RequestValidator.java`**:
```java
/**
 * Valida que el body no sea nulo
 * @throws ApiException(400) si es nulo
 */
public static <T> T requireBody(T body, String message) {
    if (body == null) {
        throw new ApiException(400, message != null ? message : "El cuerpo de la petición es obligatorio");
    }
    return body;
}
```

**Usar en endpoints**:
```java
// ANTES
Producto prod = ctx.bodyAsClass(Producto.class);
if (prod.getIdNegocio() == null) { ... }

// DESPUÉS
Producto prod = RequestValidator.requireBody(
    ctx.bodyAsClass(Producto.class),
    "El producto es obligatorio"
);
if (prod.getIdNegocio() == null) { ... }
```

---

### **4. Logging Mejorado**

**Crear clase `Logger.java` simple**:
```java
package com.mycompany.delivery.api.util;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class Logger {
    private static final DateTimeFormatter FORMATTER = 
        DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    
    public static void info(String message) {
        System.out.printf("[INFO] %s - %s%n", 
            LocalDateTime.now().format(FORMATTER), message);
    }
    
    public static void error(String message, Throwable e) {
        System.err.printf("[ERROR] %s - %s%n", 
            LocalDateTime.now().format(FORMATTER), message);
        if (e != null) e.printStackTrace();
    }
    
    public static void warn(String message) {
        System.out.printf("[WARN] %s - %s%n", 
            LocalDateTime.now().format(FORMATTER), message);
    }
}
```

**Usar en el código**:
```java
// En lugar de System.out.println()
Logger.info("Servidor iniciado en puerto " + port);

// En lugar de e.printStackTrace()
Logger.error("Error al procesar pedido", e);
```

---

### **5. Health Check Endpoint**

**Agregar en `main()` después de crear Javalin**:
```java
// Health check para monitoreo
app.get("/health", ctx -> {
    try {
        // Verificar conexión a BD
        Connection conn = DbConnection.getConnection();
        boolean dbOk = conn != null && !conn.isClosed();
        conn.close();
        
        ctx.json(Map.of(
            "status", "UP",
            "database", dbOk ? "UP" : "DOWN",
            "timestamp", System.currentTimeMillis(),
            "uptime", ManagementFactory.getRuntimeMXBean().getUptime()
        ));
    } catch (Exception e) {
        ctx.status(503).json(Map.of(
            "status", "DOWN",
            "error", e.getMessage(),
            "timestamp", System.currentTimeMillis()
        ));
    }
});

// Endpoint de versión
app.get("/version", ctx -> {
    ctx.json(Map.of(
        "name", "Unite Speed Delivery API",
        "version", "1.0.0",
        "build", "2025-11-02"
    ));
});
```

---

## 📦 PASOS PARA EMPAQUETAR A JAR

### **1. Verificar pom.xml**

```xml
<build>
    <plugins>
        <!-- Plugin para crear JAR ejecutable -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-shade-plugin</artifactId>
            <version>3.5.1</version>
            <executions>
                <execution>
                    <phase>package</phase>
                    <goals>
                        <goal>shade</goal>
                    </goals>
                    <configuration>
                        <transformers>
                            <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                                <mainClass>com.mycompany.delivery.api.DeliveryApi</mainClass>
                            </transformer>
                        </transformers>
                        <filters>
                            <filter>
                                <artifact>*:*</artifact>
                                <excludes>
                                    <exclude>META-INF/*.SF</exclude>
                                    <exclude>META-INF/*.DSA</exclude>
                                    <exclude>META-INF/*.RSA</exclude>
                                </excludes>
                            </filter>
                        </filters>
                    </configuration>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

### **2. Comandos de Build**

```bash
# Limpiar builds anteriores
mvn clean

# Compilar sin tests
mvn package -DskipTests

# Compilar con tests
mvn package

# JAR resultante en: target/delivery-api-1.0-SNAPSHOT.jar
```

### **3. Ejecutar JAR**

```bash
# Opción 1: Con variables de entorno
export DB_URL="jdbc:postgresql://localhost:5432/sspeed_db"
export DB_USER="postgres"
export DB_PASSWORD="tu_password"
export JWT_SECRET="tu_secret_super_seguro"
export PORT=8080

java -jar target/delivery-api-1.0-SNAPSHOT.jar

# Opción 2: Con archivo .env en el mismo directorio
java -jar target/delivery-api-1.0-SNAPSHOT.jar

# Opción 3: Con parámetros de JVM
java -DPORT=8080 -DDB_URL=... -jar target/delivery-api-1.0-SNAPSHOT.jar
```

---

## 🧪 TESTS ANTES DE DEPLOYMENT

### **Checklist de Pruebas**

```bash
# 1. Health check
curl http://localhost:8080/health

# 2. Version info
curl http://localhost:8080/version

# 3. Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"correo":"ana.admin@example.com","contrasena":"Admin123!"}'

# 4. Listar productos (con token)
curl http://localhost:8080/api/productos \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# 5. Error handling (sin token)
curl http://localhost:8080/api/ubicaciones/1

# 6. Error 404
curl http://localhost:8080/api/ruta/inexistente
```

### **Verificar Logs**

Revisar que los logs muestren:
- ✅ Variables de entorno validadas
- ✅ Puerto correcto
- ✅ Requests con tiempo de respuesta
- ✅ Errores con stack trace completo

---

## 🚀 DEPLOYMENT CHECKLIST

### **Pre-Deployment**

- [ ] Todas las excepciones están manejadas
- [ ] Variables de entorno documentadas
- [ ] Health check endpoint funciona
- [ ] Tests manuales pasados
- [ ] JAR se ejecuta localmente sin errores
- [ ] Logs son legibles y útiles

### **Post-Deployment**

- [ ] Servidor responde en puerto configurado
- [ ] BD conecta correctamente
- [ ] JWT funciona (login retorna token)
- [ ] CORS configurado (si es necesario)
- [ ] Logs se guardan (stdout/stderr)
- [ ] Monitoreo activo

---

## 📋 ARCHIVOS A INCLUIR EN DEPLOYMENT

```
deployment/
├── delivery-api.jar          # JAR ejecutable
├── .env.example              # Template de variables
├── README.md                 # Instrucciones de deployment
└── scripts/
    ├── start.sh              # Script de inicio Linux
    ├── start.bat             # Script de inicio Windows
    └── healthcheck.sh        # Script de verificación
```

**start.sh**:
```bash
#!/bin/bash
set -e

# Cargar variables de entorno
if [ -f .env ]; then
    export $(cat .env | xargs)
fi

# Ejecutar JAR
java -Xmx512m -Xms256m -jar delivery-api.jar
```

**healthcheck.sh**:
```bash
#!/bin/bash
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/health)
if [ $response -eq 200 ]; then
    echo "✅ API is healthy"
    exit 0
else
    echo "❌ API is down (HTTP $response)"
    exit 1
fi
```

---

## 🔐 SEGURIDAD FINAL

### **Variables Sensibles**

⚠️ **NUNCA** incluir en el repositorio:
- Contraseñas de BD
- JWT_SECRET
- API Keys (Google Maps, Gemini)
- Tokens de terceros

✅ **SÍ** incluir:
- .env.example con valores de ejemplo
- Documentación de variables requeridas

### **Permisos de Archivos**

```bash
# Solo el dueño puede leer .env
chmod 600 .env

# JAR ejecutable
chmod +x delivery-api.jar
```

---

## 📊 MONITOREO RECOMENDADO

### **Métricas Críticas**

1. **Uptime**: `/health` cada 30 segundos
2. **Response Time**: Logs de timing en cada request
3. **Error Rate**: Conteo de excepciones por minuto
4. **DB Connections**: Pool de conexiones activas
5. **Memory Usage**: JVM heap usage

### **Alertas**

- 🚨 API down más de 2 minutos
- ⚠️ Response time > 5 segundos
- ⚠️ Error rate > 10% requests
- ⚠️ Memory usage > 80%

---

## ✅ RESUMEN EJECUTIVO

| Aspecto | Estado | Acción Requerida |
|---------|--------|------------------|
| Manejo de Excepciones | 🟡 Bueno | Agregar handlers globales |
| Validación de Entrada | ✅ Excelente | Ninguna |
| Configuración | 🟡 Bueno | Validar vars al inicio |
| Logging | 🔴 Básico | Implementar Logger |
| Health Check | 🔴 Faltante | Agregar endpoint |
| Build Configuration | ✅ Listo | Ninguna |
| Seguridad | ✅ Buena | Ninguna |
| Performance | 🟡 Aceptable | Considerar pool BD |

**Tiempo estimado de mejoras**: 2-3 horas  
**Prioridad**: 🔴 ALTA (antes de deployment)

---

**Última actualización**: 2 de noviembre de 2025  
**Versión**: 1.0  
**Estado**: ⏳ Pendiente de implementación
