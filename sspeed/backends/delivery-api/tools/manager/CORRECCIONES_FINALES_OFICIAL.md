# 🎯 CORRECCIONES FINALES BASADAS EN DOCUMENTACIÓN OFICIAL

## 📚 Fuente: DOCUMENTACION_API.md y FUNCIONES_ROLES.md

---

## ✅ CAMBIOS APLICADOS

### 1. **POST /auth/login** → ✅ CORREGIDO
**Campo incorrecto:** `email`  
**Campo correcto:** `correo`

```json
// ❌ Antes
{ "email": "test@test.com", "password": "123456" }

// ✅ Ahora
{ "correo": "test@test.com", "password": "123456" }
```

---

### 2. **POST /registro** → ✅ YA ESTABA CORRECTO
Usa `correo` correctamente ✅

---

### 3. **PUT /auth/cambiar-password** → ✅ RUTA CONFIRMADA
**Ruta oficial:** `/auth/cambiar-password` ✅  
**Campos:** `passwordActual`, `nuevaPassword`

```json
{
  "passwordActual": "Cliente123!",
  "nuevaPassword": "Cliente123!"
}
```

**Nota:** Requiere token de autenticación válido

---

### 4. **POST /admin/productos** → ✅ CORREGIDO
**Campos obligatorios según documentación:**
- `nombre` ✅
- `descripcion` ✅
- `precio` ✅
- `imagenUrl` ✅
- `categoria` ✅
- `disponible` ✅
- `idNegocio` ✅

```json
{
  "nombre": "Hamburguesa Clásica",
  "descripcion": "Hamburguesa con carne, lechuga y tomate",
  "precio": 8.50,
  "imagenUrl": "https://...",
  "categoria": "Comida",
  "disponible": true,
  "idNegocio": 1
}
```

**Roles permitidos:**
- ✅ `admin` - Puede crear productos en cualquier negocio
- ✅ `negocio` - Puede crear productos en su propio negocio

---

### 5. **POST /pedidos** → ✅ CORREGIDO - CAMBIO CRÍTICO
**Campo incorrecto:** `productos`  
**Campo correcto:** `items` ← **SEGÚN DOCUMENTACIÓN OFICIAL**

```json
// ❌ Antes
{
  "idUsuario": 1,
  "idNegocio": 1,
  "productos": [{"idProducto": 1, "cantidad": 2}]
}

// ✅ Ahora (SEGÚN DOCUMENTACIÓN)
{
  "idUsuario": 1,
  "idNegocio": 1,
  "items": [
    { "idProducto": 1, "cantidad": 2 },
    { "idProducto": 5, "cantidad": 1 }
  ],
  "direccionEntrega": "Calle Principal #123",
  "latitud": 0.988033,
  "longitud": -79.659094
}
```

**Roles permitidos:**
- ✅ `cliente` - ÚNICO ROL que puede crear pedidos
- ❌ `delivery` - NO puede crear pedidos
- ❌ `negocio` - NO puede crear pedidos
- ❌ `admin` - NO necesita crear pedidos (puede hacerlo pero no es su función)

---

## 🔐 PERMISOS POR ROL (Según FUNCIONES_ROLES.md)

### 👤 CLIENTE
**Puede:**
- ✅ Login/Registro
- ✅ Ver productos (GET /productos)
- ✅ Crear pedidos (POST /pedidos) ← **EXCLUSIVO**
- ✅ Ver sus pedidos (GET /pedidos/cliente/{id})
- ✅ Tracking en tiempo real
- ✅ Chat con delivery
- ✅ Chat con soporte
- ✅ Chat con IA bot
- ✅ Gestionar ubicaciones
- ✅ Cambiar password

**NO puede:**
- ❌ Crear productos
- ❌ Ver pedidos de otros usuarios
- ❌ Gestionar negocios

---

### 🏍️ DELIVERY
**Puede:**
- ✅ Login
- ✅ Ver pedidos disponibles
- ✅ Aceptar pedidos
- ✅ Ver sus pedidos asignados (GET /pedidos/delivery/{id})
- ✅ Actualizar estado de pedidos
- ✅ GPS tracking
- ✅ Chat con cliente
- ✅ Cambiar password

**NO puede:**
- ❌ Crear pedidos
- ❌ Ver productos en modo "agregar al carrito"
- ❌ Gestionar productos

---

### 🏪 NEGOCIO
**Puede:**
- ✅ Login/Registro con datos comerciales
- ✅ Ver pedidos de su negocio (GET /pedidos/negocio/{id})
- ✅ Actualizar estado de pedidos
- ✅ **Gestionar productos** (POST /admin/productos) ← PUEDE CREAR
- ✅ Crear/Editar/Eliminar productos
- ✅ Ver estadísticas
- ✅ Chat con soporte
- ✅ Cambiar password

**NO puede:**
- ❌ Crear pedidos
- ❌ Ver pedidos de otros negocios

---

### 👨‍💼 ADMIN
**Puede:**
- ✅ TODO ← **ACCESO COMPLETO**
- ✅ Ver todos los usuarios
- ✅ Ver todos los negocios
- ✅ Ver todos los pedidos
- ✅ **Gestionar productos globalmente**
- ✅ Crear/Editar/Eliminar cualquier recurso
- ✅ Ver estadísticas completas

**Acceso total a API**

---

### 🎧 SOPORTE
**Puede:**
- ✅ Login
- ✅ Ver conversaciones de soporte
- ✅ Responder tickets
- ✅ Cambiar password

**NO puede:**
- ❌ Gestionar productos
- ❌ Crear pedidos
- ❌ Acceso limitado

---

## 📊 MATRIZ DE PERMISOS POR ENDPOINT

| Endpoint | Cliente | Delivery | Negocio | Admin | Soporte |
|----------|---------|----------|---------|-------|---------|
| POST /auth/login | ✅ | ✅ | ✅ | ✅ | ✅ |
| POST /registro | ✅ | ✅ | ✅ | ✅ | ✅ |
| GET /productos | ✅ | ✅ | ✅ | ✅ | ✅ |
| **POST /pedidos** | **✅** | **❌** | **❌** | ✅ | ❌ |
| **POST /admin/productos** | ❌ | ❌ | **✅** | **✅** | ❌ |
| GET /pedidos/cliente/{id} | ✅ | ❌ | ❌ | ✅ | ❌ |
| GET /pedidos/delivery/{id} | ❌ | ✅ | ❌ | ✅ | ❌ |
| GET /pedidos/negocio/{id} | ❌ | ❌ | ✅ | ✅ | ❌ |
| PUT /auth/cambiar-password | ✅ | ✅ | ✅ | ✅ | ✅ |
| GET /usuarios | ❌ | ❌ | ❌ | ✅ | ❌ |

---

## 🔧 CAMBIOS EN EL CÓDIGO GUI

### Archivo: `unite_speed_gui.py`

#### 1. Login - Cambio de campo
```python
# Línea ~487
# ❌ Antes
json={"email": user['email'], "password": user['password']}

# ✅ Ahora
json={"correo": user['email'], "password": user['password']}
```

#### 2. Endpoint de Pedidos - Cambio de campo
```python
# Línea ~617
# ❌ Antes
'data': {'productos': [{'idProducto': 1, 'cantidad': 1}]}

# ✅ Ahora
'data': {'items': [{'idProducto': 1, 'cantidad': 2}]}
```

#### 3. Agregar roles permitidos
```python
# Línea ~610+
# Nuevo campo 'roles' para validación
{'method': 'POST', 'path': '/pedidos', 'roles': ['cliente'], ...}
{'method': 'POST', 'path': '/admin/productos', 'roles': ['admin', 'negocio'], ...}
```

---

## 🎯 PRUEBAS RECOMENDADAS

### Test 1: Login con cada rol
```
1. Rol: cliente → Obtener Token → ✅ Debe funcionar
2. Rol: admin → Obtener Token → ✅ Debe funcionar
3. Rol: delivery → Obtener Token → ✅ Debe funcionar
4. Rol: negocio → Obtener Token → ✅ Debe funcionar
```

### Test 2: Crear pedido (Solo cliente)
```
1. Obtener token de CLIENTE
2. POST /pedidos con token de cliente → ✅ Debe funcionar
3. POST /pedidos con token de delivery → ❌ Debe fallar (403)
```

### Test 3: Crear producto (Admin y Negocio)
```
1. Obtener token de ADMIN
2. POST /admin/productos → ✅ Debe funcionar
3. Obtener token de NEGOCIO
4. POST /admin/productos → ✅ Debe funcionar
5. Obtener token de CLIENTE
6. POST /admin/productos → ❌ Debe fallar (403)
```

---

## 📝 NOTAS IMPORTANTES

### Sobre POST /pedidos
Según la documentación oficial (DOCUMENTACION_API.md línea 513):
```json
{
  "idUsuario": 1,
  "idNegocio": 1,
  "items": [  // ← USA "items" NO "productos"
    { "idProducto": 1, "cantidad": 2 },
    { "idProducto": 5, "cantidad": 1 }
  ],
  "direccionEntrega": "Calle Principal #123",
  "latitud": 0.988033,
  "longitud": -79.659094
}
```

### Sobre POST /admin/productos
Pueden usarlo 2 roles:
- **ADMIN**: Crea productos en cualquier negocio
- **NEGOCIO**: Crea productos solo en su propio negocio

---

## ✅ CHECKLIST DE VERIFICACIÓN

- [x] Cambiar `email` → `correo` en login
- [x] Cambiar `productos` → `items` en crear pedido
- [x] Agregar campo `categoria` en crear producto
- [x] Agregar permisos por rol en endpoints
- [x] Documentar matriz de permisos
- [ ] **Ejecutar GUI y probar con token de CLIENTE**
- [ ] **Verificar que POST /pedidos ahora funcione**
- [ ] **Ejecutar GUI con token de ADMIN**
- [ ] **Verificar que POST /admin/productos funcione**
- [ ] **Confirmar 21/21 endpoints OK**

---

## 🚀 PRÓXIMO PASO

```bash
EJECUTAR_GUI.bat
```

**Secuencia de prueba:**
1. Obtener token de **cliente**
2. Click "Probar TODOS los Endpoints"
3. Verificar que POST /pedidos pase (ahora usa `items`)
4. Obtener token de **admin**
5. Click "Probar TODOS los Endpoints"
6. Verificar que POST /admin/productos pase

**Resultado esperado:** 21/21 (100%) ✅

---

*Basado en: DOCUMENTACION_API.md + FUNCIONES_ROLES.md*  
*Fecha: 2025-11-07*  
*Estado: ✅ CORRECCIONES FINALES APLICADAS*
