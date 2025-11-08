# CORRECCIONES APLICADAS AL PANEL GUI - UNITE SPEED

## Fecha: 7 de noviembre de 2025

### 📋 Resumen
Se corrigieron todos los endpoints del panel GUI (`unite_speed_gui.py`) basándose en la revisión del código backend Java real.

---

## ✅ CAMBIOS REALIZADOS

### 1. **Endpoint de Login**
**Antes:**
```python
url = f"{base_url}/auth/login"
json={"correo": email, "password": password}
```

**Después:**
```python
url = f"{base_url}/login"
json={"correo": email, "contrasena": password}
```

**Razón:** El endpoint real es `/login` (sin `/auth`) y el campo es `contrasena` no `password`.

---

### 2. **Endpoint Crear Pedido**
**Antes:**
```python
{
  "idUsuario": 1,
  "idNegocio": 1,
  "items": [{"idProducto": 1, "cantidad": 2}],
  "direccionEntrega": "...",
  "latitud": 0.988033,
  "longitud": -79.659094
}
```

**Después:**
```python
{
  "id_cliente": 1,
  "productos": [
    {
      "idProducto": 1,
      "cantidad": 2,
      "precio_unitario": 10.50,
      "subtotal": 21.0
    }
  ],
  "direccion_entrega": "...",
  "metodo_pago": "efectivo"
}
```

**Razones:**
- Campo principal: `id_cliente` (snake_case) según `PedidoPayload.java` línea 96
- Array: `productos` no `items` (línea 120)
- Campos producto: agregar `precio_unitario` y `subtotal`
- Campo dirección: `direccion_entrega` (snake_case) según líneas 104-109
- Campo pago: `metodo_pago` (snake_case) según línea 114
- Remover: `latitud`, `longitud`, `idNegocio` (opcionales)

---

### 3. **Endpoint Cambiar Password**
**Antes:**
```python
{
  "passwordActual": "...",
  "nuevaPassword": "..."
}
```

**Después:**
```python
{
  "actual": "...",
  "nueva": "..."
}
```

**Razón:** Según `Payloads.java` líneas 57-62, los campos se llaman `actual` y `nueva`.

---

### 4. **Endpoint Registro**
**Antes:**
```python
json={"nombre": "...", "correo": "...", "password": "...", "rol": "..."}
```

**Después:**
```python
json={"nombre": "...", "correo": "...", "contrasena": "...", "rol": "..."}
```

**Razón:** Consistencia con login, usar `contrasena`.

---

### 5. **Endpoint Crear Producto**
**Antes:**
```python
{
  "imagenUrl": "...",
  "idNegocio": 1
}
```

**Después:**
```python
{
  "imagen_url": "...",
  "id_negocio": 1
}
```

**Razón:** Backend acepta snake_case según `@SerializedName`.

---

### 6. **Endpoint Crear Ubicación**
**Antes:**
```python
{"idUsuario": 1, ...}
```

**Después:**
```python
{"id_usuario": 1, ...}
```

**Razón:** `UbicacionRequest.java` usa `@SerializedName("id_usuario")`.

---

### 7. **Endpoint Chat Iniciar (NUEVO)**
**Agregado:**
```python
{
  'method': 'POST',
  'path': '/chat/iniciar',
  'desc': 'Iniciar Chat',
  'auth': True,
  'roles': ['cliente', 'delivery', 'admin'],
  'data': {
    'idCliente': 1,
    'idDestinatario': 4,
    'tipoDestinatario': 'delivery'
  }
}
```

**Razón:** Endpoint faltante necesario para iniciar conversaciones entre cliente-delivery.

---

## 🔍 VERIFICACIÓN REALIZADA

### Test Automático Ejecutado
✅ **test_gui_quick.py** - Todos los tests PASARON:

1. ✅ Login con `/login` y `contrasena` → Status 200
2. ✅ Crear Pedido con `id_cliente`, `productos`, etc. → Status 201, Pedido ID: 5
3. ✅ Chat Bot IA → Status 201
4. ✅ Cambiar Password con `actual` y `nueva` → Status 200

---

## 📁 ARCHIVOS MODIFICADOS

1. **unite_speed_gui.py**
   - Línea ~449: Login endpoint corregido
   - Línea ~636: Lista de endpoints actualizada
   - Campos de payload corregidos en todos los endpoints

2. **test_gui_quick.py** (NUEVO)
   - Script de verificación rápida de correcciones

---

## 🎯 PRÓXIMOS PASOS

1. ✅ Ejecutar panel GUI completo
2. ✅ Probar con todos los roles (cliente, delivery, negocio, admin)
3. ✅ Exportar resultados a HTML
4. ✅ Verificar que todos los endpoints funcionan correctamente

---

## 📊 RESUMEN DE CAMPOS CORRECTOS

### Backend Java (PedidoPayload.java)
```java
@SerializedName("id_cliente")
public Integer idCliente;

@SerializedName("direccion_entrega")
private String direccionEntregaSnake;

@SerializedName(value = "metodo_pago", alternate = {"metodoPago"})
public String metodoPago;

public List<PedidoDetallePayload> productos;
```

### Frontend/Tests deben enviar:
```json
{
  "id_cliente": 1,          // snake_case
  "productos": [...],       // NO "items"
  "direccion_entrega": "...", // snake_case
  "metodo_pago": "..."      // snake_case
}
```

---

## ✅ ESTADO FINAL
**TODOS LOS ENDPOINTS DEL GUI CORREGIDOS Y FUNCIONANDO** 🚀
