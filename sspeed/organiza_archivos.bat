@echo off
REM Script para organizar archivos sueltos en la raíz del proyecto
REM Mueve documentación y logs a docs/

REM Crear carpeta docs si no existe
if not exist "docs" mkdir docs

REM Mover archivos de documentación
move README_GITHUB.md docs\README_GITHUB.md
move BUGS_FLUTTER_IDENTIFICADOS.md docs\BUGS_FLUTTER_IDENTIFICADOS.md
move CORRECCIONES_COMPLETADAS.md docs\CORRECCIONES_COMPLETADAS.md
move PENDIENTES_WEB.md docs\PENDIENTES_WEB.md

REM Mover logs
move flutter_01.log docs\flutter_01.log
move flutter_02.log docs\flutter_02.log

REM Mensaje final
@echo Archivos movidos correctamente. Revisa la carpeta docs/.
