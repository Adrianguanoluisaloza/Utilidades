@echo off
REM Script para crear usuario SOPORTE via SSH + psql
echo ===================================================================
echo CREACION DE USUARIO SOPORTE VIA SSH
echo ===================================================================
echo.
echo Conectando a EC2 y ejecutando comando SQL...
echo.

ssh -i "D:\Users\Adrian\Downloads\finalidad.pem" ubuntu@18.217.51.221 "PGPASSWORD='XxM7pYbQvtmOo3YdAbYs' psql -h databasefinal.c3o8qkm2u0hm.us-east-2.rds.amazonaws.com -U Michael -d databasefinal -c \"UPDATE usuarios SET id_rol = (SELECT id_rol FROM roles WHERE nombre = 'soporte') WHERE correo = 'juan.soporte@example.com'; SELECT u.nombre, u.correo, r.nombre as rol FROM usuarios u JOIN roles r ON u.id_rol = r.id_rol WHERE u.correo = 'juan.soporte@example.com';\""

echo.
echo ===================================================================
echo PROCESO COMPLETADO
echo ===================================================================
pause
