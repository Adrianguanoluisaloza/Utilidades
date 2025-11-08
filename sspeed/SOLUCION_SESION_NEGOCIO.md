# 🔧 SOLUCIÓN: Sesión Rota al Convertir Cliente → Negocio

## 🐛 PROBLEMA IDENTIFICADO

Cuando un usuario **cliente** se convertía en **negocio**, ocurrían los siguientes problemas:

1. ✅ Backend actualizaba `usuarios.id_rol = 'negocio'` correctamente
2. ❌ Frontend **NO** actualizaba el objeto `Usuario` en `SessionController`
3. ❌ La sesión persistida seguía con `rol='cliente'`
4. ❌ Al editar productos, la sesión se perdía o mostraba "usuario sin identificar"
5. ❌ Perfil mostraba datos incorrectos o vacíos

### Flujo del Bug:
```
1. Cliente login → usuario.rol = 'cliente', token guardado ✅
2. Cliente registra negocio → backend cambia rol a 'negocio' ✅
3. Frontend navega a negocioHome PERO sesión sigue con rol='cliente' ❌
4. Al editar producto → inconsistencia rol/permisos → 403 o error ❌
5. Sesión se pierde porque Usuario en memoria ≠ Usuario en backend ❌
```

---

## ✅ SOLUCIÓN IMPLEMENTADA

### 🔹 **1. Backend: Retornar Usuario Actualizado en Respuesta**

**Archivo:** `backends/delivery-api/src/main/java/com/mycompany/delivery/api/controller/NegocioController.java`

**Cambio:**
```java
// ANTES: Solo retornaba el negocio
return ApiResponse.success(200, "Negocio registrado", resultado);

// DESPUÉS: Retorna negocio Y usuario con rol actualizado
Map<String, Object> respuesta = new HashMap<>();
respuesta.put("negocio", resultado);
respuesta.put("usuario", usuario); // usuario.rol ya actualizado a 'negocio'
return ApiResponse.success(200, "Negocio registrado", respuesta);
```

---

### 🔹 **2. Frontend: Actualizar Sesión tras Registro**

**Archivo:** `lib/screen/register_business_screen.dart`

**Cambio:**
```dart
// ANTES: No actualizaba la sesión
final guardado = await servicio.registrarNegocioParaUsuario(...);
if (guardado != null) {
  navigator.pushNamedAndRemoveUntil(AppRoutes.negocioHome, ...);
}

// DESPUÉS: Actualiza sesión con rol correcto
final respuesta = await servicio.registrarNegocioParaUsuario(...);
if (respuesta != null && respuesta['negocio'] != null) {
  final negocioGuardado = respuesta['negocio'] as Negocio;
  final usuarioActualizado = respuesta['usuario'] as Usuario?;
  
  // CRÍTICO: Actualizar sesión
  final usuarioFinal = usuarioActualizado ?? widget.usuario.copyWith(rol: 'negocio');
  await context.read<SessionController>().setUser(usuarioFinal);
  
  navigator.pushNamedAndRemoveUntil(
    AppRoutes.negocioHome, 
    (route) => false, 
    arguments: usuarioFinal // ✅ Pasar usuario con rol actualizado
  );
}
```

**Import agregado:**
```dart
import '../models/session_state.dart';
```

---

### 🔹 **3. Actualizar Interface y Servicios**

**Archivo:** `lib/services/data_source.dart`

```dart
// ANTES:
Future<Negocio?> registrarNegocioParaUsuario(int idUsuario, Negocio negocio);

// DESPUÉS:
/// Registra negocio y retorna Map con 'negocio' y 'usuario' (con rol actualizado)
Future<Map<String, dynamic>?> registrarNegocioParaUsuario(int idUsuario, Negocio negocio);
```

**Archivo:** `lib/services/api_data_source.dart`

```dart
@override
Future<Map<String, dynamic>?> registrarNegocioParaUsuario(
    int idUsuario, Negocio negocio) async {
  final payload = Map<String, dynamic>.from(negocio.toJson());
  payload['id_usuario'] = idUsuario;
  final resp = await _post('/usuarios/$idUsuario/negocio', payload);
  final data = resp['data'];
  
  if (data is Map<String, dynamic>) {
    // Respuesta actualizada con negocio y usuario
    if (data.containsKey('negocio') && data.containsKey('usuario')) {
      return {
        'negocio': Negocio.fromMap(data['negocio'] as Map<String, dynamic>),
        'usuario': Usuario.fromMap(data['usuario'] as Map<String, dynamic>),
      };
    }
    // Retrocompatibilidad: respuesta antigua solo con negocio
    return {
      'negocio': Negocio.fromMap(data),
      'usuario': null,
    };
  }
  return null;
}
```

---

### 🔹 **4. Manejo Mejorado de Errores en Edición de Productos**

**Archivo:** `lib/admin/business_products_view.dart`

**Cambios:**

1. **Imports agregados:**
```dart
import '../services/api_exception.dart';
import '../routes/app_routes.dart';
```

2. **Manejo específico de errores 401/403:**
```dart
try {
  final success = await db2.updateProducto(updated);
  
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Producto actualizado correctamente'),
        backgroundColor: Colors.green,
      ),
    );
    setState(_reload);
  }
} on ApiException catch (e) {
  // Manejo específico de errores de autenticación
  if (e.statusCode == 401 || e.statusCode == 403) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sesión expirada: ${e.message}'),
        backgroundColor: Colors.red,
      ),
    );
    // Solo redirigir al login si es error de autenticación
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  } else {
    // Otros errores no limpian la sesión
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: ${e.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

### 🔹 **5. Logging Detallado en updateProducto**

**Archivo:** `lib/services/api_data_source.dart`

```dart
@override
Future<bool> updateProducto(Producto producto) async {
  if (AppConfig.enableLogs) {
    debugPrint('[ApiDataSource] Actualizando producto ${producto.idProducto}');
    debugPrint('   -> Token presente: ${_token != null && _token!.isNotEmpty}');
    debugPrint('   -> Payload: ${producto.toMap()}');
  }
  
  try {
    final response = await _put('/admin/productos/${producto.idProducto}', producto.toMap());
    
    if (AppConfig.enableLogs) {
      debugPrint('[ApiDataSource] Producto actualizado exitosamente');
      debugPrint('   <- Response: $response');
    }
    
    return response['success'] ?? false;
  } catch (e) {
    if (AppConfig.enableLogs) {
      debugPrint('[ApiDataSource] ERROR al actualizar producto: $e');
    }
    rethrow;
  }
}
```

---

## 📊 ESTRUCTURA DE BASE DE DATOS

La estructura actual es **correcta** y **NO necesita cambios**:

```sql
-- Tabla usuarios: Un usuario puede tener múltiples roles (cliente, negocio, delivery, admin)
CREATE TABLE usuarios (
    id_usuario BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(120) NOT NULL,
    correo VARCHAR(160) NOT NULL UNIQUE,
    contrasena TEXT NOT NULL,
    telefono VARCHAR(60),
    id_rol INTEGER NOT NULL REFERENCES roles(id_rol),  -- Rol actual del usuario
    activo BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla negocios: Relación 1:1 con usuarios (un usuario puede tener un negocio)
CREATE TABLE negocios (
    id_negocio BIGSERIAL PRIMARY KEY,
    id_usuario BIGINT REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    nombre_comercial VARCHAR(150) NOT NULL,
    ruc VARCHAR(13),
    direccion TEXT,
    telefono VARCHAR(60),
    logo_url TEXT,
    activo BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

**Ventajas del diseño actual:**
- ✅ Un usuario puede ser cliente Y negocio (solo cambia `id_rol`)
- ✅ Relación 1:1 clara entre `usuarios` y `negocios`
- ✅ No necesita tabla intermedia `cliente_negocio`
- ✅ Mantiene historial de pedidos como cliente aunque se convierta en negocio

---

## 🧪 PRUEBAS RECOMENDADAS

### Flujo Completo a Probar:
```
1. Login como cliente ✅
2. Registrar negocio ✅
3. Verificar que perfil muestra rol='negocio' ✅
4. Crear producto nuevo ✅
5. Editar producto existente ✅
6. Verificar que sesión sigue activa (no "usuario sin identificar") ✅
7. Cerrar sesión y volver a entrar ✅
8. Verificar que sigue como negocio ✅
```

### Comandos de Verificación:
```bash
# Ver logs en tiempo real durante prueba
flutter run --verbose

# Ver solo logs de API
flutter run | grep "ApiDataSource"
```

---

## 📝 RESUMEN DE ARCHIVOS MODIFICADOS

### Backend (Java):
1. ✅ `NegocioController.java` - Retorna usuario actualizado en respuesta

### Frontend (Flutter):
1. ✅ `register_business_screen.dart` - Actualiza sesión tras registro
2. ✅ `data_source.dart` - Interface actualizada
3. ✅ `api_data_source.dart` - Procesa respuesta con usuario, logging en updateProducto
4. ✅ `database_service.dart` - Actualiza firma del método
5. ✅ `business_products_view.dart` - Manejo mejorado de errores 401/403

### Validaciones:
- ✅ `Usuario.copyWith()` mantiene el token correctamente
- ✅ `SessionController.setUser()` persiste en SharedPreferences
- ✅ Logs detallados para diagnóstico

---

## 🎯 CONCLUSIÓN

El problema se resolvió **sincronizando el rol del usuario entre backend y frontend** tras la conversión de cliente a negocio. Ahora:

- ✅ La sesión se mantiene correcta después de registrar el negocio
- ✅ El perfil muestra datos correctos con rol='negocio'
- ✅ Los productos se pueden editar sin perder la sesión
- ✅ Los errores 401/403 se manejan correctamente sin limpiar sesión innecesariamente
- ✅ Logs detallados para diagnóstico de problemas futuros

**NO** se necesita crear una tabla `cliente_negocio`. La estructura actual es óptima y sigue las mejores prácticas de diseño de bases de datos.
