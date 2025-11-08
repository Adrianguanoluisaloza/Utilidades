"""
Verificación final de usuarios NEGOCIO y SOPORTE
"""
import requests

API_BASE = "http://18.217.51.221:7070"

def verificar_usuario(rol, correo, password):
    """Verifica login y obtiene información del usuario"""
    print(f"\n{'='*70}")
    print(f"🔐 VERIFICANDO USUARIO: {rol.upper()}")
    print(f"{'='*70}")
    print(f"📧 Correo: {correo}")
    print(f"🔑 Password: {password}")
    
    # Login
    url = f"{API_BASE}/auth/login"
    data = {
        "correo": correo,
        "password": password
    }
    
    try:
        resp = requests.post(url, json=data, timeout=15)
        
        if resp.status_code == 200:
            data = resp.json()
            token = data.get('token') or data.get('data', {}).get('token')
            user_data = data.get('data', {})
            
            print(f"\n✅ LOGIN EXITOSO")
            print(f"🎫 Token: {token[:40]}...")
            print(f"👤 Datos del usuario:")
            
            if isinstance(user_data, dict):
                for key, value in user_data.items():
                    if key != 'token':
                        print(f"   {key}: {value}")
            
            # Probar un endpoint permitido
            print(f"\n🧪 Probando endpoint /productos...")
            headers = {"Authorization": f"Bearer {token}"}
            resp2 = requests.get(f"{API_BASE}/productos", headers=headers, timeout=15)
            
            if resp2.status_code == 200:
                productos = resp2.json()
                count = len(productos) if isinstance(productos, list) else 0
                print(f"✅ Endpoint /productos OK - {count} productos encontrados")
            else:
                print(f"⚠️ Endpoint /productos: {resp2.status_code}")
            
            return True
        else:
            print(f"\n❌ LOGIN FALLIDO")
            print(f"Status: {resp.status_code}")
            print(f"Respuesta: {resp.text}")
            return False
            
    except Exception as e:
        print(f"\n❌ EXCEPCIÓN: {e}")
        return False

if __name__ == "__main__":
    print("="*70)
    print("🚀 VERIFICACIÓN FINAL DE USUARIOS CREADOS")
    print("="*70)
    
    # Verificar NEGOCIO
    negocio_ok = verificar_usuario(
        "negocio",
        "maria.negocio@example.com",
        "Negocio123!"
    )
    
    # Verificar SOPORTE
    soporte_ok = verificar_usuario(
        "soporte",
        "juan.soporte@example.com",
        "Soporte123!"
    )
    
    # Resumen final
    print(f"\n{'='*70}")
    print("📊 RESUMEN FINAL")
    print(f"{'='*70}")
    print(f"✅ Usuario NEGOCIO: {'FUNCIONAL' if negocio_ok else 'ERROR'}")
    print(f"   📧 maria.negocio@example.com")
    print(f"   🔑 Negocio123!")
    print()
    print(f"✅ Usuario SOPORTE: {'FUNCIONAL' if soporte_ok else 'ERROR'}")
    print(f"   📧 juan.soporte@example.com")
    print(f"   🔑 Soporte123!")
    print(f"{'='*70}")
    
    if negocio_ok and soporte_ok:
        print("\n🎉 TODOS LOS USUARIOS ESTÁN LISTOS PARA USAR EN EL GUI")
        print("\n📝 Próximo paso:")
        print("   1. Abre el GUI: python unite_speed_gui.py")
        print("   2. Selecciona rol: negocio")
        print("   3. Click 'Obtener Token'")
        print("   4. Click 'Probar TODOS los Endpoints'")
        print("   5. Repite con rol: soporte")
    else:
        print("\n⚠️ Algunos usuarios tienen problemas")
    
    print(f"{'='*70}\n")
