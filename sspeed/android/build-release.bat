@echo off
REM Script para compilar la aplicación Android en modo Release
echo ====================================
echo   Compilando aplicacion Android
echo   MODO RELEASE
echo ====================================
echo.

cd /d "%~dp0"

echo Limpiando proyecto...
call gradlew.bat clean

echo.
echo Compilando APK Release...
call gradlew.bat assembleRelease

echo.
echo ====================================
if %ERRORLEVEL% EQU 0 (
    echo   COMPILACION EXITOSA
    echo   APK ubicado en: app\build\outputs\apk\release\
) else (
    echo   ERROR EN LA COMPILACION
)
echo ====================================
pause

