"""
Script para actualizar el rol del usuario soporte en PostgreSQL
"""
import psycopg2
from psycopg2 import sql

# Configuración de la base de datos
DB_CONFIG = {
    'host': 'databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com',
    'port': 5432,  # PostgreSQL usa puerto 5432 (no 3306 como MySQL)
    'database': 'databasefinal',
    'user': 'Michael',
    'password': 'XxM7pYbQvtmOo3YdAbYs'
}

def actualizar_rol_soporte():
    """Actualiza el rol del usuario juan.soporte@example.com a 'soporte'"""
    
    print("=" * 70)
    print("🔄 ACTUALIZANDO ROL DE USUARIO SOPORTE")
    print("=" * 70)
    
    try:
        # Conectar a PostgreSQL
        print("\n📡 Conectando a PostgreSQL...")
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        print("✅ Conexión exitosa")
        
        # Verificar que existe el rol 'soporte'
        print("\n🔍 Verificando rol 'soporte'...")
        cursor.execute("SELECT id_rol, nombre FROM roles WHERE nombre = 'soporte'")
        rol = cursor.fetchone()
        
        if not rol:
            print("❌ El rol 'soporte' no existe en la tabla roles")
            print("   Creando rol 'soporte'...")
            
            cursor.execute("""
                INSERT INTO roles (nombre, descripcion, created_at, updated_at)
                VALUES ('soporte', 'Personal de soporte técnico', NOW(), NOW())
                RETURNING id_rol, nombre
            """)
            rol = cursor.fetchone()
            conn.commit()
            print(f"✅ Rol 'soporte' creado con ID: {rol[0]}")
        else:
            print(f"✅ Rol 'soporte' encontrado con ID: {rol[0]}")
        
        id_rol_soporte = rol[0]
        
        # Verificar que existe el usuario
        print("\n🔍 Verificando usuario juan.soporte@example.com...")
        cursor.execute("""
            SELECT id_usuario, nombre, correo, id_rol 
            FROM usuarios 
            WHERE correo = 'juan.soporte@example.com'
        """)
        usuario = cursor.fetchone()
        
        if not usuario:
            print("❌ Usuario no encontrado")
            print("   Ejecuta primero: crear_usuarios_completo.py")
            return False
        
        print(f"✅ Usuario encontrado:")
        print(f"   ID: {usuario[0]}")
        print(f"   Nombre: {usuario[1]}")
        print(f"   Correo: {usuario[2]}")
        print(f"   Rol actual: {usuario[3]}")
        
        # Actualizar el rol
        print(f"\n🔄 Actualizando rol a 'soporte' (ID: {id_rol_soporte})...")
        cursor.execute("""
            UPDATE usuarios
            SET id_rol = %s, updated_at = NOW()
            WHERE correo = 'juan.soporte@example.com'
        """, (id_rol_soporte,))
        
        conn.commit()
        print(f"✅ Rol actualizado exitosamente")
        
        # Verificar actualización
        print("\n🔍 Verificando actualización...")
        cursor.execute("""
            SELECT u.id_usuario, u.nombre, u.correo, r.nombre as rol
            FROM usuarios u
            JOIN roles r ON u.id_rol = r.id_rol
            WHERE u.correo = 'juan.soporte@example.com'
        """)
        usuario_actualizado = cursor.fetchone()
        
        print(f"✅ Usuario actualizado:")
        print(f"   ID: {usuario_actualizado[0]}")
        print(f"   Nombre: {usuario_actualizado[1]}")
        print(f"   Correo: {usuario_actualizado[2]}")
        print(f"   Rol: {usuario_actualizado[3]}")
        
        cursor.close()
        conn.close()
        
        print("\n" + "=" * 70)
        print("✅ ACTUALIZACIÓN COMPLETADA EXITOSAMENTE")
        print("=" * 70)
        print("\n📝 Puedes usar estas credenciales:")
        print("   Correo: juan.soporte@example.com")
        print("   Password: Soporte123!")
        print("   Rol: soporte")
        
        return True
        
    except psycopg2.Error as e:
        print(f"\n❌ Error de PostgreSQL: {e}")
        return False
    except Exception as e:
        print(f"\n❌ Error inesperado: {e}")
        return False

if __name__ == "__main__":
    actualizar_rol_soporte()
