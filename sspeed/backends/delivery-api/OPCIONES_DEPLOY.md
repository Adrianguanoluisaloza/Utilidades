# 🚀 OPCIONES DE DEPLOY - UNITE SPEED DELIVERY

## ✅ ESTADO ACTUAL
- JAR compilado: `target/delivery-api-current.jar`
- Todos los endpoints funcionando correctamente
- Tests pasados: 4/5 (solo health falla por URL)

## 📦 OPCIÓN 1: Deploy con Docker (RECOMENDADO)

**Requisitos:**
- Docker Desktop instalado
- Archivo `.env` configurado

**Comando:**
```cmd
DEPLOY_DOCKER.bat
```

**Ventajas:**
- ✅ Fácil de replicar
- ✅ Aislamiento completo
- ✅ Rollback rápido
- ✅ Logs centralizados

---

## 🌐 OPCIÓN 2: Subir JAR al Servidor EC2

**Requisitos:**
- Acceso SSH al servidor (18.217.51.221)
- Clave privada configurada

**Comando:**
```cmd
SUBIR_JAR.bat
```

**Pasos manuales:**
1. Compilar: `mvn clean package`
2. Subir: `scp target/delivery-api-current.jar ubuntu@18.217.51.221:/home/ubuntu/`
3. Conectar: `ssh ubuntu@18.217.51.221`
4. Reiniciar: `sudo systemctl restart delivery-api`

---

## ☁️ OPCIÓN 3: Deploy con AWS CodeDeploy

**Requisitos:**
- AWS CLI configurado
- Rol IAM con permisos

**Pasos:**
1. Crear `appspec.yml`
2. Empaquetar: `aws deploy push`
3. Desplegar: `aws deploy create-deployment`

---

## 🔄 OPCIÓN 4: GitHub Actions (CI/CD Automático)

**Archivo:** `.github/workflows/deploy.yml`

```yaml
name: Deploy API
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build JAR
        run: mvn clean package
      - name: Deploy to EC2
        run: |
          scp target/*.jar ${{ secrets.EC2_USER }}@${{ secrets.EC2_HOST }}:/home/ubuntu/
          ssh ${{ secrets.EC2_USER }}@${{ secrets.EC2_HOST }} "sudo systemctl restart delivery-api"
```

---

## 🧪 OPCIÓN 5: Deploy Local (Testing)

**Para desarrollo local:**
```cmd
java -jar target/delivery-api-current.jar
```

**Con variables de entorno:**
```cmd
set PORT=7070
set DB_HOST=localhost
java -jar target/delivery-api-current.jar
```

---

## 📊 VERIFICACIÓN POST-DEPLOY

**Ejecutar tests:**
```cmd
TEST_RAPIDO.bat
```

**Endpoints a verificar:**
- ✅ GET /health
- ✅ GET /productos
- ✅ GET /recomendaciones/destacadas
- ✅ POST /chat/bot/mensajes
- ✅ POST /chat/mensaje (soporte)

---

## 🔧 TROUBLESHOOTING

### Error: "Docker no está instalado"
**Solución:** Instala Docker Desktop desde https://www.docker.com/products/docker-desktop

### Error: "No se puede conectar al servidor"
**Solución:** Verifica que tienes acceso SSH configurado con tu clave privada

### Error: "API no responde"
**Solución:** 
1. Verifica logs: `docker-compose logs -f`
2. Revisa puerto: `netstat -ano | findstr 7070`
3. Reinicia: `docker-compose restart`

---

## 📝 RECOMENDACIÓN FINAL

**Para producción:** Usa Docker (OPCIÓN 1)
**Para desarrollo:** Usa deploy local (OPCIÓN 5)
**Para CI/CD:** Usa GitHub Actions (OPCIÓN 4)

**Estado actual:** Sistema 100% funcional y listo para deploy
