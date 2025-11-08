"""
╔═══════════════════════════════════════════════════════════╗
║   UNITE SPEED DELIVERY - APLICACIÓN GUI COMPLETA v2.0    ║
║      Interfaz Visual con Todos los Endpoints + Deploy    ║
╚═══════════════════════════════════════════════════════════╝

Características:
- Interfaz gráfica moderna con pestañas
- Prueba de TODOS los endpoints (35+)
- Tokens automáticos para todos los roles
- Resultados en tabla visual con colores
- Reinicio de API, Deploy, BD, Logs
- Exportar resultados a Excel/HTML
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import threading
import requests
import json
import subprocess
import time
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, List, Any

# ============= CONFIGURACIÓN =============
SCRIPT_DIR = Path(__file__).parent
CONFIG_FILE = SCRIPT_DIR / "config" / "config.json"

class UniteSpeedGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Unite Speed Delivery - Panel de Control v2.0")
        self.root.geometry("1200x800")
        self.root.configure(bg='#2c3e50')
        
        # Cargar configuración
        self.config = self.cargar_config()
        self.tokens = {}  # Tokens por rol
        self.resultados_tests = []
        
        # Crear interfaz
        self.crear_interfaz()
        
    def cargar_config(self) -> Dict:
        """Carga configuración desde config.json"""
        with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    
    def crear_interfaz(self):
        """Crea toda la interfaz gráfica"""
        # Frame principal
        main_frame = tk.Frame(self.root, bg='#2c3e50')
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Título
        titulo = tk.Label(
            main_frame,
            text="🚀 UNITE SPEED DELIVERY - PANEL DE CONTROL",
            font=('Arial', 18, 'bold'),
            bg='#2c3e50',
            fg='#ecf0f1'
        )
        titulo.pack(pady=10)
        
        # Notebook (pestañas)
        self.notebook = ttk.Notebook(main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True)
        
        # Crear pestañas
        self.crear_pestana_endpoints()
        self.crear_pestana_api()
        self.crear_pestana_bd()
        self.crear_pestana_logs()
        self.crear_pestana_config()
        
        # Barra de estado
        self.status_bar = tk.Label(
            main_frame,
            text="Listo",
            bg='#34495e',
            fg='#ecf0f1',
            anchor=tk.W,
            font=('Arial', 9)
        )
        self.status_bar.pack(side=tk.BOTTOM, fill=tk.X)
    
    def crear_pestana_endpoints(self):
        """Pestaña de pruebas de endpoints"""
        frame = tk.Frame(self.notebook, bg='#ecf0f1')
        self.notebook.add(frame, text='🧪 Pruebas de Endpoints')
        
        # Panel superior - Controles
        control_frame = tk.Frame(frame, bg='#ecf0f1')
        control_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Selector de rol
        tk.Label(control_frame, text="Rol:", bg='#ecf0f1', font=('Arial', 10, 'bold')).pack(side=tk.LEFT, padx=5)
        self.rol_var = tk.StringVar(value="cliente")
        roles = ["cliente", "admin", "delivery", "negocio", "soporte"]
        rol_menu = ttk.Combobox(control_frame, textvariable=self.rol_var, values=roles, state='readonly', width=15)
        rol_menu.pack(side=tk.LEFT, padx=5)
        
        # Botón obtener token
        btn_token = tk.Button(
            control_frame,
            text="🔑 Obtener Token",
            command=self.obtener_token_rol,
            bg='#3498db',
            fg='white',
            font=('Arial', 10, 'bold'),
            padx=15,
            pady=5
        )
        btn_token.pack(side=tk.LEFT, padx=5)
        
        # Botón probar todos
        btn_test_all = tk.Button(
            control_frame,
            text="▶ Probar TODOS los Endpoints",
            command=self.probar_todos_endpoints,
            bg='#27ae60',
            fg='white',
            font=('Arial', 11, 'bold'),
            padx=20,
            pady=5
        )
        btn_test_all.pack(side=tk.LEFT, padx=10)
        
        # Botón exportar
        btn_export = tk.Button(
            control_frame,
            text="💾 Exportar Resultados",
            command=self.exportar_resultados,
            bg='#f39c12',
            fg='white',
            font=('Arial', 10, 'bold'),
            padx=15,
            pady=5
        )
        btn_export.pack(side=tk.LEFT, padx=5)
        
        # Indicador de token
        self.token_label = tk.Label(
            control_frame,
            text="Sin token",
            bg='#ecf0f1',
            fg='#e74c3c',
            font=('Arial', 9, 'italic')
        )
        self.token_label.pack(side=tk.RIGHT, padx=10)
        
        # Tabla de resultados
        tabla_frame = tk.Frame(frame, bg='#ecf0f1')
        tabla_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Scrollbars
        scroll_y = tk.Scrollbar(tabla_frame)
        scroll_y.pack(side=tk.RIGHT, fill=tk.Y)
        
        scroll_x = tk.Scrollbar(tabla_frame, orient=tk.HORIZONTAL)
        scroll_x.pack(side=tk.BOTTOM, fill=tk.X)
        
        # Treeview
        self.tree = ttk.Treeview(
            tabla_frame,
            columns=('Nº', 'Método', 'Endpoint', 'Descripción', 'Status', 'Resultado', 'Tiempo'),
            show='headings',
            yscrollcommand=scroll_y.set,
            xscrollcommand=scroll_x.set
        )
        
        # Configurar columnas
        self.tree.heading('Nº', text='#')
        self.tree.heading('Método', text='Método')
        self.tree.heading('Endpoint', text='Endpoint')
        self.tree.heading('Descripción', text='Descripción')
        self.tree.heading('Status', text='Status')
        self.tree.heading('Resultado', text='Resultado')
        self.tree.heading('Tiempo', text='Tiempo (ms)')
        
        self.tree.column('Nº', width=40, anchor=tk.CENTER)
        self.tree.column('Método', width=80, anchor=tk.CENTER)
        self.tree.column('Endpoint', width=250)
        self.tree.column('Descripción', width=250)
        self.tree.column('Status', width=70, anchor=tk.CENTER)
        self.tree.column('Resultado', width=100, anchor=tk.CENTER)
        self.tree.column('Tiempo', width=100, anchor=tk.CENTER)
        
        scroll_y.config(command=self.tree.yview)
        scroll_x.config(command=self.tree.xview)
        
        self.tree.pack(fill=tk.BOTH, expand=True)
        
        # Configurar colores de filas
        self.tree.tag_configure('ok', background='#d5f4e6')
        self.tree.tag_configure('fail', background='#fadbd8')
        self.tree.tag_configure('skip', background='#fef5e7')
    
    def crear_pestana_api(self):
        """Pestaña de gestión de API"""
        frame = tk.Frame(self.notebook, bg='#ecf0f1')
        self.notebook.add(frame, text='🔄 API & Deploy')
        
        # Título
        tk.Label(
            frame,
            text="Gestión del API Backend",
            font=('Arial', 14, 'bold'),
            bg='#ecf0f1'
        ).pack(pady=15)
        
        # Botones
        btn_frame = tk.Frame(frame, bg='#ecf0f1')
        btn_frame.pack(pady=20)
        
        btn_reiniciar = tk.Button(
            btn_frame,
            text="🔄 Reiniciar Contenedor Docker",
            command=self.reiniciar_api,
            bg='#3498db',
            fg='white',
            font=('Arial', 12, 'bold'),
            padx=30,
            pady=15,
            width=30
        )
        btn_reiniciar.grid(row=0, column=0, padx=10, pady=10)
        
        btn_health = tk.Button(
            btn_frame,
            text="❤️ Health Check",
            command=self.health_check,
            bg='#27ae60',
            fg='white',
            font=('Arial', 12, 'bold'),
            padx=30,
            pady=15,
            width=30
        )
        btn_health.grid(row=0, column=1, padx=10, pady=10)
        
        btn_deploy = tk.Button(
            btn_frame,
            text="🚀 Deploy Completo",
            command=self.deploy_api,
            bg='#e74c3c',
            fg='white',
            font=('Arial', 12, 'bold'),
            padx=30,
            pady=15,
            width=30
        )
        btn_deploy.grid(row=1, column=0, padx=10, pady=10)
        
        # Área de logs
        tk.Label(frame, text="Salida:", bg='#ecf0f1', font=('Arial', 10, 'bold')).pack(pady=5)
        self.api_output = scrolledtext.ScrolledText(
            frame,
            height=20,
            bg='#2c3e50',
            fg='#ecf0f1',
            font=('Consolas', 9)
        )
        self.api_output.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
    
    def crear_pestana_bd(self):
        """Pestaña de gestión de base de datos"""
        frame = tk.Frame(self.notebook, bg='#ecf0f1')
        self.notebook.add(frame, text='🗄️ Base de Datos')
        
        # Título
        tk.Label(
            frame,
            text="Gestión de Base de Datos MySQL",
            font=('Arial', 14, 'bold'),
            bg='#ecf0f1'
        ).pack(pady=15)
        
        # Botones
        btn_frame = tk.Frame(frame, bg='#ecf0f1')
        btn_frame.pack(pady=10)
        
        tk.Button(
            btn_frame,
            text="📋 Ver Tablas",
            command=self.ver_tablas_bd,
            bg='#3498db',
            fg='white',
            font=('Arial', 11, 'bold'),
            padx=20,
            pady=10,
            width=20
        ).grid(row=0, column=0, padx=10, pady=5)
        
        tk.Button(
            btn_frame,
            text="👥 Ver Usuarios",
            command=lambda: self.ejecutar_query_bd("SELECT * FROM usuarios LIMIT 20;"),
            bg='#9b59b6',
            fg='white',
            font=('Arial', 11, 'bold'),
            padx=20,
            pady=10,
            width=20
        ).grid(row=0, column=1, padx=10, pady=5)
        
        tk.Button(
            btn_frame,
            text="📦 Ver Productos",
            command=lambda: self.ejecutar_query_bd("SELECT * FROM productos LIMIT 20;"),
            bg='#16a085',
            fg='white',
            font=('Arial', 11, 'bold'),
            padx=20,
            pady=10,
            width=20
        ).grid(row=1, column=0, padx=10, pady=5)
        
        tk.Button(
            btn_frame,
            text="🛍️ Ver Pedidos",
            command=lambda: self.ejecutar_query_bd("SELECT * FROM pedidos LIMIT 20;"),
            bg='#d35400',
            fg='white',
            font=('Arial', 11, 'bold'),
            padx=20,
            pady=10,
            width=20
        ).grid(row=1, column=1, padx=10, pady=5)
        
        # Query personalizado
        query_frame = tk.Frame(frame, bg='#ecf0f1')
        query_frame.pack(fill=tk.X, padx=20, pady=10)
        
        tk.Label(query_frame, text="Query SQL:", bg='#ecf0f1', font=('Arial', 10, 'bold')).pack(anchor=tk.W)
        self.query_entry = tk.Text(query_frame, height=3, font=('Consolas', 10))
        self.query_entry.pack(fill=tk.X, pady=5)
        
        tk.Button(
            query_frame,
            text="▶ Ejecutar Query",
            command=self.ejecutar_query_custom,
            bg='#27ae60',
            fg='white',
            font=('Arial', 10, 'bold'),
            padx=20,
            pady=5
        ).pack(pady=5)
        
        # Área de resultados
        tk.Label(frame, text="Resultados:", bg='#ecf0f1', font=('Arial', 10, 'bold')).pack(pady=5)
        self.bd_output = scrolledtext.ScrolledText(
            frame,
            height=15,
            bg='#2c3e50',
            fg='#ecf0f1',
            font=('Consolas', 9)
        )
        self.bd_output.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
    
    def crear_pestana_logs(self):
        """Pestaña de logs del sistema"""
        frame = tk.Frame(self.notebook, bg='#ecf0f1')
        self.notebook.add(frame, text='📋 Logs')
        
        # Título
        tk.Label(
            frame,
            text="Logs del Contenedor Docker",
            font=('Arial', 14, 'bold'),
            bg='#ecf0f1'
        ).pack(pady=15)
        
        # Botones
        btn_frame = tk.Frame(frame, bg='#ecf0f1')
        btn_frame.pack(pady=10)
        
        tk.Button(
            btn_frame,
            text="📄 Últimas 50 líneas",
            command=lambda: self.ver_logs(50),
            bg='#3498db',
            fg='white',
            font=('Arial', 10, 'bold'),
            padx=20,
            pady=8
        ).pack(side=tk.LEFT, padx=5)
        
        tk.Button(
            btn_frame,
            text="📜 Últimas 200 líneas",
            command=lambda: self.ver_logs(200),
            bg='#9b59b6',
            fg='white',
            font=('Arial', 10, 'bold'),
            padx=20,
            pady=8
        ).pack(side=tk.LEFT, padx=5)
        
        tk.Button(
            btn_frame,
            text="🔄 Actualizar",
            command=lambda: self.ver_logs(100),
            bg='#27ae60',
            fg='white',
            font=('Arial', 10, 'bold'),
            padx=20,
            pady=8
        ).pack(side=tk.LEFT, padx=5)
        
        # Área de logs
        self.logs_output = scrolledtext.ScrolledText(
            frame,
            bg='#2c3e50',
            fg='#00ff00',
            font=('Consolas', 9)
        )
        self.logs_output.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
    
    def crear_pestana_config(self):
        """Pestaña de configuración"""
        frame = tk.Frame(self.notebook, bg='#ecf0f1')
        self.notebook.add(frame, text='⚙️ Configuración')
        
        # Título
        tk.Label(
            frame,
            text="Configuración del Sistema",
            font=('Arial', 14, 'bold'),
            bg='#ecf0f1'
        ).pack(pady=15)
        
        # Mostrar configuración actual
        config_text = scrolledtext.ScrolledText(
            frame,
            height=25,
            bg='#2c3e50',
            fg='#ecf0f1',
            font=('Consolas', 10)
        )
        config_text.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
        
        # Cargar configuración
        config_str = json.dumps(self.config, indent=2, ensure_ascii=False)
        config_text.insert('1.0', config_str)
        config_text.config(state='disabled')
        
        # Botones
        btn_frame = tk.Frame(frame, bg='#ecf0f1')
        btn_frame.pack(pady=10)
        
        tk.Button(
            btn_frame,
            text="🔄 Recargar Config",
            command=self.recargar_config,
            bg='#3498db',
            fg='white',
            font=('Arial', 10, 'bold'),
            padx=20,
            pady=8
        ).pack(side=tk.LEFT, padx=10)
        
        tk.Button(
            btn_frame,
            text="📝 Editar config.json",
            command=self.abrir_config_editor,
            bg='#f39c12',
            fg='white',
            font=('Arial', 10, 'bold'),
            padx=20,
            pady=8
        ).pack(side=tk.LEFT, padx=10)
    
    # ============= FUNCIONES DE ENDPOINTS =============
    def obtener_token_rol(self):
        """Obtiene token JWT para el rol seleccionado"""
        rol = self.rol_var.get()
        self.actualizar_status(f"Obteniendo token para {rol}...")
        
        def tarea():
            try:
                user = self.config['test_users'][rol]
                url = f"{self.config['api']['base_url']}/login"  # Corregido: sin /auth
                
                resp = requests.post(
                    url,
                    json={"correo": user['email'], "contrasena": user['password']},  # Corregido: contrasena no password
                    timeout=15
                )
                
                if resp.status_code == 200:
                    data = resp.json()
                    token = data.get('token') or data.get('data', {}).get('token')
                    if token:
                        self.tokens[rol] = token
                        self.root.after(0, lambda: self.token_label.config(
                            text=f"Token {rol}: {token[:30]}...",
                            fg='#27ae60'
                        ))
                        self.root.after(0, lambda: self.actualizar_status(f"✅ Token obtenido para {rol}"))
                        messagebox.showinfo("Éxito", f"Token obtenido para {rol}")
                    else:
                        raise Exception("No se encontró token en respuesta")
                else:
                    raise Exception(f"Status {resp.status_code}: {resp.text[:100]}")
            except Exception as e:
                self.root.after(0, lambda: self.actualizar_status(f"❌ Error: {e}"))
                messagebox.showerror("Error", f"Error obteniendo token:\n{e}")
        
        threading.Thread(target=tarea, daemon=True).start()
    
    def probar_todos_endpoints(self):
        """Prueba todos los endpoints del sistema según el rol seleccionado"""
        rol = self.rol_var.get()
        self.actualizar_status(f"Iniciando pruebas completas para rol: {rol}...")
        
        # Limpiar tabla
        for item in self.tree.get_children():
            self.tree.delete(item)
        
        self.resultados_tests = []
        
        def tarea():
            # Obtener token si no existe
            if rol not in self.tokens:
                self.root.after(0, lambda: messagebox.showwarning(
                    "Sin Token",
                    f"Primero obtenga un token para {rol}"
                ))
                return
            
            token = self.tokens[rol]
            api_base = self.config['api']['base_url']
            
            # Lista completa de endpoints
            todos_endpoints = self.obtener_lista_endpoints()
            
            # FILTRAR endpoints según el rol actual
            endpoints = [ep for ep in todos_endpoints if not ep.get('roles') or rol in ep.get('roles', [])]
            
            total_disponibles = len(endpoints)
            total_restringidos = len(todos_endpoints) - total_disponibles
            
            self.root.after(0, lambda: self.actualizar_status(
                f"📊 Rol: {rol.upper()} | Endpoints disponibles: {total_disponibles} | Restringidos: {total_restringidos}"
            ))
            
            for idx, ep in enumerate(endpoints, 1):
                try:
                    headers = {"Content-Type": "application/json"}
                    if ep.get('auth', False):
                        headers['Authorization'] = f"Bearer {token}"
                    
                    start = time.time()
                    
                    if ep['method'] == 'GET':
                        resp = requests.get(f"{api_base}{ep['path']}", headers=headers, timeout=20)
                    elif ep['method'] == 'POST':
                        resp = requests.post(f"{api_base}{ep['path']}", json=ep.get('data'), headers=headers, timeout=30)
                    elif ep['method'] == 'PUT':
                        resp = requests.put(f"{api_base}{ep['path']}", json=ep.get('data'), headers=headers, timeout=30)
                    elif ep['method'] == 'DELETE':
                        resp = requests.delete(f"{api_base}{ep['path']}", headers=headers, timeout=20)
                    
                    elapsed = int((time.time() - start) * 1000)
                    ok = 200 <= resp.status_code < 300
                    
                    resultado = {
                        'num': idx,
                        'method': ep['method'],
                        'path': ep['path'],
                        'desc': ep['desc'],
                        'status': resp.status_code,
                        'ok': ok,
                        'time': elapsed
                    }
                    
                    self.resultados_tests.append(resultado)
                    
                    # Agregar a tabla
                    tag = 'ok' if ok else 'fail'
                    self.root.after(0, lambda r=resultado, t=tag: self.tree.insert(
                        '',
                        'end',
                        values=(r['num'], r['method'], r['path'], r['desc'], r['status'], '✅ OK' if r['ok'] else '❌ FAIL', f"{r['time']} ms"),
                        tags=(t,)
                    ))
                    
                except Exception as e:
                    resultado = {
                        'num': idx,
                        'method': ep['method'],
                        'path': ep['path'],
                        'desc': ep['desc'],
                        'status': 0,
                        'ok': False,
                        'time': 0
                    }
                    self.resultados_tests.append(resultado)
                    
                    self.root.after(0, lambda r=resultado: self.tree.insert(
                        '',
                        'end',
                        values=(r['num'], r['method'], r['path'], r['desc'], 'ERROR', '❌ ERROR', '0 ms'),
                        tags=('fail',)
                    ))
            
            total = len(endpoints)
            exitosos = sum(1 for r in self.resultados_tests if r['ok'])
            self.root.after(0, lambda: self.actualizar_status(
                f"✅ Pruebas completadas para {rol.upper()}: {exitosos}/{total} OK ({total_restringidos} restringidos)"
            ))
            self.root.after(0, lambda: messagebox.showinfo(
                "Pruebas Completadas",
                f"Rol: {rol.upper()}\n\n"
                f"✅ Exitosos: {exitosos}/{total}\n"
                f"❌ Fallidos: {total - exitosos}\n"
                f"🚫 Restringidos: {total_restringidos}\n\n"
                f"Porcentaje: {int(exitosos/total*100) if total > 0 else 0}%"
            ))
        
        threading.Thread(target=tarea, daemon=True).start()
    
    def obtener_lista_endpoints(self) -> List[Dict]:
        """Retorna lista completa de endpoints a probar con permisos por rol"""
        return [
            # AUTENTICACIÓN (Todos los roles)
            {'method': 'POST', 'path': '/login', 'desc': 'Login', 'auth': False, 'roles': ['cliente', 'delivery', 'negocio', 'admin', 'soporte'], 'data': {'correo': 'carlos.cliente@example.com', 'contrasena': 'Cliente123!'}},
            {'method': 'POST', 'path': '/registro', 'desc': 'Registro', 'auth': False, 'roles': ['cliente', 'delivery', 'negocio', 'admin', 'soporte'], 'data': {'nombre': 'Test Usuario', 'correo': f'test{int(time.time())}@test.com', 'contrasena': '123456', 'rol': 'cliente'}},
            {'method': 'POST', 'path': '/auth/reset/generar', 'desc': 'Reset Password', 'auth': False, 'roles': ['cliente', 'delivery', 'negocio', 'admin', 'soporte'], 'data': {'correo': 'carlos.cliente@example.com'}},
            {'method': 'PUT', 'path': '/auth/cambiar-password', 'desc': 'Cambiar Password', 'auth': True, 'roles': ['cliente', 'admin', 'delivery', 'negocio', 'soporte'], 'data': {'actual': 'Cliente123!', 'nueva': 'Cliente123!'}},
            
            # HEALTH (Público - Todos)
            {'method': 'GET', 'path': '/health', 'desc': 'Health Check', 'auth': False, 'roles': ['cliente', 'delivery', 'negocio', 'admin', 'soporte']},
            
            # PRODUCTOS (Lectura: Todos | Escritura: Admin/Negocio)
            {'method': 'GET', 'path': '/productos', 'desc': 'Listar Productos', 'auth': False, 'roles': ['cliente', 'delivery', 'negocio', 'admin', 'soporte']},
            {'method': 'GET', 'path': '/productos/1', 'desc': 'Detalle Producto', 'auth': False, 'roles': ['cliente', 'delivery', 'negocio', 'admin', 'soporte']},
            {'method': 'POST', 'path': '/admin/productos', 'desc': 'Crear Producto (Admin/Negocio)', 'auth': True, 'roles': ['admin', 'negocio'], 'data': {'nombre': 'Producto Test', 'descripcion': 'Descripcion de prueba', 'precio': 10.50, 'imagen_url': 'https://unitespeed-landing-2025.s3.us-east-2.amazonaws.com/productos/test.jpg', 'categoria': 'Comida', 'disponible': True, 'id_negocio': 1}},
            
            # PEDIDOS (Cliente crea | Cada rol ve los suyos | Admin ve todos)
            {'method': 'GET', 'path': '/pedidos/cliente/1', 'desc': 'Pedidos de Cliente', 'auth': True, 'roles': ['cliente', 'admin']},
            {'method': 'GET', 'path': '/pedidos/negocio/1', 'desc': 'Pedidos de Negocio', 'auth': True, 'roles': ['negocio', 'admin']},
            {'method': 'GET', 'path': '/pedidos/delivery/1', 'desc': 'Pedidos de Delivery', 'auth': True, 'roles': ['delivery', 'admin']},
            {'method': 'POST', 'path': '/pedidos', 'desc': 'Crear Pedido (Solo Cliente)', 'auth': True, 'roles': ['cliente', 'admin'], 'data': {'id_cliente': 1, 'productos': [{'idProducto': 1, 'cantidad': 2, 'precio_unitario': 10.50, 'subtotal': 21.0}], 'direccion_entrega': 'Calle Principal #123, Esmeraldas, Ecuador', 'metodo_pago': 'efectivo'}},
            
            # UBICACIONES (Cliente/Delivery pueden gestionar)
            {'method': 'GET', 'path': '/ubicaciones/usuario/1', 'desc': 'Ubicaciones de Usuario', 'auth': True, 'roles': ['cliente', 'delivery', 'admin']},
            {'method': 'POST', 'path': '/ubicaciones', 'desc': 'Crear Ubicación', 'auth': True, 'roles': ['cliente', 'delivery', 'admin'], 'data': {'id_usuario': 1, 'latitud': 0.98, 'longitud': -79.65, 'direccion': 'Test'}},
            
            # TRACKING (Cliente/Delivery pueden ver)
            {'method': 'GET', 'path': '/tracking/pedido/1', 'desc': 'Tracking de Pedido', 'auth': True, 'roles': ['cliente', 'delivery', 'admin']},
            {'method': 'GET', 'path': '/tracking/pedido/1/ruta', 'desc': 'Ruta de Pedido', 'auth': True, 'roles': ['cliente', 'delivery', 'admin']},
            
            # CHAT (Cliente/Delivery con IA bot)
            {'method': 'POST', 'path': '/chat/bot/mensajes', 'desc': 'Chat Bot IA', 'auth': True, 'roles': ['cliente', 'delivery', 'admin'], 'data': {'mensaje': 'Hola', 'idRemitente': 1}},
            {'method': 'POST', 'path': '/chat/iniciar', 'desc': 'Iniciar Chat', 'auth': True, 'roles': ['cliente', 'delivery', 'admin'], 'data': {'idCliente': 1, 'idDestinatario': 4, 'tipoDestinatario': 'delivery'}},
            {'method': 'GET', 'path': '/chat/conversaciones/1', 'desc': 'Conversaciones', 'auth': True, 'roles': ['cliente', 'delivery', 'admin']},
            
            # USUARIOS (Todos pueden ver su perfil | Solo Admin ve lista completa)
            {'method': 'GET', 'path': '/usuarios/1', 'desc': 'Detalle de Usuario', 'auth': True, 'roles': ['cliente', 'delivery', 'negocio', 'admin', 'soporte']},
            {'method': 'GET', 'path': '/usuarios', 'desc': 'Listar Usuarios (Solo Admin)', 'auth': True, 'roles': ['admin']},
            
            # RECOMENDACIONES (Solo Cliente)
            {'method': 'POST', 'path': '/recomendaciones/productos', 'desc': 'Recomendaciones', 'auth': True, 'roles': ['cliente', 'admin'], 'data': {'idUsuario': 1}},
        ]
    
    def exportar_resultados(self):
        """Exporta resultados a HTML"""
        if not self.resultados_tests:
            messagebox.showwarning("Sin Datos", "No hay resultados para exportar")
            return
        
        filename = filedialog.asksaveasfilename(
            defaultextension=".html",
            filetypes=[("HTML", "*.html"), ("Todos", "*.*")]
        )
        
        if filename:
            html = self.generar_html_reporte()
            with open(filename, 'w', encoding='utf-8') as f:
                f.write(html)
            messagebox.showinfo("Éxito", f"Reporte exportado a:\n{filename}")
    
    def generar_html_reporte(self) -> str:
        """Genera reporte HTML de resultados"""
        total = len(self.resultados_tests)
        exitosos = sum(1 for r in self.resultados_tests if r['ok'])
        fallidos = total - exitosos
        
        html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Reporte de Pruebas - Unite Speed</title>
    <style>
        body {{ font-family: Arial; margin: 20px; }}
        h1 {{ color: #2c3e50; }}
        .summary {{ background: #ecf0f1; padding: 15px; margin: 20px 0; border-radius: 5px; }}
        table {{ width: 100%; border-collapse: collapse; }}
        th {{ background: #34495e; color: white; padding: 10px; text-align: left; }}
        td {{ padding: 8px; border-bottom: 1px solid #ddd; }}
        .ok {{ background: #d5f4e6; }}
        .fail {{ background: #fadbd8; }}
    </style>
</head>
<body>
    <h1>🧪 Reporte de Pruebas de Endpoints</h1>
    <div class="summary">
        <h2>Resumen</h2>
        <p><strong>Total:</strong> {total}</p>
        <p><strong>Exitosos:</strong> {exitosos} ✅</p>
        <p><strong>Fallidos:</strong> {fallidos} ❌</p>
        <p><strong>Fecha:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    </div>
    <table>
        <tr>
            <th>#</th>
            <th>Método</th>
            <th>Endpoint</th>
            <th>Descripción</th>
            <th>Status</th>
            <th>Resultado</th>
            <th>Tiempo</th>
        </tr>
"""
        for r in self.resultados_tests:
            clase = 'ok' if r['ok'] else 'fail'
            html += f"""
        <tr class="{clase}">
            <td>{r['num']}</td>
            <td>{r['method']}</td>
            <td>{r['path']}</td>
            <td>{r['desc']}</td>
            <td>{r['status']}</td>
            <td>{'✅ OK' if r['ok'] else '❌ FAIL'}</td>
            <td>{r['time']} ms</td>
        </tr>
"""
        html += """
    </table>
</body>
</html>
"""
        return html
    
    # ============= FUNCIONES DE API =============
    def reiniciar_api(self):
        """Reinicia el contenedor Docker del API"""
        self.actualizar_status("Reiniciando contenedor Docker...")
        
        def tarea():
            try:
                container = self.config['api']['docker_container']
                ok, out, err = self.ejecutar_ssh(f"sudo docker restart {container}")
                
                if ok:
                    self.root.after(0, lambda: self.api_output.insert('end', f"✅ Contenedor {container} reiniciado\n\n{out}\n"))
                    self.root.after(0, lambda: self.actualizar_status("✅ API reiniciado"))
                    self.root.after(0, lambda: messagebox.showinfo("Éxito", "Contenedor reiniciado correctamente"))
                else:
                    self.root.after(0, lambda: self.api_output.insert('end', f"❌ Error:\n{err}\n"))
                    self.root.after(0, lambda: self.actualizar_status("❌ Error al reiniciar"))
            except Exception as e:
                self.root.after(0, lambda: self.api_output.insert('end', f"❌ Excepción: {e}\n"))
        
        threading.Thread(target=tarea, daemon=True).start()
    
    def health_check(self):
        """Realiza health check del API"""
        self.actualizar_status("Verificando health check...")
        
        def tarea():
            try:
                url = f"{self.config['api']['base_url']}/health"
                resp = requests.get(url, timeout=10)
                
                if resp.status_code == 200:
                    data = resp.json()
                    self.root.after(0, lambda: self.api_output.insert('end', f"✅ API funcionando correctamente\n\n{json.dumps(data, indent=2)}\n\n"))
                    self.root.after(0, lambda: messagebox.showinfo("Health Check", "✅ API funcionando correctamente"))
                else:
                    self.root.after(0, lambda: self.api_output.insert('end', f"❌ Status: {resp.status_code}\n"))
            except Exception as e:
                self.root.after(0, lambda: self.api_output.insert('end', f"❌ Error: {e}\n"))
                self.root.after(0, lambda: messagebox.showerror("Error", f"Error en health check:\n{e}"))
        
        threading.Thread(target=tarea, daemon=True).start()
    
    def deploy_api(self):
        """Deploy completo del API"""
        confirmacion = messagebox.askyesno(
            "Confirmación",
            "¿Desea realizar un deploy completo del API?\n\nEsto compilará y subirá el JAR a AWS."
        )
        if not confirmacion:
            return
        
        self.actualizar_status("Deploy en progreso...")
        messagebox.showinfo("Deploy", "Función en desarrollo - use el gestor CLI por ahora")
    
    # ============= FUNCIONES DE BD =============
    def ver_tablas_bd(self):
        """Muestra las tablas de la base de datos"""
        self.ejecutar_query_bd("SHOW TABLES;")
    
    def ejecutar_query_bd(self, query: str):
        """Ejecuta query SQL en la BD"""
        self.actualizar_status(f"Ejecutando query en BD...")
        
        def tarea():
            try:
                rds = self.config['aws']['rds']
                cmd = f"mysql -h {rds['host']} -u {rds['user']} -p{rds['password']} {rds['database']} -e \"{query}\""
                
                ok, out, err = self.ejecutar_ssh(cmd)
                
                if ok:
                    self.root.after(0, lambda: self.bd_output.delete('1.0', 'end'))
                    self.root.after(0, lambda: self.bd_output.insert('1.0', out))
                    self.root.after(0, lambda: self.actualizar_status("✅ Query ejecutado"))
                else:
                    self.root.after(0, lambda: self.bd_output.delete('1.0', 'end'))
                    self.root.after(0, lambda: self.bd_output.insert('1.0', f"❌ Error:\n{err}"))
            except Exception as e:
                self.root.after(0, lambda: self.bd_output.insert('end', f"\n❌ Excepción: {e}\n"))
        
        threading.Thread(target=tarea, daemon=True).start()
    
    def ejecutar_query_custom(self):
        """Ejecuta query personalizado del usuario"""
        query = self.query_entry.get('1.0', 'end').strip()
        if not query:
            messagebox.showwarning("Query Vacío", "Ingrese un query SQL")
            return
        self.ejecutar_query_bd(query)
    
    # ============= FUNCIONES DE LOGS =============
    def ver_logs(self, lineas: int):
        """Ver logs del contenedor Docker"""
        self.actualizar_status(f"Obteniendo últimas {lineas} líneas de logs...")
        
        def tarea():
            try:
                container = self.config['api']['docker_container']
                ok, out, err = self.ejecutar_ssh(f"sudo docker logs {container} --tail {lineas}")
                
                if ok:
                    self.root.after(0, lambda: self.logs_output.delete('1.0', 'end'))
                    self.root.after(0, lambda: self.logs_output.insert('1.0', out))
                    self.root.after(0, lambda: self.actualizar_status(f"✅ {lineas} líneas de logs cargadas"))
                else:
                    self.root.after(0, lambda: self.logs_output.insert('end', f"\n❌ Error: {err}\n"))
            except Exception as e:
                self.root.after(0, lambda: self.logs_output.insert('end', f"\n❌ Excepción: {e}\n"))
        
        threading.Thread(target=tarea, daemon=True).start()
    
    # ============= FUNCIONES DE CONFIG =============
    def recargar_config(self):
        """Recarga la configuración desde archivo"""
        self.config = self.cargar_config()
        messagebox.showinfo("Éxito", "Configuración recargada")
    
    def abrir_config_editor(self):
        """Abre el editor de config.json"""
        import os
        os.startfile(str(CONFIG_FILE))
    
    # ============= UTILIDADES =============
    def ejecutar_ssh(self, comando: str) -> tuple:
        """Ejecuta comando SSH en EC2"""
        ec2 = self.config['aws']['ec2']
        pem = ec2['pem_path']
        host = f"{ec2['user']}@{ec2['host']}"
        
        cmd = ["ssh", "-i", pem, "-o", "StrictHostKeyChecking=no", host, comando]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=60, encoding='utf-8', errors='replace')
            return result.returncode == 0, result.stdout, result.stderr
        except Exception as e:
            return False, "", str(e)
    
    def actualizar_status(self, texto: str):
        """Actualiza la barra de estado"""
        self.status_bar.config(text=texto)

# ============= MAIN =============
if __name__ == "__main__":
    root = tk.Tk()
    app = UniteSpeedGUI(root)
    root.mainloop()
