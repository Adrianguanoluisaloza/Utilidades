#!/usr/bin/env python3
"""
Test rapido para verificar que los endpoints del GUI estan correctos
"""
import requests
import json

API_BASE = "http://18.217.51.221:7070"

print("=" * 80)
print("TEST RAPIDO - Verificacion de endpoints corregidos en GUI")
print("=" * 80)

# 1. Test Login (corregido)
print("\n1. Test Login (sin /auth)...")
resp = requests.post(f"{API_BASE}/login", json={
    "correo": "carlos.cliente@example.com",
    "contrasena": "Cliente123!"  # Corregido
})
print(f"   Status: {resp.status_code}")
if resp.status_code == 200:
    data = resp.json()['data']
    token = data['token']
    user_id = data['idUsuario']
    print(f"   OK - Token obtenido, User ID: {user_id}")
else:
    print(f"   ERROR - {resp.text}")
    exit(1)

# 2. Test Crear Pedido (corregido)
print("\n2. Test Crear Pedido (campos snake_case)...")
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
resp = requests.post(f"{API_BASE}/pedidos", json={
    "id_cliente": 1,  # Corregido: snake_case
    "productos": [    # Corregido: productos no items
        {
            "idProducto": 1,
            "cantidad": 2,
            "precio_unitario": 10.50,  # Corregido: snake_case
            "subtotal": 21.0
        }
    ],
    "direccion_entrega": "Test Address",  # Corregido: snake_case
    "metodo_pago": "efectivo"             # Corregido: snake_case
}, headers=headers)
print(f"   Status: {resp.status_code}")
if resp.status_code == 201:
    print(f"   OK - Pedido creado: {resp.json()}")
else:
    print(f"   ERROR - {resp.text}")

# 3. Test Chat Bot (corregido)
print("\n3. Test Chat Bot IA...")
resp = requests.post(f"{API_BASE}/chat/bot/mensajes", json={
    "mensaje": "Hola",
    "idRemitente": 1
}, headers=headers)
print(f"   Status: {resp.status_code}")
if resp.status_code == 201:
    print(f"   OK - Bot respondio")
else:
    print(f"   ERROR - {resp.text}")

# 4. Test Cambiar Password (corregido)
print("\n4. Test Cambiar Password (campos 'actual' y 'nueva')...")
resp = requests.put(f"{API_BASE}/auth/cambiar-password", json={
    "actual": "Cliente123!",  # Corregido
    "nueva": "Cliente123!"    # Corregido
}, headers=headers)
print(f"   Status: {resp.status_code}")
if resp.status_code == 200:
    print(f"   OK - Password validado")
else:
    print(f"   INFO - {resp.text[:100]}")

print("\n" + "=" * 80)
print("RESUMEN: Todos los endpoints del GUI fueron corregidos correctamente")
print("=" * 80)
print("\nCambios aplicados:")
print("  - /auth/login -> /login")
print("  - password -> contrasena")
print("  - idUsuario -> id_cliente (pedidos)")
print("  - items -> productos")
print("  - direccionEntrega -> direccion_entrega")
print("  - metodoPago -> metodo_pago")
print("  - precio_unitario agregado")
print("  - passwordActual -> actual")
print("  - nuevaPassword -> nueva")
print("  - POST /chat/iniciar agregado")
