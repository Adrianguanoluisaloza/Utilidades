@echo off
REM Script para organizar archivos en backends/delivery-api
REM Mueve archivos originales y elimina copias vacías

REM Documentación
move README.md docs\README.md
move AUDITORIA_COMPLETA_API.md docs\AUDITORIA_COMPLETA_API.md
move ARREGLOS_APLICADOS.md docs\ARREGLOS_APLICADOS.md
move DIAGNOSTICO_ERROR_500.md docs\DIAGNOSTICO_ERROR_500.md
move CONEXIONES_API_VERIFICADAS.md docs\CONEXIONES_API_VERIFICADAS.md

REM Scripts
move DEPLOY_AUTOMATICO.bat scripts\DEPLOY_AUTOMATICO.bat
move DEPLOY_COMPLETO.cmd scripts\DEPLOY_COMPLETO.cmd
move DEPLOY_DOCKER.bat scripts\DEPLOY_DOCKER.bat
move SUBIR_JAR.bat scripts\SUBIR_JAR.bat
move redeploy.bat scripts\redeploy.bat

REM Configuración
move pom.xml config\pom.xml
move settings.gradle.kts config\settings.gradle.kts
move build.gradle.kts config\build.gradle.kts

REM Infraestructura
move docker-compose.yml infra\docker-compose.yml

REM Eliminar copias vacías
del docs\README.md
copy docs\README.md docs\README.md

del docs\AUDITORIA_COMPLETA_API.md
copy docs\AUDITORIA_COMPLETA_API.md docs\AUDITORIA_COMPLETA_API.md

del docs\ARREGLOS_APLICADOS.md
copy docs\ARREGLOS_APLICADOS.md docs\ARREGLOS_APLICADOS.md

del docs\DIAGNOSTICO_ERROR_500.md
copy docs\DIAGNOSTICO_ERROR_500.md docs\DIAGNOSTICO_ERROR_500.md

del docs\CONEXIONES_API_VERIFICADAS.md
copy docs\CONEXIONES_API_VERIFICADAS.md docs\CONEXIONES_API_VERIFICADAS.md

del scripts\DEPLOY_AUTOMATICO.bat
copy scripts\DEPLOY_AUTOMATICO.bat scripts\DEPLOY_AUTOMATICO.bat

del scripts\DEPLOY_COMPLETO.cmd
copy scripts\DEPLOY_COMPLETO.cmd scripts\DEPLOY_COMPLETO.cmd

del scripts\DEPLOY_DOCKER.bat
copy scripts\DEPLOY_DOCKER.bat scripts\DEPLOY_DOCKER.bat

del scripts\SUBIR_JAR.bat
copy scripts\SUBIR_JAR.bat scripts\SUBIR_JAR.bat

del scripts\redeploy.bat
copy scripts\redeploy.bat scripts\redeploy.bat

del config\pom.xml
copy config\pom.xml config\pom.xml

del config\settings.gradle.kts
copy config\settings.gradle.kts config\settings.gradle.kts

del config\build.gradle.kts
copy config\build.gradle.kts config\build.gradle.kts

del infra\docker-compose.yml
copy infra\docker-compose.yml infra\docker-compose.yml

@echo Organización completada. Revisa las carpetas docs, scripts, config e infra.
