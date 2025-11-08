"""
Script para crear usuarios NEGOCIO y SOPORTE
- NEGOCIO: Usa endpoint /registro (rol permitido)
- SOPORTE: Debe crearse directamente en BD o por admin
"""
import requests
import json

API_BASE = "http://18.217.51.221:7070"

# Credenciales de admin para crear usuario soporte
ADMIN_EMAIL = "ana.admin@example.com"
ADMIN_PASSWORD = "Admin123!"

def obtener_token_admin():
    """Obtiene token de admin"""
    url = f"{API_BASE}/auth/login"
    data = {
        "correo": ADMIN_EMAIL,
        "password": ADMIN_PASSWORD
    }
    
    print("🔐 Obteniendo token de admin...")
    
    try:
        resp = requests.post(url, json=data, timeout=15)
        if resp.status_code == 200:
            data = resp.json()
            token = data.get('token') or data.get('data', {}).get('token')
            print(f"✅ Token admin obtenido: {token[:30]}...")
            return token
        else:
            print(f"❌ Error obteniendo token: {resp.status_code}")
            return None
    except Exception as e:
        print(f"❌ Excepción: {e}")
        return None

def crear_usuario_negocio():
    """Crea usuario NEGOCIO usando endpoint público de registro"""
    url = f"{API_BASE}/registro"
    data = {
        "nombre": "Maria Negocio",
        "correo": "maria.negocio@example.com",
        "contrasena": "Negocio123!",
        "rol": "negocio"
    }
    
    print("\n📦 Creando usuario NEGOCIO...")
    print(f"📧 Correo: maria.negocio@example.com")
    
    try:
        resp = requests.post(url, json=data, timeout=15)
        
        if resp.status_code in [200, 201]:
            print(f"✅ Usuario NEGOCIO creado exitosamente!")
            return True
        elif resp.status_code == 400 and "ya existe" in resp.text.lower():
            print(f"⚠️ Usuario NEGOCIO ya existe en la base de datos")
            return True
        else:
            print(f"❌ Error {resp.status_code}: {resp.text}")
            return False
    except Exception as e:
        print(f"❌ Excepción: {e}")
        return False

def crear_usuario_soporte_directo():
    """
    Crea usuario SOPORTE directamente en la base de datos
    usando psql o mediante inserción SQL directa
    """
    print("\n📦 Usuario SOPORTE...")
    print("⚠️ El endpoint /registro no permite rol 'soporte'")
    print("📝 Opciones:")
    print("   1. Crear manualmente en PostgreSQL")
    print("   2. Usar endpoint de admin (si existe)")
    print("   3. Modificar validación en backend")
    
    # Por ahora, usamos el registro normal con rol "cliente"
    # y luego actualizamos el rol manualmente
    url = f"{API_BASE}/registro"
    data = {
        "nombre": "Juan Soporte",
        "correo": "juan.soporte@example.com",
        "contrasena": "Soporte123!",
        "rol": "cliente"  # Primero creamos como cliente
    }
    
    print("\n🔄 Creando usuario temporal como 'cliente'...")
    
    try:
        resp = requests.post(url, json=data, timeout=15)
        
        if resp.status_code in [200, 201]:
            print(f"✅ Usuario base creado")
            print(f"⚠️ IMPORTANTE: Debes actualizar el rol a 'soporte' en la BD")
            print(f"   SQL: UPDATE usuarios SET id_rol = (SELECT id_rol FROM roles WHERE nombre = 'soporte') WHERE correo = 'juan.soporte@example.com';")
            return "parcial"
        elif resp.status_code == 400 and "ya existe" in resp.text.lower():
            print(f"⚠️ Usuario ya existe en la base de datos")
            return True
        else:
            print(f"❌ Error {resp.status_code}: {resp.text}")
            return False
    except Exception as e:
        print(f"❌ Excepción: {e}")
        return False

def verificar_login(correo, password):
    """Verifica login de usuario"""
    url = f"{API_BASE}/auth/login"
    data = {
        "correo": correo,
        "password": password
    }
    
    print(f"\n🔐 Verificando login para {correo}...")
    
    try:
        resp = requests.post(url, json=data, timeout=15)
        
        if resp.status_code == 200:
            data = resp.json()
            token = data.get('token') or data.get('data', {}).get('token')
            print(f"✅ Login exitoso! Token: {token[:30]}...")
            return True
        else:
            print(f"❌ Login falló: {resp.status_code}")
            return False
    except Exception as e:
        print(f"❌ Excepción: {e}")
        return False

if __name__ == "__main__":
    print("=" * 70)
    print("🚀 CREACIÓN DE USUARIOS DE PRUEBA - NEGOCIO Y SOPORTE")
    print("=" * 70)
    
    # 1. Crear usuario NEGOCIO
    print("\n" + "=" * 70)
    print("1️⃣  USUARIO NEGOCIO")
    print("=" * 70)
    negocio_ok = crear_usuario_negocio()
    
    if negocio_ok:
        verificar_login("maria.negocio@example.com", "Negocio123!")
    
    # 2. Crear usuario SOPORTE (parcial)
    print("\n" + "=" * 70)
    print("2️⃣  USUARIO SOPORTE")
    print("=" * 70)
    soporte_ok = crear_usuario_soporte_directo()
    
    # Resumen
    print("\n" + "=" * 70)
    print("📊 RESUMEN FINAL")
    print("=" * 70)
    print(f"✅ Usuario NEGOCIO: {'Creado' if negocio_ok else 'Error'}")
    print(f"   📧 maria.negocio@example.com / Negocio123!")
    print()
    print(f"⚠️  Usuario SOPORTE: {'Creado parcialmente' if soporte_ok == 'parcial' else ('Creado' if soporte_ok else 'Error')}")
    print(f"   📧 juan.soporte@example.com / Soporte123!")
    
    if soporte_ok == "parcial":
        print("\n" + "=" * 70)
        print("⚠️  ACCIÓN REQUERIDA - ACTUALIZAR ROL DE SOPORTE")
        print("=" * 70)
        print("Ejecuta este comando SQL en PostgreSQL:")
        print()
        print("UPDATE usuarios")
        print("SET id_rol = (SELECT id_rol FROM roles WHERE nombre = 'soporte')")
        print("WHERE correo = 'juan.soporte@example.com';")
        print()
        print("O crea un script Python para actualizar usando psycopg2")
        print("=" * 70)
    
    print("\n✅ Proceso completado")
