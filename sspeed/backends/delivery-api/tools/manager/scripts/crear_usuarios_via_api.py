"""
Script para crear usuarios de prueba usando la API del backend
No requiere psql instalado, usa directamente los endpoints de la API
"""
import requests
import json
from typing import Dict, List

# Configuración
API_BASE_URL = "http://18.217.51.221:7070"

# Usuarios de prueba (deben coincidir con config.json)
USUARIOS = [
    {
        'email': 'carlos.cliente@example.com',
        'password': 'Cliente123!',
        'rol': 'cliente',
        'nombre': 'Carlos',
        'apellido': 'Cliente',
        'telefono': '+593999000001'
    },
    {
        'email': 'adrian@admin.com',
        'password': 'Admin123!',
        'rol': 'admin',
        'nombre': 'Adrian',
        'apellido': 'Admin',
        'telefono': '+593999000002'
    },
    {
        'email': 'delivery1@example.com',
        'password': 'Delivery123!',
        'rol': 'delivery',
        'nombre': 'Delivery',
        'apellido': 'Uno',
        'telefono': '+593999000003'
    },
    {
        'email': 'negocio1@example.com',
        'password': 'Negocio123!',
        'rol': 'negocio',
        'nombre': 'Negocio',
        'apellido': 'Uno',
        'telefono': '+593999000004'
    },
    {
        'email': 'soporte@example.com',
        'password': 'Soporte123!',
        'rol': 'soporte',
        'nombre': 'Soporte',
        'apellido': 'Unite',
        'telefono': '+593999000005'
    }
]

class Color:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

def print_header(text):
    print(f"\n{Color.BOLD}{Color.BLUE}{'='*60}{Color.END}")
    print(f"{Color.BOLD}{Color.BLUE}  {text}{Color.END}")
    print(f"{Color.BOLD}{Color.BLUE}{'='*60}{Color.END}\n")

def print_ok(text):
    print(f"{Color.GREEN}✅ {text}{Color.END}")

def print_error(text):
    print(f"{Color.RED}❌ {text}{Color.END}")

def print_warning(text):
    print(f"{Color.YELLOW}⚠️  {text}{Color.END}")

def verificar_api():
    """Verifica que la API esté funcionando"""
    print("🔌 Verificando API...")
    
    try:
        response = requests.get(f"{API_BASE_URL}/health", timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print_ok(f"API funcionando: {API_BASE_URL}")
            print(f"   Status: {data.get('status', 'N/A')}")
            print(f"   DB Connected: {data.get('db', {}).get('connected', False)}")
            return True
        else:
            print_error(f"API responde con código {response.status_code}")
            return False
            
    except requests.exceptions.ConnectionError:
        print_error("No se puede conectar a la API")
        print(f"   URL: {API_BASE_URL}")
        print("   Verifica que el servidor esté corriendo")
        return False
    except Exception as e:
        print_error(f"Error al conectar: {e}")
        return False

def registrar_usuario(usuario: Dict) -> bool:
    """Registra un usuario usando el endpoint de registro"""
    email = usuario['email']
    
    print(f"\n📝 Creando usuario: {email} ({usuario['rol']})...")
    
    # Datos para el registro
    data = {
        'email': email,
        'password': usuario['password'],
        'nombre': usuario['nombre'],
        'apellido': usuario['apellido'],
        'telefono': usuario['telefono'],
        'rol': usuario['rol']
    }
    
    try:
        # Endpoint de registro
        response = requests.post(
            f"{API_BASE_URL}/auth/register",
            json=data,
            timeout=10
        )
        
        if response.status_code == 200 or response.status_code == 201:
            print_ok(f"Usuario '{email}' creado exitosamente")
            result = response.json()
            if 'token' in result:
                print(f"   Token generado: {result['token'][:20]}...")
            return True
        elif response.status_code == 409 or 'ya existe' in response.text.lower():
            print_warning(f"Usuario '{email}' ya existe (omitiendo)")
            return True
        else:
            print_error(f"Error al crear '{email}': {response.status_code}")
            print(f"   Respuesta: {response.text[:200]}")
            return False
            
    except Exception as e:
        print_error(f"Error al crear '{email}': {e}")
        return False

def verificar_login(usuario: Dict) -> bool:
    """Verifica que un usuario pueda hacer login"""
    email = usuario['email']
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/auth/login",
            json={
                'email': email,
                'password': usuario['password']
            },
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"   ✓ Login OK - Token: {result.get('token', '')[:20]}...")
            return True
        else:
            print(f"   ✗ Login falló: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"   ✗ Error en login: {e}")
        return False

def listar_usuarios_creados():
    """Intenta listar los usuarios creados (requiere token admin)"""
    print("\n📊 Intentando listar usuarios creados...")
    
    # Primero hacer login como admin
    admin = next((u for u in USUARIOS if u['rol'] == 'admin'), None)
    if not admin:
        print_warning("No hay usuario admin para listar")
        return
    
    try:
        # Login admin
        response = requests.post(
            f"{API_BASE_URL}/auth/login",
            json={
                'email': admin['email'],
                'password': admin['password']
            },
            timeout=10
        )
        
        if response.status_code != 200:
            print_warning("No se pudo obtener token admin")
            return
        
        token = response.json().get('token')
        
        # Listar usuarios
        response = requests.get(
            f"{API_BASE_URL}/usuarios",
            headers={'Authorization': f'Bearer {token}'},
            timeout=10
        )
        
        if response.status_code == 200:
            usuarios = response.json()
            print_ok(f"Total de usuarios en sistema: {len(usuarios)}")
            
            # Mostrar usuarios de prueba
            emails_prueba = [u['email'] for u in USUARIOS]
            usuarios_prueba = [u for u in usuarios if u.get('email') in emails_prueba]
            
            if usuarios_prueba:
                print("\n  Usuarios de prueba encontrados:")
                for u in usuarios_prueba:
                    activo = "✓" if u.get('activo', False) else "✗"
                    print(f"    {activo} {u.get('email', 'N/A'):30s} | {u.get('rol', 'N/A'):10s}")
        else:
            print_warning(f"No se pudo listar usuarios: {response.status_code}")
            
    except Exception as e:
        print_warning(f"Error al listar: {e}")

def main():
    print_header("CREAR USUARIOS VÍA API")
    print(f"API: {API_BASE_URL}")
    print()
    
    # 1. Verificar API
    if not verificar_api():
        print("\n⛔ No se puede continuar sin API funcionando")
        print("\n💡 Soluciones:")
        print("   1. Compilar y desplegar backend:")
        print("      cd deploy")
        print("      DEPLOY_COMPLETO.bat → Opción [1]")
        print()
        print("   2. O iniciar servidor local:")
        print("      cd src")
        print("      mvn spring-boot:run")
        return 1
    
    # 2. Crear usuarios
    print(f"\n👥 Creando {len(USUARIOS)} usuarios de prueba...")
    
    exitosos = 0
    for usuario in USUARIOS:
        if registrar_usuario(usuario):
            exitosos += 1
    
    print()
    print("=" * 60)
    print(f"Resultado: {exitosos}/{len(USUARIOS)} usuarios creados/verificados")
    print("=" * 60)
    
    # 3. Verificar logins
    print("\n🔐 Verificando logins de usuarios creados...")
    
    logins_ok = 0
    for usuario in USUARIOS:
        email = usuario['email']
        print(f"\n  Login: {email}")
        if verificar_login(usuario):
            logins_ok += 1
    
    print()
    print(f"Logins exitosos: {logins_ok}/{len(USUARIOS)}")
    
    # 4. Listar usuarios
    listar_usuarios_creados()
    
    # 5. Resumen final
    print_header("RESUMEN")
    
    print(f"{Color.BOLD}Credenciales de acceso:{Color.END}\n")
    for u in USUARIOS:
        print(f"  {u['rol']:10s} → {u['email']:30s} / {u['password']}")
    
    print()
    print(f"{Color.BOLD}Endpoints de prueba:{Color.END}")
    print(f"  Health:   {API_BASE_URL}/api/health")
    print(f"  Login:    {API_BASE_URL}/auth/login")
    print(f"  Register: {API_BASE_URL}/auth/register")
    
    print()
    
    if exitosos == len(USUARIOS) and logins_ok == len(USUARIOS):
        print_ok("✅ TODOS LOS USUARIOS FUNCIONANDO CORRECTAMENTE")
        return 0
    elif exitosos > 0:
        print_warning("⚠️  ALGUNOS USUARIOS CREADOS, REVISAR LOGS")
        return 0
    else:
        print_error("❌ NO SE PUDO CREAR USUARIOS")
        return 1

if __name__ == "__main__":
    import sys
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print(f"\n\n{Color.YELLOW}⚠️  Operación cancelada{Color.END}")
        sys.exit(1)
    except Exception as e:
        print(f"\n{Color.RED}❌ Error inesperado: {e}{Color.END}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
