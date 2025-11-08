import requests

API_BASE_URL = "http://18.217.51.221:7070"

print("Probando endpoint de health...")
try:
    r = requests.get(f"{API_BASE_URL}/health", timeout=10)
    print(f"Status: {r.status_code}")
    print(f"Respuesta: {r.text}")
except Exception as e:
    print(f"Error al conectar al backend: {e}")
