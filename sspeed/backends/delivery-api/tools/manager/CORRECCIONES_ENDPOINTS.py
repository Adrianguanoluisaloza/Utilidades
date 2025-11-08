"""
CORRECCIONES DE ENDPOINTS - Unite Speed GUI
Este archivo documenta los errores encontrados y las correcciones aplicadas
"""

# ============= ERRORES DETECTADOS EN LA PRIMERA EJECUCIÓN =============

"""
ERRORES ENCONTRADOS:
1. ❌ #2 - POST /auth/registro (404)
   Problema: Ruta incorrecta, debe ser /registro (sin /auth)
   Datos: Usaba 'email' en vez de 'correo'
   
2. ❌ #4 - PUT /auth/cambiar-password (400)
   Problema: Método incorrecto, debe ser POST
   
3. ❌ #8 - POST /admin/productos (500)
   Problema: Faltan campos requeridos (descripcion, disponible, imagenUrl)
   
4. ❌ #12 - POST /pedidos (400)
   Problema: Formato incorrecto, usa 'items' en vez de 'productos'
"""

# ============= ENDPOINTS CORREGIDOS =============

ENDPOINTS_CORREGIDOS = {
    "registro": {
        "ruta_incorrecta": "/auth/registro",
        "ruta_correcta": "/registro",
        "metodo": "POST",
        "datos_incorrectos": {
            "nombre": "Test",
            "email": "test@test.com",  # ❌ Debe ser 'correo'
            "password": "123456",
            "rol": "cliente"
        },
        "datos_correctos": {
            "nombre": "Test Usuario",
            "correo": "test@test.com",  # ✅ 'correo' no 'email'
            "password": "123456",
            "rol": "cliente"
        }
    },
    
    "cambiar_password": {
        "ruta": "/auth/cambiar-password",
        "metodo_incorrecto": "PUT",
        "metodo_correcto": "POST",
        "datos": {
            "passwordActual": "Cliente123!",
            "nuevaPassword": "Cliente123!"
        },
        "nota": "Requiere token de autenticación"
    },
    
    "crear_producto": {
        "ruta": "/admin/productos",
        "metodo": "POST",
        "datos_incorrectos": {
            "nombre": "Test",
            "precio": 10,
            "categoria": "Test",
            "idNegocio": 1
        },
        "datos_correctos": {
            "nombre": "Producto Test",
            "descripcion": "Descripción del producto",  # ✅ Campo requerido
            "precio": 10.50,
            "categoria": "Test",
            "disponible": True,  # ✅ Campo requerido
            "idNegocio": 1,
            "imagenUrl": "https://ejemplo.com/img.jpg"  # Opcional pero recomendado
        },
        "nota": "Requiere rol ADMIN"
    },
    
    "crear_pedido": {
        "ruta": "/pedidos",
        "metodo": "POST",
        "datos_incorrectos": {
            "idUsuario": 1,
            "idNegocio": 1,
            "items": [{"idProducto": 1, "cantidad": 1}],  # ❌ Debe ser 'productos'
            "direccionEntrega": "Test",
            "latitud": 0.98,
            "longitud": -79.65
        },
        "datos_correctos": {
            "idUsuario": 1,  # Opcional, se toma del token
            "idNegocio": 1,
            "productos": [{"idProducto": 1, "cantidad": 1}],  # ✅ 'productos' no 'items'
            "direccionEntrega": "Av. Test 123",
            "latitud": 0.9825,
            "longitud": -79.6532
        },
        "nota": "Requiere token de autenticación (CLIENTE)"
    }
}

# ============= ROLES REQUERIDOS POR ENDPOINT =============

ROLES_ENDPOINTS = {
    # Sin autenticación
    "publicos": [
        "/health",
        "/productos",
        "/productos/{id}",
        "/auth/login",
        "/registro",
        "/auth/reset/generar"
    ],
    
    # Requieren autenticación (cualquier rol)
    "autenticados": [
        "/auth/cambiar-password",
        "/usuarios/{id}",
        "/chat/bot/mensajes",
        "/chat/conversaciones/{id}",
        "/ubicaciones/usuario/{id}",
        "/ubicaciones"
    ],
    
    # Solo CLIENTE
    "cliente": [
        "/pedidos",  # Crear pedido
        "/pedidos/cliente/{id}",
        "/tracking/pedido/{id}",
        "/recomendaciones/productos"
    ],
    
    # Solo ADMIN
    "admin": [
        "/admin/productos",  # Crear
        "/admin/productos/{id}",  # Actualizar
        "/usuarios",  # Listar todos
        "/negocios",
        "/negocios/{id}"
    ],
    
    # Solo DELIVERY
    "delivery": [
        "/pedidos/delivery/{id}",
        "/pedidos/{id}/asignar",
        "/pedidos/{id}/ubicacion-actual"
    ],
    
    # Solo NEGOCIO
    "negocio": [
        "/pedidos/negocio/{id}",
        "/productos",  # Crear productos de su negocio
        "/negocios/{id}/productos"
    ]
}

# ============= MENSAJES DE ERROR COMUNES =============

ERRORES_COMUNES = {
    400: "Bad Request - Datos incorrectos o faltantes",
    401: "Unauthorized - Token faltante o inválido",
    403: "Forbidden - Permisos insuficientes (rol incorrecto)",
    404: "Not Found - Endpoint o recurso no encontrado",
    500: "Internal Server Error - Error en el servidor"
}

# ============= TIPS PARA DEBUGGING =============

DEBUGGING_TIPS = """
🔍 TIPS PARA DEBUGGING DE ENDPOINTS:

1. ERROR 404:
   - Verificar que la ruta sea exacta (con/sin /auth, etc.)
   - Verificar método HTTP (GET/POST/PUT/DELETE)
   
2. ERROR 400:
   - Revisar nombres de campos (correo vs email, productos vs items)
   - Verificar tipos de datos (string, number, boolean)
   - Revisar campos requeridos vs opcionales
   
3. ERROR 401:
   - Verificar que el token esté en el header
   - Formato: Authorization: Bearer {token}
   - Verificar que el token no haya expirado
   
4. ERROR 403:
   - Verificar que el rol del usuario sea el correcto
   - Admin para /admin/*, Cliente para /pedidos, etc.
   
5. ERROR 500:
   - Revisar logs del servidor
   - Puede ser error de validación en backend
   - Puede ser error de base de datos

COMANDOS ÚTILES:
- Ver logs: docker logs delivery-api --tail 100
- Reiniciar: docker restart delivery-api
- Health check: curl http://18.217.51.221:7070/api/health
"""

if __name__ == "__main__":
    print("=" * 70)
    print("  CORRECCIONES DE ENDPOINTS - UNITE SPEED DELIVERY")
    print("=" * 70)
    print()
    
    for nombre, info in ENDPOINTS_CORREGIDOS.items():
        print(f"\n📌 {nombre.upper().replace('_', ' ')}")
        print("-" * 70)
        for key, value in info.items():
            if key.startswith("datos_"):
                print(f"\n  {key}:")
                import json
                print(f"  {json.dumps(value, indent=4)}")
            else:
                print(f"  {key}: {value}")
    
    print("\n" + "=" * 70)
    print(DEBUGGING_TIPS)
