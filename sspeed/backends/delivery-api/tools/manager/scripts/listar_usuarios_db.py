"""
Script para listar usuarios directamente desde la base de datos PostgreSQL RDS
No requiere psql, usa psycopg2
"""
import psycopg2
from psycopg2.extras import RealDictCursor

DB_CONFIG = {
    'host': 'databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com',
    'port': 5432,
    'user': 'Michael',
    'password': 'Unidos2025!',
    'database': 'databasefinal'
}

try:
    print("Conectando a PostgreSQL RDS...")
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    print("\nUsuarios en la base de datos:")
    cur.execute("SELECT email, rol, activo, verificado, nombre FROM usuarios ORDER BY rol, email;")
    usuarios = cur.fetchall()
    for u in usuarios:
        print(f"{u['rol']:10s} | {u['email']:30s} | {'✓' if u['activo'] else '✗'} | {'✓' if u['verificado'] else '✗'} | {u['nombre']}")
    
    print(f"\nTotal: {len(usuarios)} usuarios encontrados.")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error al conectar o consultar: {e}")
