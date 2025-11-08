"""
VISOR DE ESTADO EN TIEMPO REAL
Este script muestra el estado de la aplicación para diagnóstico
"""

import tkinter as tk
from tkinter import scrolledtext, ttk
import subprocess
import threading
import time
import json
import requests
from pathlib import Path
from datetime import datetime

class VisorEstado:
    def __init__(self, root):
        self.root = root
        self.root.title("📊 Visor de Estado - Unite Speed")
        self.root.geometry("900x700")
        self.root.configure(bg='#1e1e1e')
        
        # Frame principal
        main_frame = tk.Frame(root, bg='#1e1e1e')
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Título
        titulo = tk.Label(
            main_frame,
            text="📊 VISOR DE ESTADO EN TIEMPO REAL",
            font=('Arial', 16, 'bold'),
            bg='#1e1e1e',
            fg='#00ff00'
        )
        titulo.pack(pady=10)
        
        # Botones de acción
        btn_frame = tk.Frame(main_frame, bg='#1e1e1e')
        btn_frame.pack(pady=10)
        
        tk.Button(
            btn_frame,
            text="🔍 Verificar Todo",
            command=self.verificar_todo,
            bg='#0066cc',
            fg='white',
            font=('Arial', 11, 'bold'),
            padx=20,
            pady=8
        ).pack(side=tk.LEFT, padx=5)
        
        tk.Button(
            btn_frame,
            text="🚀 Ejecutar GUI",
            command=self.ejecutar_gui,
            bg='#00aa00',
            fg='white',
            font=('Arial', 11, 'bold'),
            padx=20,
            pady=8
        ).pack(side=tk.LEFT, padx=5)
        
        tk.Button(
            btn_frame,
            text="❤️ Test API",
            command=self.test_api,
            bg='#cc6600',
            fg='white',
            font=('Arial', 11, 'bold'),
            padx=20,
            pady=8
        ).pack(side=tk.LEFT, padx=5)
        
        tk.Button(
            btn_frame,
            text="🔄 Limpiar",
            command=self.limpiar,
            bg='#666666',
            fg='white',
            font=('Arial', 11, 'bold'),
            padx=20,
            pady=8
        ).pack(side=tk.LEFT, padx=5)
        
        # Área de salida
        tk.Label(
            main_frame,
            text="📋 Salida del Sistema:",
            bg='#1e1e1e',
            fg='#ffffff',
            font=('Arial', 11, 'bold')
        ).pack(pady=5)
        
        self.output = scrolledtext.ScrolledText(
            main_frame,
            height=30,
            bg='#0c0c0c',
            fg='#00ff00',
            font=('Consolas', 10),
            insertbackground='white'
        )
        self.output.pack(fill=tk.BOTH, expand=True, pady=5)
        
        # Barra de estado
        self.status = tk.Label(
            main_frame,
            text="Listo",
            bg='#2d2d2d',
            fg='#00ff00',
            anchor=tk.W,
            font=('Arial', 9)
        )
        self.status.pack(side=tk.BOTTOM, fill=tk.X)
        
        # Auto-verificar al inicio
        self.root.after(500, self.verificar_todo)
    
    def log(self, texto, color='green'):
        """Agregar texto al log"""
        timestamp = datetime.now().strftime('%H:%M:%S')
        self.output.insert('end', f"[{timestamp}] {texto}\n")
        self.output.see('end')
        self.root.update()
    
    def limpiar(self):
        """Limpiar el área de salida"""
        self.output.delete('1.0', 'end')
        self.log("Pantalla limpiada")
    
    def verificar_todo(self):
        """Verificar todos los componentes"""
        self.status.config(text="Verificando sistema...")
        
        def tarea():
            self.log("=" * 60)
            self.log("🔍 INICIANDO VERIFICACIÓN COMPLETA")
            self.log("=" * 60)
            
            # 1. Python
            import sys
            self.log(f"\n✅ Python {sys.version.split()[0]}")
            
            # 2. Tkinter
            try:
                import tkinter
                self.log("✅ Tkinter disponible")
            except:
                self.log("❌ ERROR: Tkinter no disponible")
            
            # 3. Requests
            try:
                import requests
                self.log(f"✅ requests {requests.__version__}")
            except:
                self.log("❌ ERROR: requests no instalado")
            
            # 4. Config.json
            try:
                config_file = Path(__file__).parent / "config" / "config.json"
                with open(config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                self.log(f"✅ config.json encontrado")
                self.log(f"   API: {config['api']['base_url']}")
                self.log(f"   EC2: {config['aws']['ec2']['host']}")
                self.log(f"   Container: {config['api']['docker_container']}")
                
                # Verificar PEM
                pem = config['aws']['ec2']['pem_path']
                if Path(pem).exists():
                    self.log(f"✅ Archivo PEM encontrado: {pem}")
                else:
                    self.log(f"⚠️  Archivo PEM no encontrado: {pem}")
                
            except Exception as e:
                self.log(f"❌ ERROR en config.json: {e}")
            
            # 5. Archivos del proyecto
            self.log("\n📁 Archivos del proyecto:")
            archivos = [
                "unite_speed_gui.py",
                "gestor_unitespeed.py",
                "config/config.json",
                "EJECUTAR_GUI.bat",
                "EJECUTAR.bat"
            ]
            for archivo in archivos:
                path = Path(__file__).parent / archivo
                if path.exists():
                    size = path.stat().st_size
                    self.log(f"   ✅ {archivo} ({size:,} bytes)")
                else:
                    self.log(f"   ❌ {archivo} NO ENCONTRADO")
            
            self.log("\n" + "=" * 60)
            self.log("✅ VERIFICACIÓN COMPLETADA")
            self.log("=" * 60)
            
            self.root.after(0, lambda: self.status.config(text="✅ Verificación completada"))
        
        threading.Thread(target=tarea, daemon=True).start()
    
    def ejecutar_gui(self):
        """Ejecutar la aplicación GUI"""
        self.log("\n🚀 Ejecutando aplicación GUI...")
        self.log("   (Se abrirá en una ventana nueva)")
        
        def tarea():
            try:
                result = subprocess.run(
                    ["python", "unite_speed_gui.py"],
                    cwd=Path(__file__).parent,
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                
                if result.returncode == 0:
                    self.log("✅ GUI ejecutada correctamente")
                else:
                    self.log(f"❌ Error al ejecutar GUI:")
                    if result.stderr:
                        self.log(result.stderr)
            except subprocess.TimeoutExpired:
                self.log("✅ GUI está ejecutándose (timeout esperado)")
            except Exception as e:
                self.log(f"❌ ERROR: {e}")
        
        threading.Thread(target=tarea, daemon=True).start()
    
    def test_api(self):
        """Probar conexión con el API"""
        self.status.config(text="Probando API...")
        
        def tarea():
            try:
                config_file = Path(__file__).parent / "config" / "config.json"
                with open(config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                
                api_url = config['api']['base_url']
                
                self.log(f"\n❤️  Probando API: {api_url}/health")
                
                resp = requests.get(f"{api_url}/health", timeout=10)
                
                if resp.status_code == 200:
                    self.log(f"✅ API respondió: {resp.status_code}")
                    try:
                        data = resp.json()
                        self.log(f"   Respuesta: {json.dumps(data, indent=2)}")
                    except:
                        self.log(f"   Respuesta: {resp.text[:200]}")
                    
                    # Probar login
                    self.log(f"\n🔑 Probando login...")
                    user = config['test_users']['cliente']
                    
                    login_resp = requests.post(
                        f"{api_url}/auth/login",
                        json={"email": user['email'], "password": user['password']},
                        timeout=10
                    )
                    
                    if login_resp.status_code == 200:
                        self.log(f"✅ Login exitoso: {login_resp.status_code}")
                        data = login_resp.json()
                        token = data.get('token') or data.get('data', {}).get('token')
                        if token:
                            self.log(f"   Token obtenido: {token[:50]}...")
                    else:
                        self.log(f"❌ Login falló: {login_resp.status_code}")
                        self.log(f"   {login_resp.text[:200]}")
                else:
                    self.log(f"❌ API respondió con error: {resp.status_code}")
                    self.log(f"   {resp.text[:200]}")
                
                self.root.after(0, lambda: self.status.config(text="✅ Prueba de API completada"))
                
            except requests.exceptions.ConnectionError:
                self.log("❌ ERROR: No se puede conectar al API")
                self.log("   Verifica que el servidor esté ejecutándose")
            except Exception as e:
                self.log(f"❌ ERROR: {e}")
                self.root.after(0, lambda: self.status.config(text="❌ Error en prueba de API"))
        
        threading.Thread(target=tarea, daemon=True).start()

if __name__ == "__main__":
    root = tk.Tk()
    app = VisorEstado(root)
    root.mainloop()
