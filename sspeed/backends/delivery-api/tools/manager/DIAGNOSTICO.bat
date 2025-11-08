@echo off
title Diagnostico Unite Speed GUI
color 0E
cls

echo ============================================
echo   DIAGNOSTICO - UNITE SPEED GUI
echo ============================================
echo.
echo Este script verificara si hay problemas
echo con la aplicacion GUI.
echo.
echo Ejecutando diagnostico...
echo.

python DIAGNOSTICO.py

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Hubo un problema
    echo Copia el error de arriba y compartelo
)

pause
