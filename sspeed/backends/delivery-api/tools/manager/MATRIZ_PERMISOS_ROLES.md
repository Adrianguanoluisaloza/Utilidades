# 🔐 MATRIZ DE PERMISOS POR ROL - UNITE SPEED DELIVERY

## 📊 TABLA COMPLETA DE PERMISOS

| # | Endpoint | Método | Cliente | Delivery | Negocio | Admin | Soporte |
|---|----------|--------|---------|----------|---------|-------|---------|
| 1 | `/auth/login` | POST | ✅ | ✅ | ✅ | ✅ | ✅ |
| 2 | `/registro` | POST | ✅ | ✅ | ✅ | ✅ | ✅ |
| 3 | `/auth/reset/generar` | POST | ✅ | ✅ | ✅ | ✅ | ✅ |
| 4 | `/auth/cambiar-password` | PUT | ✅ | ✅ | ✅ | ✅ | ✅ |
| 5 | `/health` | GET | ✅ | ✅ | ✅ | ✅ | ✅ |
| 6 | `/productos` | GET | ✅ | ✅ | ✅ | ✅ | ✅ |
| 7 | `/productos/{id}` | GET | ✅ | ✅ | ✅ | ✅ | ✅ |
| 8 | `/admin/productos` | POST | ❌ | ❌ | ✅ | ✅ | ❌ |
| 9 | `/pedidos/cliente/{id}` | GET | ✅ | ❌ | ❌ | ✅ | ❌ |
| 10 | `/pedidos/negocio/{id}` | GET | ❌ | ❌ | ✅ | ✅ | ❌ |
| 11 | `/pedidos/delivery/{id}` | GET | ❌ | ✅ | ❌ | ✅ | ❌ |
| 12 | `/pedidos` | POST | ✅ | ❌ | ❌ | ✅ | ❌ |
| 13 | `/ubicaciones/usuario/{id}` | GET | ✅ | ✅ | ❌ | ✅ | ❌ |
| 14 | `/ubicaciones` | POST | ✅ | ✅ | ❌ | ✅ | ❌ |
| 15 | `/tracking/pedido/{id}` | GET | ✅ | ✅ | ❌ | ✅ | ❌ |
| 16 | `/tracking/pedido/{id}/ruta` | GET | ✅ | ✅ | ❌ | ✅ | ❌ |
| 17 | `/chat/bot/mensajes` | POST | ✅ | ✅ | ❌ | ✅ | ❌ |
| 18 | `/chat/conversaciones/{id}` | GET | ✅ | ✅ | ❌ | ✅ | ❌ |
| 19 | `/usuarios/{id}` | GET | ✅ | ✅ | ✅ | ✅ | ✅ |
| 20 | `/usuarios` | GET | ❌ | ❌ | ❌ | ✅ | ❌ |
| 21 | `/recomendaciones/productos` | POST | ✅ | ❌ | ❌ | ✅ | ❌ |

---

## 👤 CLIENTE - Permisos Detallados

### ✅ PUEDE:
- **Autenticación:** Login, registro, cambiar password
- **Productos:** Ver lista, ver detalle, recibir recomendaciones
- **Pedidos:** 
  - ✅ Crear pedidos (EXCLUSIVO)
  - ✅ Ver sus propios pedidos
  - ❌ NO puede ver pedidos de otros
- **Ubicaciones:** Ver y crear sus ubicaciones
- **Tracking:** Ver tracking de sus pedidos
- **Chat:** Chat con delivery, chat con IA bot, chat con soporte

### ❌ NO PUEDE:
- Ver pedidos de otros usuarios
- Crear productos
- Ver lista completa de usuarios
- Ver pedidos de negocios o deliveries
- Gestionar productos de negocios

---

## 🏍️ DELIVERY - Permisos Detallados

### ✅ PUEDE:
- **Autenticación:** Login, cambiar password
- **Pedidos:**
  - ✅ Ver pedidos asignados a él
  - ✅ Actualizar estado de pedidos
  - ❌ NO puede crear pedidos
  - ❌ NO puede ver pedidos de clientes o negocios
- **Ubicaciones:** Ver y actualizar su ubicación GPS
- **Tracking:** Ver tracking de pedidos asignados
- **Chat:** Chat con cliente durante entrega
- **Productos:** Solo ver lista (no agregar al carrito)

### ❌ NO PUEDE:
- Crear pedidos
- Ver productos para "agregar al carrito"
- Gestionar productos
- Ver pedidos de otros deliveries
- Ver lista completa de usuarios

---

## 🏪 NEGOCIO - Permisos Detallados

### ✅ PUEDE:
- **Autenticación:** Login, registro con datos comerciales, cambiar password
- **Productos:**
  - ✅ Crear productos en su negocio
  - ✅ Editar productos de su negocio
  - ✅ Eliminar productos de su negocio
  - ❌ NO puede modificar productos de otros negocios
- **Pedidos:**
  - ✅ Ver pedidos de su negocio
  - ✅ Actualizar estado (Preparando → Listo)
  - ❌ NO puede ver pedidos de otros negocios
- **Chat:** Chat con soporte
- **Estadísticas:** Ver ventas y métricas de su negocio

### ❌ NO PUEDE:
- Crear pedidos
- Ver productos de otros negocios con intención de modificar
- Ver pedidos de clientes o deliveries
- Ver tracking de rutas
- Chat con IA bot

---

## 👨‍💼 ADMIN - Permisos Detallados

### ✅ PUEDE TODO:
- **Acceso completo** a todos los endpoints
- **Ver todos los usuarios** de todos los roles
- **Ver todos los negocios** del sistema
- **Ver todos los pedidos** sin restricción
- **Gestionar productos** de cualquier negocio
- **Crear/Editar/Eliminar** cualquier recurso
- **Ver estadísticas** del sistema completo
- **Acceso total** sin restricciones

### 🔐 Permisos Especiales:
- Puede actuar como cualquier rol
- Acceso a endpoints administrativos
- Sin validación de "pertenencia" (puede ver/editar todo)

---

## 🎧 SOPORTE - Permisos Detallados

### ✅ PUEDE:
- **Autenticación:** Login, cambiar password
- **Chat:**
  - ✅ Ver conversaciones de soporte
  - ✅ Responder tickets
  - ✅ Usar respuestas predefinidas
- **Usuarios:** Ver perfil de usuarios que piden soporte
- **Productos:** Ver lista de productos (solo lectura)

### ❌ NO PUEDE:
- Gestionar productos
- Crear pedidos
- Ver pedidos de otros usuarios
- Acceso a tracking
- Chat con IA bot
- Gestionar negocios
- Acceso a endpoints administrativos

---

## 🎯 REGLAS DE VALIDACIÓN EN EL BACKEND

### Por Endpoint:

#### POST /pedidos
```java
// Solo CLIENTE puede crear pedidos
if (usuario.getRol() != Roles.CLIENTE && usuario.getRol() != Roles.ADMIN) {
    throw new ForbiddenException("Solo clientes pueden crear pedidos");
}
```

#### POST /admin/productos
```java
// Solo ADMIN y NEGOCIO pueden crear productos
if (usuario.getRol() != Roles.ADMIN && usuario.getRol() != Roles.NEGOCIO) {
    throw new ForbiddenException("No autorizado");
}

// NEGOCIO solo puede crear en su propio negocio
if (usuario.getRol() == Roles.NEGOCIO) {
    if (producto.getIdNegocio() != usuario.getIdNegocio()) {
        throw new ForbiddenException("Solo puede crear productos en su negocio");
    }
}
```

#### GET /pedidos/cliente/{id}
```java
// Solo el CLIENTE dueño o ADMIN pueden ver
if (usuario.getRol() == Roles.CLIENTE && usuario.getId() != id) {
    throw new ForbiddenException("Solo puede ver sus propios pedidos");
}
```

#### GET /pedidos/delivery/{id}
```java
// Solo el DELIVERY asignado o ADMIN pueden ver
if (usuario.getRol() == Roles.DELIVERY && usuario.getId() != id) {
    throw new ForbiddenException("Solo puede ver sus pedidos asignados");
}
```

#### GET /pedidos/negocio/{id}
```java
// Solo el NEGOCIO dueño o ADMIN pueden ver
if (usuario.getRol() == Roles.NEGOCIO && usuario.getIdNegocio() != id) {
    throw new ForbiddenException("Solo puede ver pedidos de su negocio");
}
```

---

## 🧪 CASOS DE PRUEBA RECOMENDADOS

### Test 1: Cliente intenta crear producto
```
POST /admin/productos
Token: cliente
Resultado esperado: 403 Forbidden
```

### Test 2: Delivery intenta crear pedido
```
POST /pedidos
Token: delivery
Resultado esperado: 403 Forbidden
```

### Test 3: Negocio intenta ver pedidos de cliente
```
GET /pedidos/cliente/1
Token: negocio
Resultado esperado: 403 Forbidden
```

### Test 4: Soporte intenta gestionar productos
```
POST /admin/productos
Token: soporte
Resultado esperado: 403 Forbidden
```

### Test 5: Admin accede a todo
```
GET /usuarios
POST /admin/productos
GET /pedidos/cliente/1
Token: admin
Resultado esperado: 200 OK (todos)
```

---

## 📝 NOTAS IMPORTANTES

1. **ADMIN tiene acceso total** - No hay restricciones para este rol
2. **CLIENTE es el único que puede crear pedidos** - Función exclusiva
3. **NEGOCIO solo gestiona sus productos** - No puede ver/editar otros negocios
4. **DELIVERY solo ve sus pedidos asignados** - No puede crear pedidos
5. **SOPORTE tiene acceso limitado** - Solo chat y consultas
6. **Tokens deben validarse en cada endpoint** - Sin token = 401 Unauthorized
7. **Roles deben validarse después de autenticar** - Token válido ≠ permiso automático

---

*Fecha: 2025-11-07*  
*Basado en: FUNCIONES_ROLES.md + DOCUMENTACION_API.md*
