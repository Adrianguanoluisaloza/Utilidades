@echo off
title Verificar Base de Datos - Unite Speed
color 0B
cls

echo ============================================
echo   VERIFICAR ESTRUCTURA DE BASE DE DATOS
echo   PostgreSQL - databasefinal
echo ============================================
echo.

set PGHOST=databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com
set PGPORT=5432
set PGUSER=Michael
set PGPASSWORD=Unidos2025!
set PGDATABASE=databasefinal

echo Conectando a PostgreSQL...
echo Host: %PGHOST%
echo Database: %PGDATABASE%
echo.

REM Verificar si psql está instalado
where psql >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PostgreSQL cliente no encontrado
    echo.
    echo Por favor instala PostgreSQL desde:
    echo https://www.postgresql.org/download/windows/
    echo.
    echo O agrega psql al PATH de Windows
    pause
    exit /b 1
)

echo [OK] Cliente PostgreSQL encontrado
echo.

echo ============================================
echo Ejecutando script de verificacion...
echo ============================================
echo.

psql -h %PGHOST% -U %PGUSER% -d %PGDATABASE% -f Scripts\verificar_datos_prueba.sql

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Error al ejecutar script
    echo Verifica las credenciales y la conexion
    pause
    exit /b 1
)

echo.
echo ============================================
echo VERIFICACION COMPLETADA
echo ============================================
echo.

pause
