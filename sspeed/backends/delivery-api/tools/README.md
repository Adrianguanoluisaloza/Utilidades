# Herramientas de pruebas

Este directorio contiene herramientas para probar la API de delivery.

## gemini_load_test.py

Script para probar la carga del endpoint del bot que usa Gemini con enrutamiento inteligente.

Requisitos:
- Python 3.9+
- `pip install requests`

Parámetros:
- `--base-url` URL base de la API (por defecto `http://localhost:7070`)
- `--email` Correo del usuario para login
- `--password` Contraseña del usuario para login
- `--concurrency` Concurrencia (hilos simultáneos)
- `--requests` Total de solicitudes a enviar
- `--user-id` ID de usuario a usar como `idRemitente` (por defecto 1)

Ejemplo (Windows cmd):

```bat
cd backends\delivery-api\tools
python gemini_load_test.py --base-url http://localhost:7070 ^
  --email demo@correo.com --password 123456 ^
  --concurrency 10 --requests 100
```

Salida:
- Métricas de latencia (p50/p90/p99)
- Conteo de modelos usados (`X-LLM-Model`/`model_used`)
- Ejemplos de errores (si los hay)

Notas:
- El endpoint protegido requiere token. El script inicia sesión automáticamente.
- Para validar el enrutamiento, observe la distribución entre `gemini-2.5-flash`, `gemini-2.5-pro` y `gemini-2.0-flash-lite`.
