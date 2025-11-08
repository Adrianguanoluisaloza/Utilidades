"""
Script para crear usuarios admin, delivery, negocio y soporte en PostgreSQL RDS
Usa la contraseña '123456' para todos y genera el hash bcrypt automáticamente.
"""
import psycopg2
import bcrypt

# Configuración de la base de datos
DB_HOST = 'sspeed.cwq2qgqgqgqg.us-east-2.rds.amazonaws.com'
DB_PORT = '5432'
DB_NAME = 'sspeed'
DB_USER = 'Michael'
DB_PASS = 'Unidos2025!'

USUARIOS = [
    {'email': 'adrian@admin.com', 'nombre': 'Adrian', 'rol': 'admin'},
    {'email': 'delivery1@example.com', 'nombre': 'Delivery', 'rol': 'delivery'},
    {'email': 'negocio1@example.com', 'nombre': 'Negocio', 'rol': 'negocio'},
    {'email': 'soporte@example.com', 'nombre': 'Soporte', 'rol': 'soporte'},
]

password_plano = '123456'

try:
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )
    cur = conn.cursor()
    print('Conexión exitosa a la base de datos.')

    for usuario in USUARIOS:
        print(f"Creando usuario: {usuario['email']} ({usuario['rol']})...")
        password_hash = bcrypt.hashpw(password_plano.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        cur.execute("""
            INSERT INTO usuarios (email, nombre, rol, password)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (email) DO NOTHING;
        """, (usuario['email'], usuario['nombre'], usuario['rol'], password_hash))
        print(f"Usuario {usuario['email']} creado o ya existente.")

    conn.commit()
    cur.close()
    conn.close()
    print('Todos los usuarios han sido procesados.')
except Exception as e:
    print('Error al conectar o insertar:', e)
                print(f"Creando usuario: {usuario['email']} ({usuario['rol']})...")
                # Generar hash bcrypt para cada usuario
                password_hash = bcrypt.hashpw(password_plano.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
                # Ajusta el nombre de la tabla y los campos según tu modelo
                cur.execute("""
                    INSERT INTO usuarios (email, nombre, rol, password)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (email) DO NOTHING;
                """, (usuario['email'], usuario['nombre'], usuario['rol'], password_hash))
                print(f"Usuario {usuario['email']} creado o ya existente.")

            conn.commit()
            cur.close()
            conn.close()
            print('Todos los usuarios han sido procesados.')
        except Exception as e:
            print('Error al conectar o insertar:', e)
    
    if ok:
        print("✅ Conexión exitosa")
        return True
    else:
        print(f"❌ Error de conexión: {output}")
        return False

def verificar_tabla_usuarios():
    """Verifica que la tabla usuarios existe"""
    print("\n📋 Verificando tabla 'usuarios'...")
    query = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='usuarios';"
    ok, output = ejecutar_psql(query)
    
    if ok and '1' in output:
        print("✅ Tabla 'usuarios' existe")
        return True
    else:
        print("❌ Tabla 'usuarios' no existe")
        print("   Ejecuta primero: database/SCHEMA_COMPLETO_UNIFICADO.sql")
        return False

def usuario_existe(email):
    """Verifica si un usuario ya existe"""
    query = f"SELECT COUNT(*) FROM usuarios WHERE email = '{email}';"
    ok, output = ejecutar_psql(query)
    
    if ok and '1' in output:
        return True
    return False

def crear_usuario(usuario):
    """Crea un usuario en la base de datos"""
    email = usuario['email']
    
    # Verificar si ya existe
    if usuario_existe(email):
        print(f"⚠️  Usuario '{email}' ya existe (omitiendo)")
        return True
    
    # Crear usuario (el password debe ser hasheado por la API)
    query = f"""
    INSERT INTO usuarios (email, password_hash, rol, nombre, activo, verificado, created_at)
    VALUES (
        '{email}',
        '$2a$10$dummyhash',  -- Hash temporal
        '{usuario['rol']}',
        '{usuario['nombre']}',
        true,
        true,
        NOW()
    );
    """
    
    ok, output = ejecutar_psql(query)
    
    if ok:
        print(f"✅ Usuario '{email}' creado correctamente")
        return True
    else:
        print(f"❌ Error al crear '{email}': {output}")
        return False

def listar_usuarios():
    """Lista todos los usuarios de prueba"""
    print("\n📊 Usuarios actuales:")
    query = """
    SELECT 
        email, 
        rol, 
        activo,
        verificado,
        TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as creado
    FROM usuarios 
    WHERE email IN (
        'carlos.cliente@example.com',
        'adrian@admin.com',
        'delivery1@example.com',
        'negocio1@example.com',
        'soporte@example.com'
    )
    ORDER BY rol, email;
    """
    
    ok, output = ejecutar_psql(query)
    
    if ok:
        print(output)
    else:
        print(f"❌ Error: {output}")

def main():
    print("=" * 60)
    print("  CREAR USUARIOS DE PRUEBA - PostgreSQL RDS")
    print("=" * 60)
    print()
    
    # 1. Verificar conexión
    if not verificar_conexion():
        print("\n⛔ No se puede continuar sin conexión")
        return 1
    
    # 2. Verificar tabla
    if not verificar_tabla_usuarios():
        print("\n⛔ No se puede continuar sin tabla 'usuarios'")
        return 1
    
    # 3. Crear usuarios
    print(f"\n👥 Creando {len(USUARIOS)} usuarios de prueba...")
    print()
    
    exitosos = 0
    for usuario in USUARIOS:
        if crear_usuario(usuario):
            exitosos += 1
    
    print()
    print("=" * 60)
    print(f"Resultado: {exitosos}/{len(USUARIOS)} usuarios creados")
    print("=" * 60)
    
    # 4. Listar usuarios
    listar_usuarios()
    
    # 5. Nota importante
    print()
    print("⚠️  NOTA IMPORTANTE:")
    print("   Los usuarios fueron creados con un hash temporal.")
    print("   Para establecer las contraseñas correctas:")
    print("   1. Usa el endpoint POST /auth/register de la API")
    print("   2. O ejecuta un UPDATE con bcrypt hash correcto")
    print()
    print("   Contraseñas esperadas:")
    for u in USUARIOS:
        print(f"   - {u['email']}: {u['password']}")
    print()
    
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\n⚠️  Operación cancelada por el usuario")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error inesperado: {e}")
        sys.exit(1)
