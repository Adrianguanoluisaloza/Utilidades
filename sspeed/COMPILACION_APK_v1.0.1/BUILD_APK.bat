@echo off
echo ========================================
echo   COMPILACION SPEED7DELIVERY v1.0.1
echo ========================================
echo.
echo Este script compila la aplicacion en modo release
echo con firma de produccion incluida.
echo.

cd c:\Users\Adrian\Proyecto\sspeed

echo [1/3] Limpiando proyecto...
call flutter clean
if errorlevel 1 (
    echo ERROR: No se pudo limpiar el proyecto
    pause
    exit /b 1
)

echo.
echo [2/3] Obteniendo dependencias...
call flutter pub get
if errorlevel 1 (
    echo ERROR: No se pudieron obtener las dependencias
    pause
    exit /b 1
)

echo.
echo [3/3] Compilando APK release...
call flutter build apk --release
if errorlevel 1 (
    echo ERROR: La compilacion fallo
    pause
    exit /b 1
)

echo.
echo ========================================
echo   COMPILACION EXITOSA!
echo ========================================
echo.
echo APKs generados:
echo.
dir build\app\outputs\flutter-apk\*.apk /b
echo.
echo Ubicacion completa:
echo %cd%\build\app\outputs\flutter-apk\
echo.
echo ========================================
echo Version: 1.0.1 (Build 2)
echo Firmado con: speed7delivery-release.keystore
echo Fecha: %date% %time%
echo ========================================
echo.
pause
