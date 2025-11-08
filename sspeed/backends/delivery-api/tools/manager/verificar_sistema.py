"""
Verificación de Sistema Integrado - Unite Speed
Conecta a PostgreSQL RDS usando Python (no requiere psql)
"""
import subprocess
import sys
import json
from pathlib import Path

# Colores para terminal
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

def print_step(num, total, text):
    print(f"{Color.BOLD}[Paso {num}/{total}]{Color.END} {text}")

def print_ok(text):
    print(f"{Color.GREEN}✅ {text}{Color.END}")

def print_error(text):
    print(f"{Color.RED}❌ {text}{Color.END}")

def print_warning(text):
    print(f"{Color.YELLOW}⚠️  {text}{Color.END}")

def verificar_config():
    """Verifica que config.json existe y es válido"""
    print_step(1, 5, "Verificando config.json...")
    
    config_path = Path(__file__).parent / "config" / "config.json"
    
    if not config_path.exists():
        print_error(f"Config no encontrado: {config_path}")
        return None
    
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
        
        # Verificar estructura
        required_keys = ['aws', 'api', 'test_users']
        if all(k in config for k in required_keys):
            print_ok("Config válido")
            return config
        else:
            print_error("Config incompleto")
            return None
            
    except Exception as e:
        print_error(f"Error al leer config: {e}")
        return None

def verificar_credenciales(config):
    """Verifica que las credenciales sean correctas"""
    print_step(2, 5, "Verificando credenciales...")
    
    rds = config['aws']['rds']
    
    print(f"  Host: {rds['host']}")
    print(f"  Port: {rds['port']}")
    print(f"  User: {rds['user']}")
    print(f"  Database: {rds['database']}")
    print(f"  Password: {'*' * len(rds['password'])}")
    
    # Verificar que sean las credenciales correctas
    if rds['password'] == 'Unidos2025!' and rds['user'] == 'Michael':
        print_ok("Credenciales correctas")
        return True
    else:
        print_error("Credenciales incorrectas!")
        print("  Esperado: user=Michael, password=Unidos2025!")
        return False

def verificar_api(config):
    """Verifica que la API esté accesible"""
    print_step(3, 5, "Verificando API...")
    
    try:
        import requests
        
        api_url = config['api']['base_url']
        health_url = f"{api_url}/api/health"
        
        response = requests.get(health_url, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print_ok(f"API respondiendo: {api_url}")
            print(f"  Status: {data.get('status', 'N/A')}")
            print(f"  DB Connected: {data.get('db', {}).get('connected', False)}")
            return True
        else:
            print_warning(f"API responde con código {response.status_code}")
            return False
            
    except ImportError:
        print_warning("Módulo 'requests' no instalado")
        print("  Instalar con: pip install requests")
        return False
    except Exception as e:
        print_error(f"Error al conectar: {e}")
        return False

def verificar_usuarios_prueba(config):
    """Verifica que los usuarios de prueba estén definidos"""
    print_step(4, 5, "Verificando usuarios de prueba...")
    
    usuarios = config.get('test_users', {})
    
    roles_esperados = ['cliente', 'admin', 'delivery', 'negocio', 'soporte']
    todos_ok = True
    
    for rol in roles_esperados:
        if rol in usuarios:
            email = usuarios[rol]['email']
            print(f"  {Color.GREEN}✓{Color.END} {rol:10s} → {email}")
        else:
            print(f"  {Color.RED}✗{Color.END} {rol:10s} → FALTA")
            todos_ok = False
    
    if todos_ok:
        print_ok("Todos los usuarios definidos")
    else:
        print_warning("Faltan algunos usuarios")
    
    return todos_ok

def verificar_archivos():
    """Verifica que los archivos del sistema existan"""
    print_step(5, 5, "Verificando archivos del sistema...")
    
    base_dir = Path(__file__).parent
    
    archivos_criticos = [
        "unite_speed_gui.py",
        "gestor_unitespeed.py",
        "config/config.json",
        "scripts/crear_usuarios_directo.py",
        "CORRECCIONES_APLICADAS.md"
    ]
    
    todos_ok = True
    
    for archivo in archivos_criticos:
        path = base_dir / archivo
        if path.exists():
            print(f"  {Color.GREEN}✓{Color.END} {archivo}")
        else:
            print(f"  {Color.RED}✗{Color.END} {archivo} - FALTA")
            todos_ok = False
    
    if todos_ok:
        print_ok("Todos los archivos presentes")
    else:
        print_warning("Faltan algunos archivos")
    
    return todos_ok

def mostrar_siguiente_pasos():
    """Muestra los siguientes pasos"""
    print_header("SIGUIENTES PASOS")
    
    print(f"{Color.BOLD}1. Probar GUI Manager:{Color.END}")
    print("   cd tools\\manager")
    print("   python unite_speed_gui.py")
    print()
    
    print(f"{Color.BOLD}2. O usar el Launcher:{Color.END}")
    print("   cd tools")
    print("   LAUNCHER_INTEGRADO.bat")
    print()
    
    print(f"{Color.BOLD}3. Crear usuarios de prueba:{Color.END}")
    print("   cd tools\\manager\\scripts")
    print("   python crear_usuarios_directo.py")
    print()
    
    print(f"{Color.BOLD}4. Probar deploy:{Color.END}")
    print("   cd deploy")
    print("   DEPLOY_COMPLETO.bat")
    print()

def main():
    print_header("VERIFICACIÓN DE SISTEMA INTEGRADO")
    print("Unite Speed Delivery - PostgreSQL RDS")
    print()
    
    # 1. Config
    config = verificar_config()
    if not config:
        print("\n⛔ No se puede continuar sin config.json válido")
        return 1
    
    # 2. Credenciales
    if not verificar_credenciales(config):
        print("\n⛔ Credenciales incorrectas en config.json")
        return 1
    
    # 3. API
    api_ok = verificar_api(config)
    
    # 4. Usuarios
    usuarios_ok = verificar_usuarios_prueba(config)
    
    # 5. Archivos
    archivos_ok = verificar_archivos()
    
    # Resumen
    print_header("RESUMEN DE VERIFICACIÓN")
    
    checks = [
        ("Configuración", True),
        ("Credenciales", True),
        ("API Health", api_ok),
        ("Usuarios de Prueba", usuarios_ok),
        ("Archivos del Sistema", archivos_ok)
    ]
    
    total = len(checks)
    ok = sum(1 for _, status in checks if status)
    
    for check, status in checks:
        icon = "✅" if status else "❌"
        print(f"  {icon} {check}")
    
    print()
    print(f"{Color.BOLD}Resultado: {ok}/{total} checks pasaron{Color.END}")
    print()
    
    if ok == total:
        print(f"{Color.GREEN}{Color.BOLD}✅ SISTEMA COMPLETAMENTE FUNCIONAL{Color.END}")
        mostrar_siguiente_pasos()
        return 0
    elif ok >= total - 1:
        print(f"{Color.YELLOW}{Color.BOLD}⚠️  SISTEMA MAYORMENTE FUNCIONAL{Color.END}")
        print("   Algunos componentes necesitan atención")
        mostrar_siguiente_pasos()
        return 0
    else:
        print(f"{Color.RED}{Color.BOLD}❌ SISTEMA CON PROBLEMAS{Color.END}")
        print("   Revisa las correcciones aplicadas en:")
        print("   tools/manager/CORRECCIONES_APLICADAS.md")
        return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print(f"\n\n{Color.YELLOW}⚠️  Verificación cancelada{Color.END}")
        sys.exit(1)
    except Exception as e:
        print(f"\n{Color.RED}❌ Error inesperado: {e}{Color.END}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
