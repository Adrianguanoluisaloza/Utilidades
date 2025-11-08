"""
REPORTE DE ERRORES - UNITE SPEED GUI
Ejecuta este script si ves errores en la aplicación GUI
"""

import sys
import traceback
from datetime import datetime

print("=" * 60)
print("  DIAGNÓSTICO DE ERRORES - UNITE SPEED GUI")
print("=" * 60)
print()

# 1. Verificar Python
print("1. Versión de Python:")
print(f"   {sys.version}")
print()

# 2. Verificar Tkinter
print("2. Verificando Tkinter...")
try:
    import tkinter as tk
    root = tk.Tk()
    root.destroy()
    print("   ✅ Tkinter funciona correctamente")
except Exception as e:
    print(f"   ❌ ERROR en Tkinter: {e}")
print()

# 3. Verificar requests
print("3. Verificando librería requests...")
try:
    import requests
    print(f"   ✅ requests versión {requests.__version__}")
except Exception as e:
    print(f"   ❌ ERROR: {e}")
    print("   Instalar con: pip install requests")
print()

# 4. Verificar config.json
print("4. Verificando config.json...")
try:
    import json
    from pathlib import Path
    
    config_file = Path(__file__).parent / "config" / "config.json"
    if config_file.exists():
        with open(config_file, 'r', encoding='utf-8') as f:
            config = json.load(f)
        print(f"   ✅ config.json encontrado y válido")
        print(f"   API: {config['api']['base_url']}")
        print(f"   EC2: {config['aws']['ec2']['host']}")
    else:
        print(f"   ❌ config.json NO encontrado en: {config_file}")
except Exception as e:
    print(f"   ❌ ERROR: {e}")
print()

# 5. Intentar ejecutar GUI
print("5. Intentando ejecutar la GUI...")
print("   (Si ves la ventana, ¡todo está bien!)")
print()

try:
    from unite_speed_gui import UniteSpeedGUI
    import tkinter as tk
    
    root = tk.Tk()
    app = UniteSpeedGUI(root)
    
    print("   ✅ GUI iniciada correctamente")
    print("   Si ves la ventana, la aplicación funciona bien")
    print()
    print("   Presiona Ctrl+C aquí para cerrar el diagnóstico")
    print("   O cierra la ventana de la aplicación")
    
    root.mainloop()
    
except KeyboardInterrupt:
    print("\n   Diagnóstico interrumpido por el usuario")
except Exception as e:
    print(f"\n   ❌ ERROR AL EJECUTAR GUI:")
    print(f"   {type(e).__name__}: {e}")
    print()
    print("   Traceback completo:")
    traceback.print_exc()
    print()
    print("   COPIA este error completo y compártelo")

print()
print("=" * 60)
print("  DIAGNÓSTICO COMPLETADO")
print(f"  Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("=" * 60)

input("\nPresiona ENTER para cerrar...")
