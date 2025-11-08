@echo off
REM Script para compilar la aplicación Android en modo Debug
echo ====================================
echo   Compilando aplicacion Android
echo ====================================
echo.

cd /d "%~dp0"

echo Limpiando proyecto...
call gradlew.bat clean

echo.
echo Compilando APK Debug...
call gradlew.bat assembleDebug

echo.
echo ====================================
if %ERRORLEVEL% EQU 0 (
    echo   COMPILACION EXITOSA
    echo   APK ubicado en: app\build\outputs\apk\debug\
) else (
    echo   ERROR EN LA COMPILACION
)
echo ====================================
pause

