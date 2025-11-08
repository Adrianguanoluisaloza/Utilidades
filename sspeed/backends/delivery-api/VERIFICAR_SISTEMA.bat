@echo off
title Verificacion de Sistema Integrado - Unite Speed
color 0B
cls

echo ============================================
echo   VERIFICACION DE SISTEMA INTEGRADO
echo   Unite Speed Delivery - PostgreSQL RDS
echo ============================================
echo.

REM Configuracion de PostgreSQL
set PGHOST=databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com
set PGPORT=5432
set PGUSER=Michael
set PGPASSWORD=Unidos2025!
set PGDATABASE=databasefinal

echo [Paso 1/4] Verificando cliente PostgreSQL...
where psql >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PostgreSQL cliente no encontrado
    echo Por favor instala: https://www.postgresql.org/download/windows/
    pause
    exit /b 1
)
echo [OK] Cliente PostgreSQL encontrado
echo.

echo [Paso 2/4] Probando conexion a RDS...
psql -h %PGHOST% -U %PGUSER% -d %PGDATABASE% -c "SELECT 1 as test;" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] No se puede conectar a la base de datos
    echo Verifica:
    echo   - Host: %PGHOST%
    echo   - User: %PGUSER%
    echo   - Database: %PGDATABASE%
    echo   - Password: [configurada]
    echo   - Puerto: %PGPORT%
    pause
    exit /b 1
)
echo [OK] Conexion exitosa a RDS
echo.

echo [Paso 3/4] Verificando tablas existentes...
psql -h %PGHOST% -U %PGUSER% -d %PGDATABASE% -c "SELECT COUNT(*) as total_tablas FROM information_schema.tables WHERE table_schema='public';"
echo.

echo [Paso 4/4] Verificando usuarios de prueba...
psql -h %PGHOST% -U %PGUSER% -d %PGDATABASE% -c "SELECT email, rol, activo FROM usuarios WHERE email IN ('carlos.cliente@example.com', 'adrian@admin.com', 'delivery1@example.com', 'negocio1@example.com', 'soporte@example.com');"
echo.

echo ============================================
echo   VERIFICACION COMPLETADA
echo ============================================
echo.
echo Todo listo para usar el sistema integrado!
echo.
echo Opciones disponibles:
echo   1. GUI Manager:     tools\manager\EJECUTAR_GUI.bat
echo   2. Deploy Script:   deploy\DEPLOY_COMPLETO.bat
echo   3. Launcher:        tools\LAUNCHER_INTEGRADO.bat
echo.

pause
