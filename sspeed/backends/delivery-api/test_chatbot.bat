@echo off
echo ========================================
echo DIAGNOSTICO RAPIDO - ERROR 500 CHATBOT
echo ========================================

echo.
echo 1. Verificando variables de entorno...
if not defined DB_PASSWORD (
    echo ❌ DB_PASSWORD no definida
) else (
    echo ✅ DB_PASSWORD definida
)

if not defined GEMINI_API_KEY (
    echo ❌ GEMINI_API_KEY no definida
) else (
    echo ✅ GEMINI_API_KEY definida
)

echo.
echo 2. Verificando conexion PostgreSQL...
psql -h localhost -U postgres -d postgres -c "SELECT 1 as test;" 2>nul
if %errorlevel% equ 0 (
    echo ✅ PostgreSQL conectado
) else (
    echo ❌ PostgreSQL NO conectado - ESTE ES EL PROBLEMA
    echo Solucion: Iniciar PostgreSQL o corregir credenciales
)

echo.
echo 3. Verificando servidor API...
curl -s http://localhost:7070/health >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Servidor API respondiendo
) else (
    echo ❌ Servidor API no responde
    echo Solucion: Iniciar el servidor Java
)

echo.
echo 4. Test API Gemini...
curl -s -H "Content-Type: application/json" -d "{\"contents\":[{\"parts\":[{\"text\":\"test\"}]}]}" "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=%GEMINI_API_KEY%" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Gemini API funciona
) else (
    echo ❌ Gemini API falla - verificar API key
)

echo.
echo ========================================
echo RESULTADO: Revisa los ❌ arriba
echo ========================================
pause