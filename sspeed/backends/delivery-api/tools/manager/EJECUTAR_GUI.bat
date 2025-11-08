@echo off
title Unite Speed Delivery - GUI v2.0
color 0A
cls

echo ========================================
echo   UNITE SPEED DELIVERY - GUI v2.0
echo   Aplicacion Visual Completa
echo ========================================
echo.

REM Detectar Python
where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python no esta instalado o no esta en el PATH
    echo Por favor instale Python 3.8+ desde https://www.python.org/
    pause
    exit /b 1
)

echo [OK] Python detectado
echo.

REM Verificar e instalar dependencias
echo Verificando dependencias...
pip show requests >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [INSTALANDO] requests...
    pip install requests
)

echo [OK] Dependencias verificadas
echo.

REM Ejecutar aplicacion GUI
echo ========================================
echo Iniciando aplicacion GUI...
echo ========================================
echo.

python unite_speed_gui.py

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Error al ejecutar la aplicacion
    pause
    exit /b 1
)

pause
