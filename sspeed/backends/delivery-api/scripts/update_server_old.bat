@echo off
REM ============================================================
REM Script para actualizar el backend en AWS EC2
REM ============================================================

echo.
echo ============================================
echo   DEPLOY BACKEND A AWS EC2
echo ============================================
echo.

set JAR_FILE=c:\Users\Adrian\Proyecto\sspeed\backends\delivery-api\target\delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar
set KEY_FILE=C:\Users\Adrian\Videos\finalidad.pem
set EC2_HOST=ubuntu@18.217.51.221
set REMOTE_PATH=/home/ubuntu/delivery-api.jar
set DOCKER_CONTAINER=delivery-api

REM Verificar que el JAR existe
if not exist "%JAR_FILE%" (
    echo ❌ ERROR: No se encontro el JAR compilado
    echo 💡 Ejecuta primero: mvn clean package -DskipTests
    pause
    exit /b 1
)

echo ✅ JAR encontrado: %JAR_FILE%
echo.
echo 📤 Subiendo JAR a EC2...
echo.

scp -i "%KEY_FILE%" "%JAR_FILE%" %EC2_HOST%:%REMOTE_PATH%

if errorlevel 1 (
    echo.
    echo ❌ ERROR: Fallo la subida del JAR
    pause
    exit /b 1
)

echo.
echo ✅ JAR subido correctamente
echo.
echo 🔄 Actualizando contenedor Docker...
echo.

ssh -i "%KEY_FILE%" %EC2_HOST% "sudo docker cp %REMOTE_PATH% %DOCKER_CONTAINER%:/app/app.jar && sudo docker restart %DOCKER_CONTAINER%"

if errorlevel 1 (
    echo.
    echo ⚠️  ADVERTENCIA: No se pudo actualizar el contenedor
    echo 💡 Intenta manualmente: sudo docker restart %DOCKER_CONTAINER%
    pause
    exit /b 1
)

echo.
echo ✅ Contenedor reiniciado
echo.
echo 🔍 Verificando logs del contenedor...
echo.

ssh -i "%KEY_FILE%" %EC2_HOST% "sudo docker logs --tail 30 %DOCKER_CONTAINER%"

echo.
echo ============================================
echo   ✅ DEPLOY COMPLETADO
echo ============================================
echo.
echo 🌐 API disponible en: http://18.217.51.221:7070/health
echo.
pause
