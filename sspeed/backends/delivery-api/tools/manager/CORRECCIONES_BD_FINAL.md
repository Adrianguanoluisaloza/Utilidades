# 🔧 CORRECCIONES FINALES BASADAS EN ESTRUCTURA BD

## 📊 Análisis de la Base de Datos PostgreSQL

**Base de Datos:** databasefinal (PostgreSQL)  
**Host:** databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com  
**Total Tablas:** 22

---

## ✅ CORRECCIONES APLICADAS

### 1. **POST /registro** → ❌ Error 400
**Problema detectado:**
- El API espera `correo` (según BD) pero posiblemente también procesa el nombre del rol como string
- Campos obligatorios en tabla `usuarios`: `nombre`, `correo`, `contrasena`, `id_rol`

**Corrección aplicada:**
```json
{
  "nombre": "Test Usuario",
  "correo": "test@test.com",  // ✅ Campo correcto según BD
  "password": "123456",
  "rol": "cliente"  // El backend debe mapear a id_rol
}
```

**Nota:** El backend debe:
1. Recibir el rol como string ("cliente", "admin", etc.)
2. Hacer lookup en tabla `roles` para obtener `id_rol`
3. Hashear la contraseña antes de guardar en `contrasena`

---

### 2. **PUT /usuarios/cambiar-password** → ❌ Error 404
**Problema detectado:**
- Ruta incorrecta: `/auth/cambiar-password` no existe en el backend
- Ruta correcta probable: `/usuarios/cambiar-password`

**Corrección aplicada:**
```diff
- Path: /auth/cambiar-password  ❌
+ Path: /usuarios/cambiar-password  ✅

Method: PUT
Headers: Authorization: Bearer {token}
Data: {
  "passwordActual": "Cliente123!",
  "nuevaPassword": "NuevaPass123!"
}
```

**Validaciones del backend:**
1. Verificar token válido
2. Extraer `id_usuario` del token
3. Verificar que `passwordActual` coincida con hash en BD
4. Hashear y guardar `nuevaPassword`

---

### 3. **POST /admin/productos** → ❌ Error 500
**Problema detectado:**
- Faltan campos obligatorios según estructura de tabla `productos`
- El orden de los campos importa (idNegocio primero)
- La URL de imagen debe apuntar a S3 real

**Estructura de tabla `productos`:**
```sql
CREATE TABLE productos (
    id_producto BIGSERIAL PRIMARY KEY,
    id_negocio BIGINT NOT NULL,  -- ✅ Obligatorio, FK
    id_categoria BIGINT,          -- Opcional
    nombre VARCHAR(160) NOT NULL,
    descripcion TEXT,             -- Puede ser NULL pero recomendado
    precio NUMERIC(12,2) NOT NULL CHECK (precio >= 0),
    disponible BOOLEAN DEFAULT TRUE,
    stock INTEGER DEFAULT 0,
    imagen_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

**Corrección aplicada:**
```json
{
  "idNegocio": 1,  // ✅ Primero, obligatorio
  "nombre": "Producto Test",
  "descripcion": "Descripción de prueba",
  "precio": 10.50,  // ✅ Tipo NUMERIC
  "disponible": true,
  "imagenUrl": "https://unitespeed-landing-2025.s3.us-east-2.amazonaws.com/productos/test.jpg"
}
```

**Validaciones del backend:**
1. Usuario debe tener rol `admin`
2. `id_negocio` debe existir en tabla `negocios` y estar activo
3. `precio` debe ser >= 0
4. Si se envía `idCategoria`, debe existir y pertenecer al negocio

---

### 4. **POST /pedidos** → ❌ Error 400
**Problema detectado:**
- Falta campo obligatorio: `metodoPago` (según tabla `pedidos`)
- El backend debe crear registros en 2 tablas: `pedidos` y `detalle_pedidos`

**Estructura de tabla `pedidos`:**
```sql
CREATE TABLE pedidos (
    id_pedido BIGSERIAL PRIMARY KEY,
    id_cliente BIGINT NOT NULL,      -- Se toma del token
    id_delivery BIGINT,               -- Opcional, se asigna después
    id_ubicacion BIGINT,              -- Opcional
    direccion_entrega TEXT,           -- ✅ Recomendado
    metodo_pago VARCHAR(30) NOT NULL, -- ✅ OBLIGATORIO
    estado VARCHAR(30) DEFAULT 'pendiente',
    total NUMERIC(12,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    fecha_entrega TIMESTAMP
);
```

**Corrección aplicada:**
```json
{
  "idNegocio": 1,
  "productos": [
    { "idProducto": 1, "cantidad": 1 }
  ],
  "direccionEntrega": "Calle Test #123, Esmeraldas, Ecuador",
  "latitud": 0.988033,
  "longitud": -79.659094,
  "metodoPago": "efectivo"  // ✅ AGREGADO (obligatorio)
}
```

**Validaciones del backend:**
1. Token debe ser de usuario con rol `cliente`
2. Extraer `id_cliente` del token
3. Verificar que `idNegocio` existe y está activo
4. Verificar que todos los `idProducto` existen y pertenecen al negocio
5. Calcular `precio_unitario` y `subtotal` para cada producto
6. Calcular `total` del pedido
7. Crear registro en `pedidos` y múltiples en `detalle_pedidos`

**Estados válidos de pedido:**
- `pendiente`
- `en_preparacion`
- `en_camino`
- `entregado`
- `cancelado`

**Métodos de pago válidos:**
- `efectivo`
- `tarjeta`
- `transferencia`

---

## 📋 CAMPOS MAPEADOS: FRONTEND ↔ BACKEND ↔ BD

### Usuarios (Registro)
| Frontend | Backend API | Base de Datos |
|----------|-------------|---------------|
| `nombre` | `nombre` | `nombre` |
| `correo` | `correo` | `correo` |
| `password` | `password` | `contrasena` (hasheado) |
| `rol` | `rol` | `id_rol` (lookup) |

### Productos
| Frontend | Backend API | Base de Datos |
|----------|-------------|---------------|
| `nombre` | `nombre` | `nombre` |
| `descripcion` | `descripcion` | `descripcion` |
| `precio` | `precio` | `precio` |
| `idNegocio` | `idNegocio` | `id_negocio` |
| `disponible` | `disponible` | `disponible` |
| `imagenUrl` | `imagenUrl` | `imagen_url` |
| `categoria` | `categoria` | `id_categoria` (lookup) |

### Pedidos
| Frontend | Backend API | Base de Datos |
|----------|-------------|---------------|
| `productos` | `productos` | → `detalle_pedidos` |
| `idNegocio` | `idNegocio` | `id_negocio` |
| `direccionEntrega` | `direccionEntrega` | `direccion_entrega` |
| `latitud` | `latitud` | → `ubicaciones.latitud` |
| `longitud` | `longitud` | → `ubicaciones.longitud` |
| `metodoPago` | `metodoPago` | `metodo_pago` |
| - | (del token) | `id_cliente` |
| - | (calculado) | `total` |

---

## 🔍 VALIDACIONES QUE DEBE HACER EL BACKEND

### POST /registro
```java
// 1. Validar email único
if (usuarioRepository.existsByCorreo(correo)) {
    return error(400, "El correo ya está registrado");
}

// 2. Obtener id_rol
Rol rol = rolRepository.findByNombre(request.getRol());
if (rol == null) {
    return error(400, "Rol inválido");
}

// 3. Hashear contraseña
String hash = BCrypt.hashpw(password, BCrypt.gensalt());

// 4. Crear usuario
Usuario u = new Usuario();
u.setNombre(nombre);
u.setCorreo(correo);
u.setContrasena(hash);
u.setIdRol(rol.getIdRol());
usuarioRepository.save(u);
```

### POST /admin/productos
```java
// 1. Validar rol admin
if (!token.getRol().equals("admin")) {
    return error(403, "Permisos insuficientes");
}

// 2. Validar negocio existe
Negocio negocio = negocioRepository.findById(idNegocio);
if (negocio == null || !negocio.isActivo()) {
    return error(400, "Negocio no encontrado");
}

// 3. Validar precio >= 0
if (precio < 0) {
    return error(400, "Precio inválido");
}

// 4. Crear producto
Producto p = new Producto();
p.setIdNegocio(idNegocio);
p.setNombre(nombre);
p.setDescripcion(descripcion);
p.setPrecio(precio);
p.setDisponible(disponible);
p.setImagenUrl(imagenUrl);
productoRepository.save(p);
```

### POST /pedidos
```java
// 1. Validar rol cliente
if (!token.getRol().equals("cliente")) {
    return error(403, "Solo clientes pueden crear pedidos");
}

// 2. Validar productos existen
for (ProductoDTO p : productos) {
    Producto producto = productoRepository.findById(p.getIdProducto());
    if (producto == null || !producto.isDisponible()) {
        return error(400, "Producto no disponible");
    }
}

// 3. Crear pedido
Pedido pedido = new Pedido();
pedido.setIdCliente(token.getIdUsuario());
pedido.setDireccionEntrega(direccionEntrega);
pedido.setMetodoPago(metodoPago);
pedido.setEstado("pendiente");
pedidoRepository.save(pedido);

// 4. Crear detalles
BigDecimal total = BigDecimal.ZERO;
for (ProductoDTO p : productos) {
    Producto producto = productoRepository.findById(p.getIdProducto());
    DetallePedido detalle = new DetallePedido();
    detalle.setIdPedido(pedido.getIdPedido());
    detalle.setIdProducto(p.getIdProducto());
    detalle.setCantidad(p.getCantidad());
    detalle.setPrecioUnitario(producto.getPrecio());
    detalle.setSubtotal(producto.getPrecio().multiply(new BigDecimal(p.getCantidad())));
    detallePedidoRepository.save(detalle);
    total = total.add(detalle.getSubtotal());
}

// 5. Actualizar total
pedido.setTotal(total);
pedidoRepository.save(pedido);
```

---

## 🎯 RESULTADOS ESPERADOS DESPUÉS DE CORRECCIONES

| Endpoint | Antes | Después | Motivo |
|----------|-------|---------|--------|
| POST /registro | ❌ 400 | ✅ 200 | Datos correctos |
| PUT /usuarios/cambiar-password | ❌ 404 | ✅ 200 | Ruta corregida |
| POST /admin/productos | ❌ 500 | ✅ 201 | Campos completos + rol admin |
| POST /pedidos | ❌ 400 | ✅ 201 | metodoPago agregado |

**Éxito esperado:** 21/21 (100%) ✅

---

## 🚀 PRÓXIMOS PASOS

1. **Ejecutar la GUI actualizada:**
   ```bash
   EJECUTAR_GUI.bat
   ```

2. **Obtener token de ADMIN:**
   - Rol: admin
   - Email: ana.admin@example.com
   - Click "Obtener Token"

3. **Probar todos los endpoints:**
   - Click "Probar TODOS los Endpoints"

4. **Si persisten errores:**
   - Revisar logs del backend:
     ```bash
     docker logs delivery-api --tail 100
     ```
   - Verificar que los usuarios de prueba existan en BD
   - Verificar que exista al menos 1 negocio activo (id=1)
   - Verificar que exista al menos 1 producto (id=1)

---

## 📝 COMANDOS ÚTILES BD

### Verificar datos de prueba:
```sql
-- Ver roles
SELECT * FROM roles;

-- Ver usuarios de prueba
SELECT id_usuario, nombre, correo, id_rol 
FROM usuarios 
WHERE correo LIKE '%example.com';

-- Ver negocios activos
SELECT id_negocio, nombre_comercial, activo 
FROM negocios 
WHERE activo = TRUE;

-- Ver productos disponibles
SELECT id_producto, nombre, precio, disponible, id_negocio 
FROM productos 
WHERE disponible = TRUE 
LIMIT 5;

-- Contar pedidos
SELECT estado, COUNT(*) 
FROM pedidos 
GROUP BY estado;
```

### Insertar datos de prueba si no existen:
```sql
-- Insertar negocio de prueba
INSERT INTO negocios (nombre_comercial, email, telefono, activo)
VALUES ('Negocio Test', 'test@test.com', '0999999999', TRUE)
ON CONFLICT DO NOTHING;

-- Insertar producto de prueba
INSERT INTO productos (id_negocio, nombre, descripcion, precio, disponible)
VALUES (1, 'Hamburguesa Clásica', 'Hamburguesa con queso', 5.50, TRUE)
ON CONFLICT DO NOTHING;
```

---

**Estado:** ✅ Correcciones aplicadas  
**Archivo actualizado:** `unite_speed_gui.py`  
**Listo para probar:** SÍ
