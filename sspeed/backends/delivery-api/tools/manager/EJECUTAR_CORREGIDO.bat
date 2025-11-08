@echo off
title Unite Speed - Prueba con Correcciones
color 0A
cls

echo ============================================
echo   UNITE SPEED - EJECUTAR CON CORRECCIONES
echo ============================================
echo.
echo Se ha actualizado unite_speed_gui.py con:
echo.
echo   CORRECCIONES APLICADAS:
echo   1. /registro (no /auth/registro)
echo   2. POST para cambiar-password
echo   3. Campos completos en crear producto
echo   4. 'productos' en vez de 'items'
echo.
echo ============================================
echo.

pause

echo Iniciando aplicacion GUI corregida...
echo.

python unite_speed_gui.py

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Error al ejecutar
    pause
)
