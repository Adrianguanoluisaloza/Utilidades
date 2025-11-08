"""
╔═══════════════════════════════════════════════════════════╗
║     UNITE SPEED DELIVERY - GESTOR UNIFICADO v1.0         ║
║  Administración centralizada de API, BD, Deploy y Tests  ║
╚═══════════════════════════════════════════════════════════╝

Uso:
  python gestor_unitespeed.py

Características:
  - Reinicio automático del API
  - Pruebas de endpoints con tokens automáticos
  - Deploy a AWS EC2
  - Gestión de base de datos MySQL
  - Logs y reportes centralizados
  - Configuración unificada (no importa desde dónde se ejecute)
"""

import os
import sys
import json
import time
import subprocess
from pathlib import Path
from typing import Optional, Dict, Any

try:
    import requests
except ImportError:
    print("❌ Instalar requests: pip install requests")
    sys.exit(1)

# ============= CONFIGURACIÓN =============
SCRIPT_DIR = Path(__file__).parent
CONFIG_FILE = SCRIPT_DIR / "config" / "config.json"
LOGS_DIR = SCRIPT_DIR / "logs"
REPORTES_DIR = SCRIPT_DIR / "reportes"

# Colores para terminal
class Color:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

# ============= UTILIDADES =============
def cargar_config() -> Dict[str, Any]:
    """Carga configuración desde config.json"""
    if not CONFIG_FILE.exists():
        print(f"{Color.RED}❌ No se encontró config.json en {CONFIG_FILE}{Color.ENDC}")
        sys.exit(1)
    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)

def imprimir_titulo(texto: str):
    """Imprime título decorado"""
    print(f"\n{Color.BOLD}{Color.CYAN}{'='*60}")
    print(f"  {texto}")
    print(f"{'='*60}{Color.ENDC}\n")

def imprimir_exito(texto: str):
    print(f"{Color.GREEN}✅ {texto}{Color.ENDC}")

def imprimir_error(texto: str):
    print(f"{Color.RED}❌ {texto}{Color.ENDC}")

def imprimir_info(texto: str):
    print(f"{Color.CYAN}ℹ️  {texto}{Color.ENDC}")

def imprimir_advertencia(texto: str):
    print(f"{Color.YELLOW}⚠️  {texto}{Color.ENDC}")

def ejecutar_ssh(config: dict, comando: str, timeout: int = 60) -> tuple:
    """Ejecuta comando SSH en EC2"""
    ec2 = config["aws"]["ec2"]
    pem = ec2["pem_path"]
    host = f"{ec2['user']}@{ec2['host']}"
    
    cmd = ["ssh", "-i", pem, "-o", "StrictHostKeyChecking=no", host, comando]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, encoding='utf-8', errors='replace')
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

# ============= FUNCIONES PRINCIPALES =============
def reiniciar_api(config: dict) -> bool:
    """Reinicia el contenedor Docker del API"""
    imprimir_titulo("REINICIO DEL API")
    container = config["api"]["docker_container"]
    
    imprimir_info(f"Reiniciando contenedor '{container}'...")
    ok, out, err = ejecutar_ssh(config, f"sudo docker restart {container}")
    
    if ok:
        imprimir_exito("Contenedor reiniciado")
        imprimir_info("Esperando 8 segundos para estabilizar...")
        time.sleep(8)
        return True
    else:
        imprimir_error(f"Fallo reinicio: {err}")
        return False

def obtener_token(config: dict, rol: str = "cliente") -> Optional[str]:
    """Obtiene token JWT de autenticación"""
    api_base = config["api"]["base_url"]
    user = config["test_users"][rol]
    
    imprimir_info(f"Obteniendo token para {rol}...")
    try:
        resp = requests.post(
            f"{api_base}/auth/login",
            json={"email": user["email"], "password": user["password"]},
            timeout=15
        )
        if resp.status_code == 200:
            data = resp.json()
            token = data.get("token") or data.get("data", {}).get("token")
            if token:
                imprimir_exito(f"Token obtenido: {token[:32]}...")
                return token
        imprimir_error(f"Login fallo ({resp.status_code}): {resp.text[:100]}")
        return None
    except Exception as e:
        imprimir_error(f"Error obteniendo token: {e}")
        return None

def probar_endpoints(config: dict):
    """Prueba todos los endpoints del API"""
    imprimir_titulo("PRUEBA DE ENDPOINTS")
    
    api_base = config["api"]["base_url"]
    token = obtener_token(config)
    
    endpoints = [
        ("GET", "/health", None, False, "Health Check"),
        ("GET", "/productos", None, False, "Listar Productos"),
        ("GET", "/productos/1", None, False, "Detalle Producto"),
        ("GET", "/pedidos/cliente/1", None, True, "Pedidos Cliente"),
        ("GET", "/ubicaciones/usuario/1", None, True, "Ubicaciones"),
        ("POST", "/chat/bot/mensajes", {"mensaje": "Hola", "idRemitente": 1}, True, "Chat Bot IA"),
    ]
    
    resultados = []
    for metodo, ruta, payload, requiere_auth, nombre in endpoints:
        if requiere_auth and not token:
            imprimir_advertencia(f"SKIP {nombre} - Sin token")
            continue
        
        headers = {"Content-Type": "application/json"}
        if requiere_auth:
            headers["Authorization"] = f"Bearer {token}"
        
        try:
            if metodo == "GET":
                r = requests.get(f"{api_base}{ruta}", headers=headers, timeout=20)
            else:
                r = requests.post(f"{api_base}{ruta}", headers=headers, json=payload, timeout=30)
            
            if 200 <= r.status_code < 300:
                imprimir_exito(f"{nombre} -> {r.status_code}")
                resultados.append((nombre, "OK", r.status_code))
            else:
                imprimir_error(f"{nombre} -> {r.status_code}")
                resultados.append((nombre, "FAIL", r.status_code))
        except Exception as e:
            imprimir_error(f"{nombre} -> ERROR: {e}")
            resultados.append((nombre, "ERROR", None))
    
    # Guardar reporte
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    reporte_file = REPORTES_DIR / f"prueba_endpoints_{timestamp}.txt"
    with open(reporte_file, 'w', encoding='utf-8') as f:
        f.write("REPORTE DE PRUEBAS DE ENDPOINTS\n")
        f.write("="*50 + "\n\n")
        for nombre, estado, codigo in resultados:
            f.write(f"{estado:6} | {nombre:30} | {codigo}\n")
    
    imprimir_info(f"Reporte guardado: {reporte_file}")

def deploy_api(config: dict):
    """Deploy completo del API a AWS"""
    imprimir_titulo("DEPLOY API A AWS")
    imprimir_advertencia("Esta función compilará y subirá el JAR a EC2")
    confirmar = input("¿Continuar? (s/n): ")
    if confirmar.lower() != 's':
        return
    
    # TODO: Implementar compilación Maven y subida SCP
    imprimir_info("Función en desarrollo - por ahora use deploy_api_completo.bat")

def gestionar_bd(config: dict):
    """Panel de gestión de base de datos"""
    imprimir_titulo("GESTIÓN DE BASE DE DATOS")
    
    print(f"{Color.BOLD}1.{Color.ENDC} Ver tablas")
    print(f"{Color.BOLD}2.{Color.ENDC} Ejecutar query custom")
    print(f"{Color.BOLD}3.{Color.ENDC} Backup base de datos")
    print(f"{Color.BOLD}4.{Color.ENDC} Conectar con PostgreSQL CLI")
    print(f"{Color.BOLD}0.{Color.ENDC} Volver")
    
    opcion = input(f"\n{Color.CYAN}Seleccione opción: {Color.ENDC}")
    
    if opcion == "1":
        ver_tablas_bd(config)
    elif opcion == "2":
        ejecutar_query_bd(config)
    elif opcion == "3":
        imprimir_info("Función en desarrollo")
    elif opcion == "4":
        conectar_psql_cli(config)

def ver_tablas_bd(config: dict):
    """Muestra las tablas de la BD"""
    rds = config["aws"]["rds"]
    imprimir_info("Obteniendo lista de tablas PostgreSQL...")
    
    # PostgreSQL: Usar psql con variable de entorno PGPASSWORD
    cmd = f"PGPASSWORD={rds['password']} psql -h {rds['host']} -p {rds['port']} -U {rds['user']} -d {rds['database']} -c \"SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name;\""
    ok, out, err = ejecutar_ssh(config, cmd)
    
    if ok:
        print(out)
    else:
        imprimir_error(f"Error: {err}")

def ejecutar_query_bd(config: dict):
    """Ejecuta query personalizado en PostgreSQL"""
    query = input("Query SQL: ")
    if not query.strip():
        return
    
    rds = config["aws"]["rds"]
    # PostgreSQL: Usar psql con PGPASSWORD
    cmd = f"PGPASSWORD={rds['password']} psql -h {rds['host']} -p {rds['port']} -U {rds['user']} -d {rds['database']} -c \"{query}\""
    ok, out, err = ejecutar_ssh(config, cmd)
    
    if ok:
        print(out)
    else:
        imprimir_error(f"Error: {err}")

def conectar_psql_cli(config: dict):
    """Abre shell interactivo de PostgreSQL"""
    rds = config["aws"]["rds"]
    imprimir_info(f"Conectando a PostgreSQL {rds['host']}...")
    
    # PostgreSQL: Comando para conectar interactivamente
    cmd = f"PGPASSWORD={rds['password']} psql -h {rds['host']} -p {rds['port']} -U {rds['user']} -d {rds['database']}"
    imprimir_info(f"Ejecute: ssh + {cmd}")

def ver_logs(config: dict):
    """Ver logs del contenedor Docker"""
    imprimir_titulo("LOGS DEL API")
    container = config["api"]["docker_container"]
    
    print(f"{Color.BOLD}1.{Color.ENDC} Ver últimas 50 líneas")
    print(f"{Color.BOLD}2.{Color.ENDC} Ver últimas 200 líneas")
    print(f"{Color.BOLD}3.{Color.ENDC} Seguir logs en tiempo real (Ctrl+C para salir)")
    print(f"{Color.BOLD}0.{Color.ENDC} Volver")
    
    opcion = input(f"\n{Color.CYAN}Seleccione opción: {Color.ENDC}")
    
    if opcion == "1":
        ok, out, err = ejecutar_ssh(config, f"sudo docker logs {container} --tail 50")
        print(out if ok else err)
    elif opcion == "2":
        ok, out, err = ejecutar_ssh(config, f"sudo docker logs {container} --tail 200")
        print(out if ok else err)
    elif opcion == "3":
        imprimir_info("Use: ssh + sudo docker logs -f delivery-api")

def configuracion(config: dict):
    """Muestra configuración actual"""
    imprimir_titulo("CONFIGURACIÓN ACTUAL")
    
    print(f"{Color.BOLD}AWS EC2:{Color.ENDC}")
    print(f"  Host: {config['aws']['ec2']['host']}")
    print(f"  User: {config['aws']['ec2']['user']}")
    print(f"  PEM:  {config['aws']['ec2']['pem_path']}")
    
    print(f"\n{Color.BOLD}AWS RDS:{Color.ENDC}")
    print(f"  Host: {config['aws']['rds']['host']}")
    print(f"  User: {config['aws']['rds']['user']}")
    print(f"  DB:   {config['aws']['rds']['database']}")
    
    print(f"\n{Color.BOLD}API:{Color.ENDC}")
    print(f"  URL:       {config['api']['base_url']}")
    print(f"  Container: {config['api']['docker_container']}")
    
    print(f"\n{Color.BOLD}Usuarios de prueba:{Color.ENDC}")
    for rol, datos in config['test_users'].items():
        print(f"  {rol}: {datos['email']}")

# ============= MENÚ PRINCIPAL =============
def menu_principal():
    """Menú principal interactivo"""
    config = cargar_config()
    
    while True:
        print(f"\n{Color.BOLD}{Color.HEADER}")
        print("╔═══════════════════════════════════════════════════════════╗")
        print("║     UNITE SPEED DELIVERY - GESTOR UNIFICADO v1.0         ║")
        print("╚═══════════════════════════════════════════════════════════╝")
        print(Color.ENDC)
        
        print(f"{Color.BOLD}1.{Color.ENDC} 🔄 Reiniciar API")
        print(f"{Color.BOLD}2.{Color.ENDC} 🧪 Probar Endpoints")
        print(f"{Color.BOLD}3.{Color.ENDC} 🚀 Deploy API a AWS")
        print(f"{Color.BOLD}4.{Color.ENDC} 🗄️  Gestionar Base de Datos")
        print(f"{Color.BOLD}5.{Color.ENDC} 📋 Ver Logs del API")
        print(f"{Color.BOLD}6.{Color.ENDC} ⚙️  Ver Configuración")
        print(f"{Color.BOLD}0.{Color.ENDC} ❌ Salir")
        
        opcion = input(f"\n{Color.CYAN}{Color.BOLD}Seleccione opción: {Color.ENDC}")
        
        if opcion == "1":
            reiniciar_api(config)
        elif opcion == "2":
            probar_endpoints(config)
        elif opcion == "3":
            deploy_api(config)
        elif opcion == "4":
            gestionar_bd(config)
        elif opcion == "5":
            ver_logs(config)
        elif opcion == "6":
            configuracion(config)
        elif opcion == "0":
            print(f"\n{Color.GREEN}¡Hasta luego!{Color.ENDC}\n")
            break
        else:
            imprimir_error("Opción inválida")

# ============= MAIN =============
if __name__ == "__main__":
    try:
        menu_principal()
    except KeyboardInterrupt:
        print(f"\n\n{Color.YELLOW}Interrumpido por usuario{Color.ENDC}\n")
    except Exception as e:
        imprimir_error(f"Error fatal: {e}")
        sys.exit(1)
