"""
Script para crear usuarios de NEGOCIO y SOPORTE en la base de datos
Usa el endpoint /registro de la API
"""
import requests
import json

API_BASE = "http://18.217.51.221:7070"

def crear_usuario(nombre, correo, password, rol):
    """Registra un nuevo usuario"""
    url = f"{API_BASE}/registro"
    data = {
        "nombre": nombre,
        "correo": correo,
        "contrasena": password,  # Campo correcto según API
        "rol": rol
    }
    
    print(f"\n🔄 Creando usuario: {nombre} ({rol})...")
    print(f"📧 Correo: {correo}")
    
    try:
        resp = requests.post(url, json=data, timeout=15)
        
        if resp.status_code == 200 or resp.status_code == 201:
            print(f"✅ Usuario creado exitosamente!")
            print(f"📄 Respuesta: {resp.json()}")
            return True
        else:
            print(f"❌ Error {resp.status_code}: {resp.text}")
            return False
    except Exception as e:
        print(f"❌ Excepción: {e}")
        return False

def verificar_login(correo, password):
    """Verifica que el usuario puede hacer login"""
    url = f"{API_BASE}/auth/login"
    data = {
        "correo": correo,
        "password": password  # Login usa "password" no "contrasena"
    }
    
    print(f"\n🔐 Verificando login para {correo}...")
    
    try:
        resp = requests.post(url, json=data, timeout=15)
        
        if resp.status_code == 200:
            data = resp.json()
            token = data.get('token') or data.get('data', {}).get('token')
            print(f"✅ Login exitoso! Token obtenido: {token[:30]}...")
            return True
        else:
            print(f"❌ Login falló: {resp.status_code} - {resp.text}")
            return False
    except Exception as e:
        print(f"❌ Excepción: {e}")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("🚀 CREACIÓN DE USUARIOS DE PRUEBA - NEGOCIO Y SOPORTE")
    print("=" * 60)
    
    # Crear usuario NEGOCIO
    print("\n📦 1. USUARIO NEGOCIO")
    print("-" * 60)
    negocio_ok = crear_usuario(
        nombre="Maria Negocio",
        correo="maria.negocio@example.com",
        password="Negocio123!",
        rol="negocio"
    )
    
    if negocio_ok:
        verificar_login("maria.negocio@example.com", "Negocio123!")
    
    # Crear usuario SOPORTE
    print("\n📦 2. USUARIO SOPORTE")
    print("-" * 60)
    soporte_ok = crear_usuario(
        nombre="Juan Soporte",
        correo="juan.soporte@example.com",
        password="Soporte123!",
        rol="soporte"
    )
    
    if soporte_ok:
        verificar_login("juan.soporte@example.com", "Soporte123!")
    
    # Resumen
    print("\n" + "=" * 60)
    print("📊 RESUMEN")
    print("=" * 60)
    print(f"Usuario NEGOCIO: {'✅ Creado' if negocio_ok else '❌ Error'}")
    print(f"Usuario SOPORTE: {'✅ Creado' if soporte_ok else '❌ Error'}")
    
    if negocio_ok and soporte_ok:
        print("\n✅ TODOS LOS USUARIOS CREADOS EXITOSAMENTE!")
        print("\n📝 Credenciales:")
        print("   Negocio: maria.negocio@example.com / Negocio123!")
        print("   Soporte: juan.soporte@example.com / Soporte123!")
    else:
        print("\n⚠️ Algunos usuarios no se pudieron crear")
        print("Puede que ya existan en la base de datos")
    
    print("=" * 60)
