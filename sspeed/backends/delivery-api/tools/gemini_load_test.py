#!/usr/bin/env python3
"""
Prueba de carga/concurrencia para el endpoint del bot que usa Gemini con enrutamiento inteligente.

Requisitos:
  - Python 3.9+
  - pip install requests

Uso rápido:
  python gemini_load_test.py --base-url http://localhost:7070 \
      --email demo@correo.com --password 123456 \
      --concurrency 10 --requests 100

El script:
  1) Inicia sesión para obtener un token JWT
  2) Lanza múltiples hilos que envían mensajes al endpoint /chat/bot/mensajes
  3) Mide latencia, recoge el modelo usado (cabecera X-LLM-Model y JSON model_used)
  4) Calcula métricas simples al final
"""

import argparse
import concurrent.futures as futures
import json
import os
import random
import string
import time
from dataclasses import dataclass
from typing import Dict, List, Optional

import requests


@dataclass
class Result:
    ok: bool
    status: int
    latency_ms: float
    model: Optional[str]
    error: Optional[str]


def login(base_url: str, email: str, password: str) -> str:
    url = f"{base_url.rstrip('/')}/auth/login"
    resp = requests.post(url, json={"correo": email, "contrasena": password}, timeout=10)
    resp.raise_for_status()
    data = resp.json()
    # ApiResponse: { status, message, data: { token, ... } }
    token = data.get("data", {}).get("token")
    if not token:
        raise RuntimeError("No se obtuvo token en la respuesta de login")
    return token


def random_message() -> str:
    corpus = [
        "¿Dónde está mi pedido?",
        "Quiero cancelar mi pedido",
        "Hola, ¿puedes ayudarme?",
        "¿Cuánto tarda la entrega?",
        "Recomiéndame algo para cenar",
        "Necesito cambiar la dirección de entrega",
        "Gracias",
        "Tengo un problema con mi pedido",
        "¿Qué métodos de pago aceptan?",
        "¿Hay promociones hoy?",
    ]
    # Añadir algo de variabilidad en longitud
    tail = ''.join(random.choices(string.ascii_letters + ' ', k=random.randint(0, 60)))
    return random.choice(corpus) + " " + tail


def send_message(base_url: str, token: str, id_remitente: int) -> Result:
    url = f"{base_url.rstrip('/')}/chat/bot/mensajes"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    body = {
        "idConversacion": None,  # dejar que el backend cree/asegure conversación
        "idRemitente": id_remitente,
        "mensaje": random_message(),
    }
    t0 = time.perf_counter()
    try:
        resp = requests.post(url, headers=headers, json=body, timeout=30)
        latency_ms = (time.perf_counter() - t0) * 1000.0
        ok = resp.status_code // 100 == 2
        model = resp.headers.get("X-LLM-Model")
        if ok:
            try:
                payload = resp.json()
                model = payload.get("data", {}).get("model_used") or model
            except Exception:
                pass
            return Result(True, resp.status_code, latency_ms, model, None)
        else:
            return Result(False, resp.status_code, latency_ms, model, resp.text[:200])
    except Exception as e:
        latency_ms = (time.perf_counter() - t0) * 1000.0
        return Result(False, 0, latency_ms, None, str(e))


def main():
    parser = argparse.ArgumentParser(description="Carga Gemini Router")
    parser.add_argument("--base-url", default=os.environ.get("API_BASE_URL", "http://localhost:7070"))
    parser.add_argument("--email", default=os.environ.get("API_EMAIL"))
    parser.add_argument("--password", default=os.environ.get("API_PASSWORD"))
    parser.add_argument("--requests", type=int, default=50)
    parser.add_argument("--concurrency", type=int, default=5)
    parser.add_argument("--user-id", type=int, default=1, help="ID de usuario para idRemitente")
    args = parser.parse_args()

    if not args.email or not args.password:
        raise SystemExit("Debe proporcionar --email y --password o variables de entorno API_EMAIL/API_PASSWORD")

    print(f"Login en {args.base_url} ...")
    token = login(args.base_url, args.email, args.password)
    print("Token OK\n")

    results: List[Result] = []
    print(f"Enviando {args.requests} solicitudes con concurrencia {args.concurrency} ...")
    with futures.ThreadPoolExecutor(max_workers=args.concurrency) as ex:
        tasks = [ex.submit(send_message, args.base_url, token, args.user_id) for _ in range(args.requests)]
        for i, f in enumerate(futures.as_completed(tasks), 1):
            r = f.result()
            results.append(r)
            if i % max(1, args.requests // 10) == 0:
                print(f"  progreso: {i}/{args.requests}")

    # Métricas
    latencies = [r.latency_ms for r in results]
    ok = [r for r in results if r.ok]
    models: Dict[str, int] = {}
    for r in results:
        if r.model:
            models[r.model] = models.get(r.model, 0) + 1

    def pct(p: float, data: List[float]) -> float:
        if not data:
            return 0.0
        s = sorted(data)
        k = int(p * (len(s) - 1))
        return s[k]

    print("\n===== RESUMEN =====")
    print(f"Total: {len(results)}  OK: {len(ok)}  FAIL: {len(results) - len(ok)}")
    if latencies:
        print(f"Latencia ms -> p50: {pct(0.50, latencies):.1f}  p90: {pct(0.90, latencies):.1f}  p99: {pct(0.99, latencies):.1f}")
    if models:
        print("Modelos usados:")
        for m, c in models.items():
            print(f"  {m}: {c}")

    fails = [r for r in results if not r.ok]
    if fails:
        print("\nEjemplos de errores:")
        for r in fails[:5]:
            print(f"  status={r.status} err={r.error}")


if __name__ == "__main__":
    main()
