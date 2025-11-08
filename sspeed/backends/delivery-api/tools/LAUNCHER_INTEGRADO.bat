@echo off
REM ================================================================
REM  LAUNCHER INTEGRADO - UNITE SPEED MANAGER + DEPLOY
REM  Abre GUI de gestión o Deploy según opción
REM ================================================================

cls
echo.
echo ========================================
echo   UNITE SPEED DELIVERY - LAUNCHER
echo ========================================
echo.
echo  [1] GUI Manager (Pruebas, BD, Logs)
echo  [2] Deploy Completo (Script)
echo  [3] Ambos (GUI + Deploy)
echo  [0] Salir
echo.
set /p "OPCION=Selecciona una opcion: "

if "%OPCION%"=="1" goto GUI
if "%OPCION%"=="2" goto DEPLOY
if "%OPCION%"=="3" goto AMBOS
if "%OPCION%"=="0" goto FIN
goto FIN

:GUI
echo.
echo Abriendo GUI Manager...
cd /d "%~dp0manager"
start "" python unite_speed_gui.py
goto FIN

:DEPLOY
echo.
echo Abriendo Deploy Completo...
cd /d "%~dp0..\deploy"
start "" DEPLOY_COMPLETO.bat
goto FIN

:AMBOS
echo.
echo Abriendo GUI Manager...
cd /d "%~dp0manager"
start "" python unite_speed_gui.py
timeout /t 2 /nobreak >nul
echo.
echo Abriendo Deploy Completo...
cd /d "%~dp0..\deploy"
start "" DEPLOY_COMPLETO.bat
goto FIN

:FIN
echo.
echo Listo!
timeout /t 2 /nobreak >nul
exit /b 0
