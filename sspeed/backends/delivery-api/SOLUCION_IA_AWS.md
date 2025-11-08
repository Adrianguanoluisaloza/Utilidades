# 🔧 Solución: IA no funciona en AWS

## Problemas identificados y solucionados

### ❌ Problema 1: Error tipográfico en modelo Gemini
**Error encontrado**: `GEMINI_MODEL=gemini-2.5-flash-Prview`
**Solución**: Corregido a `GEMINI_MODEL=gemini-1.5-flash`

### ❌ Problema 2: Variables de entorno faltantes
**Errores**: Faltaban DB_URL, DB_USER, DB_PASSWORD, JWT_SECRET
**Solución**: Agregadas al archivo .env

### ❌ Problema 3: Modelo inexistente
**Error**: `gemini-2.5-flash-Preview` no existe
**Solución**: Usar modelos válidos del tier gratuito

## 🚀 Pasos para solucionar

### 1. Verificar API Key de Gemini
```bash
curl -H "Content-Type: application/json" \
     -d '{"contents":[{"parts":[{"text":"Hello"}]}]}' \
     "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=TU_API_KEY"
```

### 2. Configurar variables para AWS
- Copia `.env.aws` a `.env` en tu instancia AWS
- Ajusta las variables según tu configuración:
  - `DB_URL`: Endpoint de tu RDS
  - `DB_USER` y `DB_PASSWORD`: Credenciales de RDS
  - `JWT_SECRET`: Clave segura para producción

### 3. Verificar conectividad de base de datos
```java
// El código ya incluye validación en Database.ping()
// Revisa los logs para errores de conexión
```

### 4. Modelos Gemini disponibles (tier gratuito)
- ✅ `gemini-1.5-flash` - Rápido, 1M tokens/min
- ✅ `gemini-1.5-pro` - Más potente, 32K tokens/min
- ❌ `gemini-2.5-flash-Preview` - NO EXISTE

### 5. Rate limits configurados
```
GEMINI_PRIMARY_RPM=15    # 15 requests por minuto
GEMINI_PRIMARY_TPM=1000000  # 1M tokens por minuto
```

## 🔍 Debugging

### Verificar logs del servidor
```bash
# Buscar errores de Gemini
grep -i "gemini\|error" logs/application.log

# Verificar conectividad
curl http://localhost:7070/health
```

### Test manual del chatbot
```bash
curl -X POST http://localhost:7070/chat/bot/mensajes \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_TOKEN" \
  -d '{"idRemitente": 1, "mensaje": "Hola"}'
```

## ✅ Verificación final
1. ✅ Modelo corregido: `gemini-1.5-flash`
2. ✅ Variables de entorno completas
3. ✅ Rate limits configurados
4. ✅ Configuración AWS lista

## 🆘 Si sigue sin funcionar
1. Verifica que tu API key de Gemini esté activa
2. Confirma que tienes cuota disponible en Google AI Studio
3. Revisa los logs de AWS CloudWatch
4. Verifica conectividad de red (security groups)