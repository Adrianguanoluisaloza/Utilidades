@echo off
REM ================================================================
REM  Despliegue delivery-api (Windows CMD) sin CloudWatch logs
REM  Edita las variables de abajo y ejecuta este .cmd
REM ================================================================

REM --- VARIABLES (EDITA SI ES NECESARIO) ---
set "PEM=C:\Users\Adrian\Downloads\finalidad.pem"
set "HOST=18.217.51.221"
set "USER=ubuntu"
set "REMOTE=/home/ubuntu"
set "REPO=C:\Users\Adrian\Proyecto\sspeed"

REM --- 1) Construir JAR ---
call mvn -f "%REPO%\backends\delivery-api\pom.xml" -DskipTests package || goto :error

REM --- 2) Subir JAR ---
if not exist "%REPO%\backends\delivery-api\target\delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar" (
  echo [ERROR] No se encontro el JAR esperado en target\delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar
  goto :error
)
call scp -i "%PEM" "%REPO%\backends\delivery-api\target\delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar" "%USER%@%HOST%:%REMOTE%/target/" || goto :error

REM --- 3) (Opcional) Subir Dockerfile/compose si quieres reemplazarlos ---
REM call scp -i "%PEM" "%REPO%\backends\delivery-api\Dockerfile" "%USER%@%HOST%:%REMOTE%/" || goto :error
REM call scp -i "%PEM" "%REPO%\backends\delivery-api\docker-compose.yml" "%USER%@%HOST%:%REMOTE%/" || goto :error

REM --- 4) Reconstruir y levantar en el servidor ---
call ssh -i "%PEM" %USER%@%HOST% "cd %REMOTE% && docker-compose down && docker-compose build --no-cache && docker-compose up -d && docker ps --filter name=delivery-api" || goto :error

REM --- 5) Verificar salud ---
call ssh -i "%PEM" %USER%@%HOST% "for i in {1..10}; do curl -fsS http://localhost:7070/health && break || sleep 3; done" || goto :error

echo.
echo [OK] Despliegue completo. Puedes ver logs con:
echo     ssh -i "%PEM%" %USER%@%HOST% "docker logs -f delivery-api"

goto :eof

:error
echo.
echo [FAIL] Ocurrio un error en el despliegue.
exit /b 1
