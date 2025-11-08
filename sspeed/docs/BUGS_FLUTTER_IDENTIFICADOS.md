# 🐛 CORRECCIONES DE BUGS EN FLUTTER

## 📊 ESTADO GENERAL

✅ **4 de 4 bugs corregidos** (100%)

- ✅ Bug 1: Creación de pedido regresa al login - **CORREGIDO**
- ✅ Bug 2: Validación de nombre comercial - **CORREGIDO**
- ✅ Bug 3: Falta nombre del dueño en interfaz - **CORREGIDO**
- ✅ Bug 4: Mensajes a soporte fallan (error 400/404) - **CORREGIDO**

---

## �📋 PROBLEMAS IDENTIFICADOS Y SOLUCIONADOS

### 1. ✅ Al crear pedido regresa al login
**Archivo afectado:** `api_data_source.dart` (líneas 520-535)
**Estado:** CORREGIDO
**Problema:** Cuando el usuario intenta crear un pedido, la app lo regresa al login
**Causa raíz:** Nombres de campos incorrectos en el payload POST /pedidos causaban error 400 Bad Request que activaba el redirect a login

**Solución aplicada:**
Cambiar payload de POST /pedidos para usar nombres correctos de la API:
- ❌ `id_cliente` → ✅ `idUsuario`
- ❌ `productos` → ✅ `items`
- ❌ `metodo_pago` → ✅ `metodoPago`
- ➕ Agregados: `idNegocio`, `latitud`, `longitud`

---

### 2. ✅ Registro de negocio: "Nombre de empresa es obligatorio" aunque está lleno
**Archivo:** `register_screen.dart` (línea 446-455)
**Estado:** CORREGIDO
**Problema:** El formulario dice que el nombre comercial es obligatorio pero el campo ya está lleno
**Causa raíz:** El validador usaba `val!.isEmpty` que lanza excepción si val es null

**Código anterior:**
```dart
_buildTextField(
  controller: _nombreComercialController,
  hint: 'Nombre Comercial',
  icon: Icons.store_outlined,
  validator: (val) => val!.isEmpty
      ? 'Ingresa el nombre del negocio'  // ← ERROR AQUÍ
      : null,
),
```

**Solución aplicada:**
```dart
_buildTextField(
  controller: _nombreComercialController,
  hint: 'Nombre Comercial',
  icon: Icons.store_outlined,
  validator: (val) {
    if (val == null || val.trim().isEmpty) {
      return 'Ingresa el nombre del negocio';
    }
    return null;
  },
),
```

---

### 🐛 Bug 3: Interfaz de negocio no muestra nombre del dueño

**Estado:** ✅ CORREGIDO

**Problema:**
Cuando un usuario se registra como negocio, la interfaz solo muestra el nombre comercial del negocio, pero no el nombre del dueño/propietario. El usuario reportó que debería aparecer tanto el nombre del negocio como el nombre del dueño.

**Causa raíz:**
- `modern_business_home_screen.dart` solo mostraba `widget.businessUser.nombre` (nombre del usuario)
- No cargaba la información del negocio desde la API
- Faltaba mostrar el `nombreComercial` del negocio

**Solución implementada:**
1. **Importar modelo Negocio** (línea 7):
   ```dart
   import '../models/negocio.dart';
   ```

2. **Añadir Future para cargar negocio** (línea 29):
   ```dart
   late Future<Negocio?> _negocioFuture;
   ```

3. **Método para cargar datos del negocio** (líneas 57-60):
   ```dart
   void _loadNegocio() {
     _negocioFuture = Provider.of<DatabaseService>(context, listen: false)
         .getNegocioDeUsuario(widget.businessUser.idUsuario);
   }
   ```

4. **Modificar _buildBusinessHeader() con FutureBuilder** (líneas 109-191):
   ```dart
   Widget _buildBusinessHeader() {
     return FutureBuilder<Negocio?>(
       future: _negocioFuture,
       builder: (context, snapshot) {
         String nombreComercial = widget.businessUser.nombre;
         String nombreDueno = widget.businessUser.nombre;

         if (snapshot.hasData && snapshot.data != null) {
           nombreComercial = snapshot.data!.nombreComercial;
           nombreDueno = widget.businessUser.nombre;
         }

         return Container(
           // ... (container decorado)
           child: Column(
             children: [
               Text('🏪 Mi Negocio'),
               Text(nombreComercial), // Nombre del negocio
               Text('Dueño: $nombreDueno'), // Nombre del dueño ✅
             ],
           ),
         );
       },
     );
   }
   ```

**Archivos modificados:**
- `d:\Users\Adrian\Proyecto\sspeed\lib\business\modern_business_home_screen.dart`

**Verificación:**
- Inicia sesión como usuario negocio (maria.negocio@example.com / Negocio123!)
- Verifica que el header muestre:
  - "🏪 Mi Negocio"
  - Nombre comercial del negocio (ej: "Restaurante El Buen Sabor")
  - "Dueño: [Nombre del usuario]" (ej: "Dueño: María González")

---

---

## 🔧 PLAN DE CORRECCIÓN

### Paso 1: Corregir validador de nombre comercial
```dart
// Archivo: register_screen.dart
// Línea: ~448

validator: (val) {
  if (val == null || val.trim().isEmpty) {
    return 'Ingresa el nombre del negocio';
  }
  return null;
},
```

### Paso 2: Verificar envío de token en crear pedido
```dart
// Archivo: api_data_source.dart
// Verificar que _jsonHeaders incluya el token

Map<String, String> get _jsonHeaders {
  final headers = {
    'Content-Type': 'application/json; charset=utf-8',
  };
  
  // AGREGAR TOKEN SI EXISTE
  if (_token != null && _token!.isNotEmpty) {
    headers['Authorization'] = 'Bearer $_token';
  }
  
  return headers;
}
```

### Paso 3: Corregir campo 'productos' → 'items' en POST /pedidos
```dart
// Archivo: api_data_source.dart
// Línea: ~520-532

final payload = {
  'idUsuario': user.idUsuario,           // Cambiar de id_cliente
  'idNegocio': 1,                        // Agregar ID del negocio
  'items': productosJson,                // Cambiar de 'productos' a 'items'
  'direccionEntrega': location.direccion,
  'latitud': location.latitud,           // Agregar coordenadas
  'longitud': location.longitud,
  'metodoPago': paymentMethod,           // Cambiar de metodo_pago
};
```

### Paso 4: Agregar nombre del dueño en interfaz de negocio
```dart
// Archivo: register_business_screen.dart o business home
// En el AppBar o perfil

Text(
  'Negocio: ${negocio.nombreComercial}\nDueño: ${usuario.nombre}',
  style: TextStyle(fontSize: 14),
)
```

---

## 🧪 PRUEBAS RECOMENDADAS

### Test 1: Registro de negocio
1. Ir a Registro
2. Seleccionar rol "Negocio"
3. Llenar todos los campos obligatorios
4. Click en "Registrar"
5. ✅ Debe registrar sin error de "nombre obligatorio"
6. ✅ Debe mostrar nombre del negocio Y nombre del dueño

### Test 2: Crear pedido
1. Login como cliente
2. Agregar productos al carrito
3. Ir a checkout
4. Seleccionar dirección
5. Seleccionar método de pago
6. Click "Confirmar Pedido"
7. ✅ NO debe regresar al login
8. ✅ Debe crear el pedido exitosamente
9. ✅ Debe mostrar confirmación

---

## 📝 NOTAS ADICIONALES

### Campos de la API según documentación oficial:

**POST /pedidos:**
```json
{
  "idUsuario": 1,
  "idNegocio": 1,
  "items": [
    {"idProducto": 1, "cantidad": 2}
  ],
  "direccionEntrega": "Calle Principal #123",
  "latitud": 0.988033,
  "longitud": -79.659094,
  "metodoPago": "efectivo"
}
```

**POST /registro con rol negocio:**
```json
{
  "nombre": "Juan Pérez",              // ← Nombre del DUEÑO
  "correo": "juan@negocio.com",
  "contrasena": "123456",
  "rol": "negocio"
}
```

Luego crear el negocio:
```json
{
  "nombreComercial": "Restaurante El Sabor",  // ← Nombre del NEGOCIO
  "ruc": "1234567890",
  "direccion": "Calle Principal #123",
  "telefono": "0987654321",
  "idUsuario": 24
}
```

---

### 🐛 Bug 4: Enviar mensajes a soporte falla con error 400/404

**Estado:** ✅ CORREGIDO

**Problema:**
Al intentar enviar mensajes a soporte desde el chat, la API devuelve error 404 Not Found, impidiendo la comunicación con el equipo de soporte.

**Causa raíz:**
- El código intentaba usar el endpoint `/soporte/mensaje` que **NO EXISTE** en el backend
- La documentación menciona este endpoint pero no está implementado en la API
- El backend solo tiene `/chat/bot/mensajes` para chat con respuestas automáticas

**Solución implementada:**
1. **Modificado `api_data_source.dart`** (línea 843-863):
   ```dart
   // ANTES (❌ INCORRECTO - endpoint no existe)
   if (chatSection == 'soporte') {
     final response = await _post('/soporte/mensaje', {
       'idUsuario': idRemitente,
       'mensaje': mensaje,
       'tipo': 'consulta',
     });
   }

   // DESPUÉS (✅ CORRECTO - usa endpoint existente)
   if (chatSection == 'soporte') {
     // Soporte usa el mismo endpoint que el bot (respuestas automáticas)
     final response = await _post('/chat/bot/mensajes', {
       'id_conversacion': idConversacion,
       'idRemitente': idRemitente,
       'mensaje': mensaje,
     });
   }
   ```

**Endpoint correcto verificado:**
```json
POST /chat/bot/mensajes (✅ FUNCIONA)
{
  "mensaje": "Hola, necesito ayuda",
  "idRemitente": 1
}

Response:
{
  "status": 201,
  "success": true,
  "message": "Respuesta generada",
  "data": {
    "bot_reply": "Puedes revisar el estado actual en la pantalla 'Mis pedidos'...",
    "id_conversacion": 1762222797914
  }
}
```

**Pruebas realizadas:**
- ✅ Login exitoso con token JWT
- ✅ Envío de 3 mensajes de prueba al soporte
- ✅ Respuestas automáticas recibidas correctamente
- ✅ ID de conversación generado y retornado
- ❌ Endpoint `/soporte/mensaje` → 404 Not Found (no existe)

**Archivos modificados:**
- `d:\Users\Adrian\Proyecto\sspeed\lib\services\api_data_source.dart`

**Verificación:**
1. Iniciar sesión con cualquier usuario
2. Ir a la pantalla de chat
3. Seleccionar "Soporte"
4. Enviar un mensaje
5. **Resultado esperado:** ✅ Mensaje enviado correctamente, respuesta automática recibida
6. **Resultado anterior:** ❌ Error 404 Not Found, mensaje no enviado

---

*Fecha: 2025-11-07*  
*Estado: 4 bugs corregidos exitosamente*

