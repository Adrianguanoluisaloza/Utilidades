@echo off
echo ========================================
echo   GENERAR KEYSTORE PARA FIRMA RELEASE
echo ========================================
echo.
echo Este script genera un archivo keystore para firmar tu APK de release.
echo.

set KEYSTORE_FILE=speed7delivery-release.keystore
set KEY_ALIAS=speed7delivery

echo Generando keystore en: android\app\%KEYSTORE_FILE%
echo.

cd app
keytool -genkey -v -keystore %KEYSTORE_FILE% -keyalg RSA -keysize 2048 -validity 10000 -alias %KEY_ALIAS%

echo.
echo ========================================
echo Keystore generado exitosamente!
echo.
echo Ubicacion: android\app\%KEYSTORE_FILE%
echo Alias: %KEY_ALIAS%
echo.
echo IMPORTANTE: Guarda la contrasena que ingresaste.
echo ========================================
pause
