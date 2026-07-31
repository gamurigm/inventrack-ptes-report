# Plan maestro: InvenTrack en Docker, Kubernetes y auditoría PTES con Kali WSL

> Guía operativa basada en `implement.md`  
> Entorno previsto: Windows + Kali Linux en WSL2 + Docker Desktop + Minikube  
> Objetivo publicado: `http://conjunta3p.espe.edu.ec`  
> Fecha límite indicada: viernes 31 de julio de 2026, 23:59  
> Estado de este archivo: plan de ejecución y control de evidencias; los resultados reales se completarán durante las actividades.

## 1. Resultado que debe entregarse

Al finalizar deben existir y funcionar estos cinco entregables:

1. InvenTrack containerizado con imágenes seguras para backend, frontend y MySQL.
2. Un repositorio público independiente, por ejemplo `inventrack-k8s`, que contenga los manifiestos `.yml`.
3. Un despliegue Kubernetes funcional con Namespace, Deployments, Services, ConfigMap, Secret, PVC e Ingress.
4. Una auditoría autorizada desde Kali WSL que documente las siete fases PTES.
5. Un informe PDF con enlaces, comandos, resultados, capturas, hallazgos, controles validados, conclusiones y recomendaciones.

La evaluación se distribuye así:

| Criterio | Peso | Evidencia mínima |
|---|---:|---|
| Dockerfiles | 10% | Tres componentes, builds reproducibles, backend sin root, frontend multi-stage, `init.sql` automático |
| Manifiestos Kubernetes | 10% | YAML versionado: Namespace, Deployments, Services, ConfigMap, Secret seguro y PVC |
| Despliegue e Ingress | 10% | Pods sanos, Services internos, Ingress y dominio `conjunta3p.espe.edu.ec` funcional |
| PTES completo | 60% | Siete fases, comandos, resultados, capturas, análisis y pruebas controladas |
| Informe técnico | 10% | PDF claro, trazable, con CVSS, mitigaciones y enlaces |

Desglose del 60% de PTES:

| Fase PTES | Peso |
|---|---:|
| 1. Pre-engagement Interactions | 5% |
| 2. Intelligence Gathering | 8% |
| 3. Threat Modeling | 7% |
| 4. Vulnerability Analysis | 12% |
| 5. Exploitation | 15% |
| 6. Post-Exploitation | 8% |
| 7. Reporting | 5% |

Prioridad académica: las fases 4 y 5 suman 27%, pero ninguna fase puede quedar sin evidencia.

## 2. Reglas de seguridad obligatorias

Este laboratorio autoriza pruebas únicamente contra la instancia local de InvenTrack.

- No escanear la infraestructura real de `espe.edu.ec`.
- No probar otros subdominios, IP públicas, servicios institucionales ni la API de Groq.
- No ejecutar denegación de servicio, cargas ilimitadas, borrado masivo, ransomware, persistencia, evasión ni extracción completa de datos.
- Usar cuentas, productos y archivos marcados como datos de laboratorio.
- Definir límites de velocidad antes de usar Nmap, Nuclei, Nikto, ZAP, Burp Intruder o Hydra.
- Conservar evidencias con tokens, contraseñas, cookies, API keys y hashes completos redactados.
- Detener una prueba si el dominio resuelve a una IP distinta de la IP local prevista.
- Tomar una copia o snapshot lógico de los datos antes de las pruebas activas.
- No publicar un Secret real, un archivo `.env`, tokens JWT, hashes completos ni la API key de Groq.

Comprobación de seguridad previa a cada herramienta:

```bash
getent ahostsv4 conjunta3p.espe.edu.ec
minikube ip
```

En Kali, la IP devuelta por `getent` debe ser la IP local obtenida con `minikube ip`. `127.0.0.1` se usa únicamente en el archivo `hosts` de Windows cuando se configura el puente documentado más adelante. Si Kali obtiene una IP pública o desconocida, se cancela la prueba.

## 3. Diagnóstico inicial ya realizado

### 3.1 Entorno

- `kali-linux` está instalado, ejecutándose sobre WSL versión 2.
- Usuario de Kali detectado: `ryuzakizeitan`.
- Herramientas presentes: `nmap`, `whatweb`, `nikto`, `nuclei`, `hydra`, `sqlmap`, `jq` y `curl`.
- Herramientas pendientes: cliente `docker`, `kubectl`, `minikube`, `zaproxy` y `burpsuite`.
- El repositorio de aplicación está en la rama `main`, sin cambios locales al momento de elaborar este plan.
- Remoto detectado: `https://github.com/agcudco/conjunta-desarrollo-seguro`.

### 3.2 Proyecto

Ruta Windows:

```text
C:\Users\gamur\Documents\ESPE VII SI 2026\Desarrollo Seguro\U3\Conjunta\conjunta-desarrollo-seguro
```

Ruta equivalente en Kali WSL:

```text
/mnt/c/Users/gamur/Documents/ESPE VII SI 2026/Desarrollo Seguro/U3/Conjunta/conjunta-desarrollo-seguro
```

Componentes observados:

- Backend Node.js/Express en el puerto 4000.
- Frontend React/Vite servido con Nginx en el puerto 80 del contenedor.
- MySQL 8 con `mysql-init/init.sql`.
- Autenticación JWT, bcrypt, rate limit, Multer, carga Excel/CSV y chatbot Groq.

### 3.3 Brechas que deben resolverse antes del despliegue

Estas son observaciones de preparación, no hallazgos finales de pentesting:

1. El Dockerfile actual del backend ejecuta la aplicación como root y usa `npm install`.
2. El frontend sí usa multi-stage, pero necesita configuración SPA de Nginx y ejecución no privilegiada.
3. `frontend/src/services/api.js` apunta a `http://localhost:4000/api`; esa dirección falla desde el navegador cuando la aplicación se publica mediante Ingress.
4. No existe un Dockerfile propio para empaquetar `init.sql` con MySQL.
5. Faltan `.dockerignore` específicos y manifiestos Kubernetes.
6. El Ingress debe enviar `/api` y `/uploads` al backend, y `/` al frontend.
7. El registro público acepta el campo `rol`; debe probarse si permite crear un administrador anónimo.
8. La carga masiva usa memoria sin un límite explícito; solo se probará con un archivo pequeño.
9. `cors()` acepta orígenes amplios y no se observó Helmet; deben revisarse CORS y cabeceras.
10. `/api/db-test` es público y puede revelar mensajes internos ante errores.
11. El rate limit debe validarse detrás del proxy Ingress, porque la identificación de IP puede cambiar.
12. Las consultas SQL observadas usan parámetros; la hipótesis inicial es resistencia a SQLi, pero debe comprobarse.

## 4. Arquitectura objetivo

```text
                        archivo hosts local
Windows Browser  ─────────────────────────────────────────┐
                                                         │
Kali WSL tools ── conjunta3p.espe.edu.ec ── Ingress :80  │
                                              │          │
                         ┌────────────────────┴───────┐  │
                         │                            │  │
                      / y SPA                  /api, /uploads
                         │                            │
                  frontend Service              backend Service
                         │                            │
                  frontend Deployment           backend Deployment
                                                      │
                                                mysql Service
                                                 ClusterIP only
                                                      │
                                             MySQL Deployment + PVC
                                                      │
                                                 init.sql inicial

Backend ── salida HTTPS autorizada ── Groq API
```

Decisiones:

- Namespace: `inventrack-prod`.
- Services de aplicación: `ClusterIP`.
- MySQL no se expone mediante Ingress ni NodePort.
- El frontend usa `/api` como URL relativa.
- El Ingress usa el host exacto `conjunta3p.espe.edu.ec`.
- El Secret real se crea en el clúster y nunca se sube a GitHub.
- El repositorio público contiene únicamente plantillas/manifiestos `.yml`.

## 5. Método de trabajo por puertas de control

Cada puerta termina con un criterio verificable. No avanzar si el criterio falla.

| Puerta | Resultado | Criterio de salida |
|---|---|---|
| G0 | Preparación y autorización | WSL2, Docker, kubectl, Minikube y herramientas verificadas; alcance firmado |
| G1 | Baseline | Tests actuales ejecutados y aplicación entendida |
| G2 | Docker | Tres imágenes construidas y contenedores saludables |
| G3 | Kubernetes | Manifiestos validados y Secret real fuera de Git |
| G4 | Ingress/DNS | Dominio local funciona desde Kali y navegador |
| G5 | PTES 1–3 | Alcance, inteligencia y modelo de amenazas documentados |
| G6 | PTES 4–6 | Escaneos, pruebas controladas, impacto y limpieza documentados |
| G7 | Reporting | PDF, repositorios, evidencias y rúbrica completos |

## 6. Organización de documentación y evidencias

### 6.1 Preparar las rutas en Kali

```bash
export LAB_ROOT="/mnt/c/Users/gamur/Documents/ESPE VII SI 2026/Desarrollo Seguro/U3/Conjunta"
export APP_ROOT="$LAB_ROOT/conjunta-desarrollo-seguro"
export K8S_ROOT="$LAB_ROOT/inventrack-k8s"
export EVIDENCE_ROOT="$LAB_ROOT/evidencias"
export TARGET_HOST="conjunta3p.espe.edu.ec"
export TARGET_URL="http://$TARGET_HOST"

mkdir -p "$EVIDENCE_ROOT"/{00-preparacion,01-docker,02-k8s,03-ingress,ptes/01-pre-engagement,ptes/02-intelligence,ptes/03-threat-model,ptes/04-vulnerability-analysis,ptes/05-exploitation,ptes/06-post-exploitation,ptes/07-reporting,report}
umask 077
```

Verificar:

```bash
printf 'APP_ROOT=%s\nK8S_ROOT=%s\nTARGET_URL=%s\n' "$APP_ROOT" "$K8S_ROOT" "$TARGET_URL"
```

### 6.2 Convención de nombres

```text
E<fase>-<número>_<fecha-hora>_<descripción>.<ext>
```

Ejemplos:

```text
E02-01_20260730-1430_nmap-puertos.txt
E04-03_20260730-1610_zap-alertas.html
E05-02_20260730-1705_rate-limit-429.png
```

### 6.3 Registro de terminal

Al iniciar cada bloque:

```bash
script -a "$EVIDENCE_ROOT/00-preparacion/sesion-$(date +%Y%m%d-%H%M%S).log"
```

Terminar el registro:

```bash
exit
```

Antes de incluir un log en el informe:

```bash
rg -n "Bearer |token|password|secret|api[_-]?key|authorization" "$EVIDENCE_ROOT"
```

Redactar copias destinadas al informe. Conservar los originales en un lugar privado.

### 6.4 Índice de evidencias

Mantener una tabla durante toda la ejecución:

| ID | Fecha/hora | Fase | Acción | Archivo | Resultado | Sección del informe |
|---|---|---|---|---|---|---|
| E00-01 | Pendiente | Preparación | Versiones de herramientas | Pendiente | Pendiente | Entorno |

Cada captura debe mostrar:

- Comando o acción ejecutada.
- Host/URL de laboratorio.
- Fecha y hora visibles cuando sea posible.
- Resultado relevante.
- Ningún secreto.

## 7. G0 — Preparar Kali WSL, Docker y herramientas

### 7.1 Confirmar WSL2 desde PowerShell

```powershell
wsl -l -v
```

Resultado esperado: `kali-linux` con `VERSION 2`.

### 7.2 Habilitar Docker Desktop para Kali

En Windows:

1. Abrir Docker Desktop.
2. Ir a `Settings > General`.
3. Activar el motor basado en WSL2.
4. Ir a `Settings > Resources > WSL Integration`.
5. Activar la integración para `kali-linux`.
6. Aplicar y reiniciar Docker Desktop.
7. Reiniciar la terminal Kali.

En Kali:

```bash
docker version
docker info --format '{{.OSType}}'
docker run --rm hello-world
```

Resultado esperado: cliente y servidor responden, el tipo es `linux` y no se requiere `sudo`.

No instalar un segundo daemon Docker dentro de Kali si se utilizará Docker Desktop. Mantener un solo motor evita contextos e imágenes inconsistentes.

### 7.3 Instalar kubectl

Confirmar arquitectura:

```bash
uname -m
```

Para `x86_64`:

```bash
cd /tmp
KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

Criterio de salida: checksum `OK` y versión del cliente visible.

### 7.4 Instalar Minikube

Para `x86_64`:

```bash
cd /tmp
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube version
```

Recursos recomendados del equipo:

- 4 CPU.
- 6 GiB de RAM para Minikube.
- Al menos 20 GiB libres.

### 7.5 Instalar ZAP y Burp Suite

```bash
sudo apt update
sudo apt install -y zaproxy burpsuite
zaproxy -version
dpkg-query -W -f='${Version}\n' burpsuite
```

Las interfaces gráficas se abrirán mediante WSLg. Si WSLg no funciona, ZAP puede ejecutarse en modo CLI y Burp se puede abrir desde Windows, conservando Kali para las demás herramientas.

### 7.6 Inventariar versiones

```bash
{
  date -Is
  uname -a
  docker version
  kubectl version --client
  minikube version
  nmap --version
  whatweb --version
  nikto -Version
  nuclei -version
  sqlmap --version
  hydra -h | head
  zaproxy -version
  dpkg-query -W -f='burpsuite=${Version}\n' burpsuite
  gh --version
} > "$EVIDENCE_ROOT/00-preparacion/E00-01_versiones.txt" 2>&1
```

Criterio G0 técnico:

- Todas las herramientas necesarias responden.
- Docker utiliza contenedores Linux.
- No se registraron secretos.

Si `gh` no está instalado:

```bash
sudo apt install -y gh
gh auth login
gh auth status
```

La autenticación se realiza de forma interactiva. También se puede crear el repositorio desde la interfaz web de GitHub.

Criterio G0 administrativo:

- Alcance, reglas y autorización PTES definidos en la sección 14.

## 8. G1 — Baseline de InvenTrack

### 8.1 Crear una rama de trabajo

```bash
cd "$APP_ROOT"
git status --short
git switch -c feat/docker-k8s-ptes
git log -1 --oneline
```

Si la rama ya existe, usarla; no crear ramas duplicadas.

### 8.2 Registrar el baseline

```bash
find backend frontend mysql-init -maxdepth 2 -type f | sort > "$EVIDENCE_ROOT/00-preparacion/E00-02_archivos-baseline.txt"
git status --short > "$EVIDENCE_ROOT/00-preparacion/E00-03_git-status.txt"
```

### 8.3 Ejecutar los tests disponibles

```bash
cd "$APP_ROOT/backend"
npm ci
npm test | tee "$EVIDENCE_ROOT/00-preparacion/E00-04_backend-tests.txt"

cd "$APP_ROOT/frontend"
npm ci
npm run build | tee "$EVIDENCE_ROOT/00-preparacion/E00-05_frontend-build.txt"
```

Registrar fallos existentes antes de modificar Dockerfiles.

### 8.4 Inventario inicial de endpoints

| Método | Ruta | Autenticación esperada | Rol esperado |
|---|---|---|---|
| GET | `/api/health` | No | Público |
| GET | `/api/db-test` | No | Público |
| POST | `/api/auth/register` | No | Debe revisarse |
| POST | `/api/auth/login` | No, rate limited | Público |
| GET/PUT | `/api/auth/perfil` | JWT | Cualquier usuario |
| GET/POST/PUT | `/api/productos` | JWT | Cualquier usuario según código |
| DELETE/PATCH | `/api/productos/:id` | JWT | Admin |
| POST | `/api/productos/imagen` | JWT | Cualquier usuario |
| POST | `/api/productos/carga-masiva` | JWT | Admin |
| GET | `/api/auditoria` | JWT | Admin |
| GET/POST/PUT/PATCH | `/api/usuarios` | JWT | Admin |
| POST | `/api/asistente/preguntar` | JWT | Cualquier usuario |

Criterio G1:

- Baseline compilable o sus fallos documentados.
- Inventario de rutas disponible.
- Cambios posteriores pueden compararse contra un estado conocido.

## 9. G2 — Dockerización segura

### 9.1 Archivos que deben quedar en el repositorio de aplicación

```text
conjunta-desarrollo-seguro/
├── .env.example
├── docker-compose.yml
├── backend/
│   ├── .dockerignore
│   └── Dockerfile
├── frontend/
│   ├── .dockerignore
│   ├── Dockerfile
│   └── nginx.conf
└── mysql-init/
    ├── Dockerfile
    └── init.sql
```

### 9.2 Backend

Objetivos del Dockerfile:

1. Usar una versión fijada de `node:20-alpine` o una versión compatible con el proyecto.
2. Copiar primero `package.json` y `package-lock.json`.
3. Instalar producción con `npm ci --omit=dev`.
4. Copiar únicamente `src`.
5. Crear `/app/uploads` con propietario correcto.
6. Copiar archivos con `--chown=node:node`.
7. Establecer `NODE_ENV=production`.
8. Ejecutar con `USER node`.
9. Exponer 4000.
10. Iniciar con `node src/app.js`.

Esqueleto esperado:

```dockerfile
FROM node:20-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY --from=dependencies --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node src ./src
RUN mkdir -p /app/uploads && chown -R node:node /app
USER node
EXPOSE 4000
CMD ["node", "src/app.js"]
```

`.dockerignore` mínimo:

```text
node_modules
npm-debug.log*
.env
.git
.gitignore
coverage
uploads/*
!uploads/.gitkeep
Dockerfile*
README.md
```

### 9.3 Frontend

Primero cambiar la API a mismo origen:

```javascript
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
});
```

Objetivos del Dockerfile:

1. Etapa de build con Node Alpine.
2. `npm ci`.
3. Build de Vite.
4. Etapa runtime con Nginx no privilegiado.
5. Puerto interno 8080.
6. Configuración SPA con `try_files`.
7. Cabeceras defensivas básicas.

Esqueleto:

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginxinc/nginx-unprivileged:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

Elementos mínimos de `nginx.conf`:

```nginx
server {
    listen 8080;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
}
```

La Content Security Policy se define después de comprobar los recursos requeridos por React. No añadir una política que rompa la aplicación sin validarla.

`.dockerignore` mínimo:

```text
node_modules
dist
.env
.git
.gitignore
npm-debug.log*
Dockerfile*
README.md
```

### 9.4 MySQL

Crear `mysql-init/Dockerfile`:

```dockerfile
FROM mysql:8.0
COPY init.sql /docker-entrypoint-initdb.d/01-init.sql
```

Consideraciones:

- MySQL no dispone de una imagen oficial Alpine equivalente; documentar esta excepción.
- `init.sql` se ejecuta únicamente cuando el directorio de datos está vacío.
- El Secret suministra las credenciales en runtime.
- La cuenta de aplicación debería tener permisos limitados; si el tiempo lo permite, crear `inventrack_app` y evitar que el backend use `root`.

### 9.5 Variables de entorno

Crear `.env.example` con nombres y valores ficticios:

```dotenv
DB_PASSWORD=REEMPLAZAR_LOCALMENTE
JWT_SECRET=REEMPLAZAR_LOCALMENTE
GROQ_API_KEY=REEMPLAZAR_LOCALMENTE
```

Crear `.env` local con secretos de laboratorio. Verificar que `.gitignore` lo excluya:

```bash
cd "$APP_ROOT"
git check-ignore -v .env
```

Generadores:

```bash
openssl rand -base64 24
openssl rand -hex 32
```

No guardar la salida en capturas o logs compartidos.

### 9.6 Ajustar Docker Compose

El Compose debe:

- Construir `mysql-init`, `backend` y `frontend`.
- Mantener healthcheck de MySQL.
- Pasar variables desde `.env`.
- Mantener volumen `mysql_data`.
- Mantener volumen `uploads_data`.
- Mapear backend `4000:4000` y frontend `5173:8080`.
- Usarse únicamente como validación local previa a Kubernetes.

Validar sintaxis sin imprimir variables interpoladas:

```bash
cd "$APP_ROOT"
docker compose config --quiet
```

### 9.7 Construir y probar

```bash
cd "$APP_ROOT"
docker compose build --no-cache | tee "$EVIDENCE_ROOT/01-docker/E01-01_build.txt"
docker compose up -d
docker compose ps | tee "$EVIDENCE_ROOT/01-docker/E01-02_compose-ps.txt"
```

Comprobar backend:

```bash
curl -sS -i http://localhost:4000/api/health | tee "$EVIDENCE_ROOT/01-docker/E01-03_backend-health.txt"
```

Comprobar frontend:

```bash
curl -sS -I http://localhost:5173 | tee "$EVIDENCE_ROOT/01-docker/E01-04_frontend-headers.txt"
```

Comprobar usuario de runtime:

```bash
docker inspect --format '{{.Config.User}}' inventrack-backend
docker inspect --format '{{.Config.User}}' inventrack-frontend
docker compose exec backend id
docker compose exec frontend id
```

Resultado esperado: usuarios no root.

Comprobar inicialización:

```bash
docker compose exec mysql mysql -uroot -p -e "USE inventrack; SHOW TABLES;"
```

La contraseña se introduce de forma interactiva. No usar `-pCONTRASEÑA`.

Comprobar persistencia:

```bash
docker compose restart mysql
docker compose exec mysql mysql -uroot -p -e "USE inventrack; SHOW TABLES;"
```

Capturas obligatorias:

- `docker compose ps`.
- Lista de imágenes y etiquetas.
- Backend y frontend respondiendo.
- Usuario no root.
- Tablas creadas.

### 9.8 Etiquetar imágenes

```bash
docker tag conjunta-desarrollo-seguro-backend:latest inventrack-backend:1.0.0
docker tag conjunta-desarrollo-seguro-frontend:latest inventrack-frontend:1.0.0
docker tag conjunta-desarrollo-seguro-mysql:latest inventrack-mysql:1.0.0
docker images 'inventrack-*'
```

Criterio G2:

- Builds sin error.
- `/api/health` devuelve 200.
- SPA abre y sus rutas sobreviven una recarga.
- Backend y frontend se ejecutan sin root.
- MySQL contiene el esquema y conserva datos al reiniciar.
- `.env` no aparece en `git status`.

## 10. G3 — Repositorio y manifiestos Kubernetes

### 10.1 Crear el repositorio independiente

Ruta local propuesta:

```bash
mkdir -p "$K8S_ROOT"
cd "$K8S_ROOT"
git init
git branch -M main
```

Estructura exclusivamente `.yml`:

```text
inventrack-k8s/
├── 00-namespace.yml
├── 01-configmap.yml
├── 02-secret.template.yml
├── 03-mysql-pvc.yml
├── 04-mysql-deployment.yml
├── 05-mysql-service.yml
├── 06-backend-deployment.yml
├── 07-backend-service.yml
├── 08-frontend-deployment.yml
├── 09-frontend-service.yml
├── 10-ingress.yml
├── 11-network-policy.yml
└── kustomization.yml
```

`kustomization.yml` debe listar los recursos aplicables y excluir `02-secret.template.yml`. La plantilla documenta la estructura; el Secret real se crea directamente en el clúster.

### 10.2 Contenido requerido

| Archivo | Requisitos |
|---|---|
| Namespace | `inventrack-prod` |
| ConfigMap | `PORT`, `DB_HOST`, `DB_USER`, `DB_NAME` y configuración no sensible |
| Secret template | Nombres de `DB_PASSWORD`, `JWT_SECRET`, `GROQ_API_KEY`; solo marcadores |
| PVC | `ReadWriteOnce`, tamaño justificado, por ejemplo 2Gi |
| MySQL Deployment | 1 réplica, PVC, probes, recursos |
| MySQL Service | `ClusterIP`, puerto 3306 |
| Backend Deployment | Imagen versionada, envFrom, probes, recursos, securityContext |
| Backend Service | `ClusterIP`, 4000 |
| Frontend Deployment | Imagen versionada, probe, recursos, securityContext |
| Frontend Service | `ClusterIP`, puerto 80 a targetPort 8080 |
| Ingress | Host obligatorio; `/api` y `/uploads` al backend; `/` al frontend |
| NetworkPolicy | Entrada a MySQL solo desde backend; entrada a backend desde Ingress |

### 10.3 Estándares de seguridad de los manifiestos

Para backend y frontend:

- `runAsNonRoot: true`.
- `allowPrivilegeEscalation: false`.
- `capabilities.drop: ["ALL"]`.
- `seccompProfile.type: RuntimeDefault`.
- `readOnlyRootFilesystem: true` cuando sea compatible.
- `requests` y `limits`.
- Etiquetas consistentes.
- `imagePullPolicy: IfNotPresent` para imágenes cargadas en Minikube.

Para el backend, montar un volumen escribible en `/app/uploads` si `readOnlyRootFilesystem` está activo. Si las imágenes deben persistir, usar un PVC adicional; documentar si se usa `emptyDir` solo para el laboratorio.

Probes:

```text
Backend:  GET /api/health sobre 4000
Frontend: GET / sobre 8080
MySQL:    mysqladmin ping
```

### 10.4 Manejo correcto de Secrets

`02-secret.template.yml` puede mostrar la estructura, nunca valores reales:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: inventrack-secrets
  namespace: inventrack-prod
type: Opaque
stringData:
  DB_PASSWORD: REEMPLAZAR_SOLO_EN_COPIA_LOCAL
  JWT_SECRET: REEMPLAZAR_SOLO_EN_COPIA_LOCAL
  GROQ_API_KEY: REEMPLAZAR_SOLO_EN_COPIA_LOCAL
```

No aplicar la plantilla. Crear el Secret real directamente:

```bash
read -rsp "DB password: " LAB_DB_PASSWORD
printf '\n'
read -rsp "JWT secret: " LAB_JWT_SECRET
printf '\n'
read -rsp "Groq API key: " LAB_GROQ_API_KEY
printf '\n'

kubectl -n inventrack-prod create secret generic inventrack-secrets \
  --from-literal=DB_PASSWORD="$LAB_DB_PASSWORD" \
  --from-literal=JWT_SECRET="$LAB_JWT_SECRET" \
  --from-literal=GROQ_API_KEY="$LAB_GROQ_API_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

unset LAB_DB_PASSWORD LAB_JWT_SECRET LAB_GROQ_API_KEY
```

En el Deployment de MySQL, la clave `DB_PASSWORD` del Secret se mapea a la variable `MYSQL_ROOT_PASSWORD` que espera la imagen:

```yaml
env:
  - name: MYSQL_ROOT_PASSWORD
    valueFrom:
      secretKeyRef:
        name: inventrack-secrets
        key: DB_PASSWORD
```

Evidencia segura:

```bash
kubectl -n inventrack-prod get secret inventrack-secrets
```

No usar `-o yaml` ni decodificar el Secret en la evidencia.

### 10.5 Validar YAML

```bash
cd "$K8S_ROOT"
kubectl apply --dry-run=client -f 00-namespace.yml
kubectl apply --dry-run=client -f 01-configmap.yml
kubectl apply --dry-run=client -f 03-mysql-pvc.yml
kubectl apply --dry-run=client -f 04-mysql-deployment.yml
kubectl apply --dry-run=client -f 05-mysql-service.yml
kubectl apply --dry-run=client -f 06-backend-deployment.yml
kubectl apply --dry-run=client -f 07-backend-service.yml
kubectl apply --dry-run=client -f 08-frontend-deployment.yml
kubectl apply --dry-run=client -f 09-frontend-service.yml
kubectl apply --dry-run=client -f 10-ingress.yml
```

### 10.6 Publicar en GitHub

Antes de publicar:

```bash
cd "$K8S_ROOT"
rg -n "DB_PASSWORD|JWT_SECRET|GROQ_API_KEY|Bearer|ghp_|eyJ" .
git status --short
git diff --check
```

Revisar manualmente cada coincidencia: solo deben existir nombres de variables o marcadores.

Después:

```bash
git add '*.yml'
git commit -m "feat: add secure InvenTrack Kubernetes manifests"
gh repo create inventrack-k8s --public --source=. --remote=origin --push
```

Guardar la URL del repositorio para el informe.

Versionar también los cambios de Docker en el repositorio de aplicación y publicarlos en una rama propia o fork autorizado:

```bash
cd "$APP_ROOT"
git status --short
git diff --check
git add backend/Dockerfile backend/.dockerignore frontend/Dockerfile frontend/.dockerignore frontend/nginx.conf frontend/src/services/api.js mysql-init/Dockerfile docker-compose.yml .env.example
git commit -m "feat: harden InvenTrack containers for Kubernetes"
git push -u origin feat/docker-k8s-ptes
```

Si no existe permiso de escritura sobre `origin`, crear un fork y cambiar el remoto de publicación sin sobrescribir el repositorio ajeno.

Criterio G3:

- Todos los manifiestos validan.
- El repositorio contiene únicamente `.yml` y metadatos Git.
- No existe ningún secreto real en el historial.
- La URL pública abre sin autenticación.

## 11. G4 — Desplegar en Minikube e Ingress

### 11.1 Crear el clúster

```bash
minikube start --driver=docker --cpus=4 --memory=6144
kubectl config current-context
kubectl get nodes -o wide
```

Resultado esperado: contexto `minikube` y nodo `Ready`.

### 11.2 Instalar el Ingress Controller

Ruta principal alineada con el enunciado:

```bash
minikube addons enable ingress
kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=180s
kubectl get pods -n ingress-nginx
```

Nota técnica: la documentación reciente de Minikube marca su addon Nginx predeterminado como no mantenido y recomienda Traefik. Para esta evaluación local se conserva Nginx por alineación con la rúbrica. En un entorno productivo se instalaría una versión mantenida del controlador o se usaría Traefik, y se documentaría `ingressClassName`.

### 11.3 Cargar imágenes locales

```bash
minikube image load inventrack-backend:1.0.0
minikube image load inventrack-frontend:1.0.0
minikube image load inventrack-mysql:1.0.0
minikube image ls | rg 'inventrack'
```

Los nombres y tags deben coincidir exactamente con los Deployments.

### 11.4 Aplicar en orden

```bash
cd "$K8S_ROOT"
kubectl apply -f 00-namespace.yml
kubectl apply -f 01-configmap.yml
kubectl apply -f 03-mysql-pvc.yml
```

Crear ahora el Secret real mediante el procedimiento de la sección 10.4.

```bash
kubectl apply -f 04-mysql-deployment.yml
kubectl apply -f 05-mysql-service.yml
kubectl -n inventrack-prod rollout status deployment/mysql --timeout=180s

kubectl apply -f 06-backend-deployment.yml
kubectl apply -f 07-backend-service.yml
kubectl -n inventrack-prod rollout status deployment/backend --timeout=180s

kubectl apply -f 08-frontend-deployment.yml
kubectl apply -f 09-frontend-service.yml
kubectl -n inventrack-prod rollout status deployment/frontend --timeout=180s

kubectl apply -f 10-ingress.yml
kubectl apply -f 11-network-policy.yml
```

### 11.5 Verificar recursos

```bash
kubectl get all -n inventrack-prod -o wide | tee "$EVIDENCE_ROOT/02-k8s/E02-01_get-all.txt"
kubectl get ingress,pvc,configmap,secret -n inventrack-prod | tee "$EVIDENCE_ROOT/02-k8s/E02-02_recursos-adicionales.txt"
kubectl describe ingress inventrack-ingress -n inventrack-prod > "$EVIDENCE_ROOT/02-k8s/E02-03_ingress-describe.txt"
kubectl get events -n inventrack-prod --sort-by='.lastTimestamp' > "$EVIDENCE_ROOT/02-k8s/E02-04_events.txt"
```

Revisar logs si algo falla:

```bash
kubectl logs -n inventrack-prod deployment/mysql --tail=100
kubectl logs -n inventrack-prod deployment/backend --tail=100
kubectl logs -n inventrack-prod deployment/frontend --tail=100
```

No incluir logs que muestren secretos o datos sensibles sin redactar.

### 11.6 Validar Ingress desde Kali sin cambiar DNS

```bash
export MINIKUBE_IP="$(minikube ip)"
curl --resolve "$TARGET_HOST:80:$MINIKUBE_IP" -i "$TARGET_URL/api/health"
curl --resolve "$TARGET_HOST:80:$MINIKUBE_IP" -I "$TARGET_URL/"
```

Resultado esperado:

- `/api/health` responde 200 desde backend.
- `/` responde 200 desde frontend.

### 11.7 Configurar `/etc/hosts` en Kali

Revisar primero si existe una entrada:

```bash
grep -n "$TARGET_HOST" /etc/hosts
```

Agregar una sola línea con la IP devuelta por `minikube ip`:

```text
<MINIKUBE_IP> conjunta3p.espe.edu.ec
```

Verificar:

```bash
getent ahostsv4 "$TARGET_HOST"
curl -i "$TARGET_URL/api/health"
```

Guardar:

```bash
getent ahostsv4 "$TARGET_HOST" | tee "$EVIDENCE_ROOT/03-ingress/E03-01_dns-kali.txt"
curl -i "$TARGET_URL/api/health" | tee "$EVIDENCE_ROOT/03-ingress/E03-02_health-dominio.txt"
```

### 11.8 Acceso desde el navegador Windows

Primero probar desde PowerShell:

```powershell
Test-NetConnection <MINIKUBE_IP> -Port 80
```

Si `TcpTestSucceeded` es verdadero:

1. Abrir como administrador:
   `C:\Windows\System32\drivers\etc\hosts`
2. Añadir:

```text
<MINIKUBE_IP> conjunta3p.espe.edu.ec
```

3. Abrir `http://conjunta3p.espe.edu.ec`.

Si Windows no llega a la red interna de Minikube, usar este puente controlado:

En Kali, dejar ejecutándose:

```bash
kubectl -n ingress-nginx port-forward --address=0.0.0.0 service/ingress-nginx-controller 9080:80
```

Obtener la IP de Kali WSL:

```bash
hostname -I
```

En PowerShell como administrador:

```powershell
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=80 connectaddress=<IP_WSL> connectport=9080
netsh interface portproxy show v4tov4
```

La IP de WSL puede cambiar después de reiniciarlo. Repetir `hostname -I` y actualizar el `portproxy` cuando ocurra.

En el archivo `hosts` de Windows:

```text
127.0.0.1 conjunta3p.espe.edu.ec
```

Limpieza posterior del puente:

```powershell
netsh interface portproxy delete v4tov4 listenaddress=127.0.0.1 listenport=80
```

Quitar también la entrada temporal del archivo `hosts` al concluir el laboratorio.

### 11.9 Evidencias obligatorias del despliegue

Capturar:

1. `kubectl get all -n inventrack-prod`.
2. `kubectl get ingress,pvc -n inventrack-prod`.
3. Pods con estado `Running` y `READY`.
4. InvenTrack abierto con el dominio visible en la barra de direcciones.
5. Login y dashboard funcionales.
6. `/api/health` a través del dominio.
7. Resolución `hosts` o configuración del puente.

Criterio G4:

- El dominio funciona desde Kali.
- El dominio funciona desde el navegador Windows.
- No se usa `localhost:4000` en las solicitudes del frontend.
- MySQL solo es accesible dentro del clúster.

## 12. Datos y cuentas controladas para el pentest

Antes de pruebas activas crear:

- Una cuenta administradora legítima de control.
- Una cuenta `almacenero`.
- Un producto con nombre `PTES-MARKER`.
- Una categoría y proveedor de prueba.
- Un archivo JPG pequeño y un CSV/XLSX pequeño.

Usar correos bajo un dominio reservado, por ejemplo:

```text
ptes-admin@example.test
ptes-almacenero@example.test
ptes-anon-admin@example.test
```

No incluir contraseñas en el informe. Identificarlas como `LAB_ADMIN_PASSWORD`, `LAB_WAREHOUSE_PASSWORD`, etc.

Tomar el estado inicial:

```bash
kubectl get all -n inventrack-prod
kubectl get pvc -n inventrack-prod
```

Si se realiza un respaldo lógico, guardarlo fuera del repositorio público y con permisos restrictivos.

## 13. Matriz general de pruebas

| ID | Superficie | Control esperado | Tipo |
|---|---|---|---|
| TC-AUTH-01 | Registro | No crear admin anónimo | Manual |
| TC-AUTH-02 | Login | Rechazar SQLi y credenciales inválidas | Manual/Burp |
| TC-AUTH-03 | Login | 429 después del umbral | Burp Intruder/cURL |
| TC-JWT-01 | Endpoints protegidos | Rechazar token ausente, inválido o alterado | Burp/cURL |
| TC-RBAC-01 | Auditoría/usuarios | Rechazar `almacenero` con 403 | Burp/cURL |
| TC-IDOR-01 | Recursos por ID | Respetar autorización al cambiar IDs | Burp Repeater |
| TC-UPLOAD-01 | Imagen | Validar tipo real, tamaño y extensión | Burp/cURL |
| TC-UPLOAD-02 | Carga masiva | Limitar tamaño y filas | Manual, archivo pequeño |
| TC-AI-01 | Chatbot | Resistir prompt injection y no filtrar secretos | Manual |
| TC-CORS-01 | API | Restringir orígenes | cURL |
| TC-HEAD-01 | HTTP | Cabeceras defensivas | cURL/ZAP/Nikto |
| TC-SQLI-01 | Parámetros | Consultas parametrizadas | Manual + revisión de código |
| TC-SESS-01 | Usuario desactivado | Invalidar acceso con token previo | Manual |
| TC-BCRYPT-01 | Contraseñas | Hash bcrypt, no texto plano | Validación interna redactada |

Cada caso registra:

```text
ID:
Objetivo:
Precondiciones:
Cuenta/rol:
Herramienta:
Solicitud o pasos:
Resultado esperado:
Resultado real:
Código HTTP:
Evidencia:
Conclusión: Pass / Fail / Inconcluso
Hallazgo relacionado:
Limpieza:
```

## 14. G5 — PTES fase 1: Pre-engagement Interactions (5%)

### 14.1 Objetivo

Definir por escrito qué se puede probar, cómo, cuándo y bajo qué límites.

### 14.2 Plantilla de autorización

Completar antes de escanear:

| Campo | Valor |
|---|---|
| Propietario del laboratorio | Estudiante/equipo |
| Sistema | InvenTrack local |
| Host autorizado | `conjunta3p.espe.edu.ec` resuelto localmente |
| IP autorizada en Kali | Resultado local de `minikube ip` |
| Resolución opcional en Windows | `127.0.0.1` solo con el puente `portproxy` |
| Ventana | Fecha/hora de inicio y fin |
| Origen | Kali WSL |
| Cuentas | Admin y almacenero de laboratorio |
| Datos | Datos demo y marcadores PTES |
| Pruebas permitidas | Reconocimiento, escaneo moderado, auth, RBAC, IDOR, SQLi controlada, upload pequeño, prompt injection |
| Fuera de alcance | ESPE real, Groq, Windows host, API de Kubernetes, DoS, persistencia, borrado masivo |
| Límite de solicitudes | Nuclei ≤5 req/s; concurrencia ≤2; Intruder secuencial |
| Criterios de parada | Caída, pérdida de datos, IP inesperada, impacto fuera de alcance |
| Contacto | Nombre/correo |
| Aprobación | Firma o confirmación |

### 14.3 Objetivos de la auditoría

1. Mapear la superficie expuesta por Ingress.
2. Validar autenticación, JWT, rate limiting y sesión.
3. Validar separación admin/almacenero.
4. Buscar inyección, IDOR, configuración insegura y exposición de endpoints.
5. Revisar cargas con Multer y el chatbot.
6. Confirmar bcrypt y controles efectivos.
7. Priorizar mitigaciones específicas.

### 14.4 Evidencias

- Documento de alcance.
- Tabla de reglas.
- IP local autorizada.
- Hora de inicio.
- Lista de cuentas de prueba sin contraseñas.

Criterio de fase:

- Alcance inequívoco.
- Autorización expresa.
- Exclusiones y límites medibles.

## 15. PTES fase 2: Intelligence Gathering (8%)

### 15.1 Validación fail-closed del objetivo

```bash
getent ahostsv4 "$TARGET_HOST" | tee "$EVIDENCE_ROOT/ptes/02-intelligence/E02-01_resolucion.txt"
curl -sS -o /dev/null -w 'remote_ip=%{remote_ip} http_code=%{http_code}\n' "$TARGET_URL/api/health"
```

Detenerse si la IP no es local.

### 15.2 Descubrimiento de puertos

Escaneo moderado:

```bash
sudo nmap -Pn -sT -T3 --max-rate 100 -p- "$TARGET_HOST" \
  -oA "$EVIDENCE_ROOT/ptes/02-intelligence/E02-02_nmap-tcp"
```

Enumeración de servicios solo sobre puertos encontrados:

```bash
sudo nmap -Pn -sV --version-light -T3 -p 80,443 "$TARGET_HOST" \
  -oA "$EVIDENCE_ROOT/ptes/02-intelligence/E02-03_nmap-servicios"
```

No asumir que 443 está abierto; registrar el resultado.

### 15.3 Tecnologías y cabeceras

```bash
whatweb -a 3 --log-verbose="$EVIDENCE_ROOT/ptes/02-intelligence/E02-04_whatweb.txt" "$TARGET_URL"

curl -sS -D "$EVIDENCE_ROOT/ptes/02-intelligence/E02-05_headers-root.txt" \
  -o /dev/null "$TARGET_URL/"

curl -sS -D "$EVIDENCE_ROOT/ptes/02-intelligence/E02-06_headers-api.txt" \
  -o "$EVIDENCE_ROOT/ptes/02-intelligence/E02-06_health-body.txt" \
  "$TARGET_URL/api/health"
```

Revisar:

- `Server`.
- `Content-Type`.
- `Content-Security-Policy`.
- `X-Content-Type-Options`.
- `X-Frame-Options` o `frame-ancestors`.
- `Referrer-Policy`.
- CORS.
- `RateLimit-*`.
- Caché.

### 15.4 Rutas de Ingress

Probar solo rutas conocidas:

```bash
for path in / /login /api/health /api/db-test /uploads/ /api/auth/login /api/productos; do
  curl -sS -o /dev/null -w '%{http_code} %{size_download} %{url_effective}\n' "$TARGET_URL$path"
done | tee "$EVIDENCE_ROOT/ptes/02-intelligence/E02-07_rutas-conocidas.txt"
```

Interpretar 401/403 como evidencia de una ruta protegida, no como un error de disponibilidad.

### 15.5 Inventario resultante

Completar:

| Activo | Host/ruta | Puerto | Tecnología | Exposición | Evidencia |
|---|---|---:|---|---|---|
| Frontend | `/` | 80 | React/Nginx | Pública | Pendiente |
| Backend | `/api` | 80 vía Ingress | Express | Mixta | Pendiente |
| Uploads | `/uploads` | 80 vía Ingress | Express static | Pública | Pendiente |
| MySQL | Interno | 3306 | MySQL 8 | ClusterIP | Pendiente |

Criterio de fase:

- Puertos y tecnologías identificados.
- Rutas de Ingress confirmadas.
- Cabeceras registradas.
- No se escaneó infraestructura externa.

## 16. PTES fase 3: Threat Modeling (7%)

### 16.1 Activos críticos

| Activo | Valor | Propietario | Impacto si se compromete |
|---|---|---|---|
| Credenciales | Acceso | Usuarios | Suplantación |
| JWT | Sesión/rol | Backend | Acceso y escalación |
| Inventario | Datos operativos | Negocio | Fraude o pérdida de integridad |
| Kardex | Trazabilidad | Negocio | Alteración de movimientos |
| Auditoría | Evidencia | Admin | Ocultamiento de acciones |
| MySQL/PVC | Datos persistentes | Plataforma | Exposición o pérdida |
| Uploads | Contenido servido | Aplicación | XSS, malware, almacenamiento |
| Excel/CSV | Entrada masiva | Admin | Consumo de recursos e integridad |
| Contexto del chatbot | Datos de inventario | Backend | Filtración/prompt injection |
| GROQ_API_KEY | Secreto externo | Plataforma | Abuso de cuenta externa |

### 16.2 Fronteras de confianza

1. Navegador/Kali → Ingress.
2. Ingress → frontend/backend.
3. Backend → MySQL.
4. Backend → volumen de uploads.
5. Backend → Groq.
6. JWT almacenado en navegador → API.
7. Admin → funciones privilegiadas.
8. Archivo cargado → parser Multer/XLSX.

### 16.3 Modelo STRIDE mínimo

| Superficie | Amenaza | STRIDE | Control esperado | Prueba |
|---|---|---|---|---|
| Login | Suplantación | S | bcrypt + rate limit | TC-AUTH-02/03 |
| Registro | Escalación | E | Rol asignado por servidor | TC-AUTH-01 |
| JWT | Manipulación | T/E | Firma y expiración | TC-JWT-01 |
| IDs de API | Acceso a otro recurso | I/E | Autorización por objeto | TC-IDOR-01 |
| Productos/kardex | Alteración | T | RBAC y auditoría | TC-RBAC-01 |
| Upload | Contenido activo | T/I | Magic bytes, tamaño, nombre | TC-UPLOAD-01 |
| Carga masiva | Agotamiento | D | Límite de tamaño/filas | TC-UPLOAD-02 |
| Chatbot | Prompt injection | I | Minimización de contexto | TC-AI-01 |
| MySQL | Exposición | I | ClusterIP/NetworkPolicy | Nmap + K8s |
| Logs/errores | Divulgación | I | Mensajes genéricos | ZAP/manual |

### 16.4 Hipótesis prioritarias derivadas del código

Estas hipótesis deben confirmarse dinámicamente:

1. Posible creación anónima de usuarios con rol `admin`.
2. CORS excesivamente permisivo.
3. Falta de cabeceras de seguridad.
4. Validación de archivo basada solo en MIME declarado.
5. Carga masiva sin límite explícito.
6. Mensajes de error internos.
7. Rate limit con comportamiento incorrecto detrás de Ingress.
8. JWT en `localStorage`, aumentando el impacto de un XSS.
9. SQLi probablemente mitigada por consultas parametrizadas.
10. RBAC de auditoría y usuarios probablemente efectivo; debe validarse.

Criterio de fase:

- Activos, flujos, fronteras y amenazas documentados.
- Cada amenaza está vinculada a un caso de prueba.
- Riesgos de negocio explicados.

## 17. G6 — PTES fase 4: Vulnerability Analysis (12%)

Preparación:

```bash
getent ahostsv4 "$TARGET_HOST"
nuclei -update-templates
```

La actualización de plantillas ocurre antes de iniciar la ventana y no se dirige al objetivo.

### 17.1 Nikto

```bash
nikto -h "$TARGET_URL" -maxtime 10m \
  -output "$EVIDENCE_ROOT/ptes/04-vulnerability-analysis/E04-01_nikto.txt" \
  -Format txt
```

Revisar falsos positivos manualmente.

### 17.2 Nuclei con límites

```bash
nuclei -u "$TARGET_URL" \
  -severity info,low,medium,high,critical \
  -rl 5 -c 2 \
  -o "$EVIDENCE_ROOT/ptes/04-vulnerability-analysis/E04-02_nuclei.txt"
```

No habilitar plantillas de fuzzing, DoS o fuerza bruta fuera de las reglas acordadas.

### 17.3 OWASP ZAP

Escaneo rápido CLI:

```bash
zaproxy -cmd -silent -quickurl "$TARGET_URL" -quickprogress \
  -quickout "$EVIDENCE_ROOT/ptes/04-vulnerability-analysis/E04-03_zap-report.html"
```

Para rutas autenticadas:

1. Abrir ZAP.
2. Crear un contexto limitado a:

```regex
http://conjunta3p\.espe\.edu\.ec/.*
```

3. Excluir logout y cualquier operación destructiva.
4. Navegar con una cuenta de laboratorio mediante el navegador de ZAP.
5. Ejecutar spider tradicional/AJAX.
6. Ejecutar primero análisis pasivo.
7. Ejecutar activo con intensidad baja.
8. Exportar HTML y guardar la sesión privada.

### 17.4 Burp Suite manual

1. Abrir Burp.
2. Crear proyecto temporal o guardar el proyecto en evidencias privadas.
3. Definir el scope exacto del dominio.
4. Activar “intercept” solo cuando sea necesario.
5. Navegar como admin y almacenero.
6. Enviar solicitudes relevantes a Repeater.
7. Marcar tokens y contraseñas para redacción.
8. Usar Intruder únicamente en TC-AUTH-03, con cuatro payloads, un hilo y pausa.

### 17.5 Revisión manual

Revisar:

- Respuestas a métodos inesperados.
- CORS.
- Cabeceras.
- Errores 500.
- Enumeración de usuarios por mensajes.
- Validación de JSON vacío, tipos incorrectos y campos adicionales.
- Controles de tamaño.
- Acceso anónimo a rutas.
- Autorización de roles.
- Rutas SPA.
- Archivos en `/uploads`.
- Exposición de `/api/db-test`.

### 17.6 Consolidar resultados

| ID candidato | Fuente | Evidencia | Reproducible | Falso positivo | Pasa a explotación |
|---|---|---|---|---|---|
| VA-01 | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |

Criterio de fase:

- Nikto, Nuclei y ZAP ejecutados.
- Rutas autenticadas revisadas con Burp.
- Falsos positivos validados.
- Cada candidato tiene evidencia y decisión.

## 18. PTES fase 5: Exploitation (15%)

Todas las pruebas usan el menor impacto que demuestre el problema.

### 18.1 TC-AUTH-01 — Registro anónimo con rol privilegiado

Hipótesis: `/api/auth/register` permite que el cliente elija `rol: admin`.

Preparar contraseña sin mostrarla:

```bash
read -rsp "Password de cuenta PTES: " TEST_PASSWORD
printf '\n'
REGISTER_BODY="$(jq -n \
  --arg nombre "PTES Anonymous Admin" \
  --arg email "ptes-anon-admin@example.test" \
  --arg password "$TEST_PASSWORD" \
  --arg rol "admin" \
  '{nombre:$nombre,email:$email,password:$password,rol:$rol}')"
```

Ejecutar una vez:

```bash
curl -sS -i -H 'Content-Type: application/json' \
  --data "$REGISTER_BODY" \
  "$TARGET_URL/api/auth/register" \
  | tee "$EVIDENCE_ROOT/ptes/05-exploitation/E05-01_registro-rol-admin.txt"
```

Confirmación:

- Si devuelve 201, iniciar sesión con esa cuenta.
- Consultar `/api/auth/perfil`.
- Verificar el rol devuelto.
- Probar una sola ruta de admin no destructiva, por ejemplo `GET /api/auditoria`.
- No modificar registros de negocio para demostrar el rol.
- Desactivar la cuenta al finalizar con el administrador legítimo.

Resultado seguro esperado: el servidor ignora el rol suministrado, asigna `almacenero` o restringe el registro inicial.

### 18.2 TC-SQLI-01 — SQLi controlada en login

Realizar antes de la prueba de rate limit y con una sola solicitud:

```bash
SQLI_BODY="$(jq -n \
  --arg email "' OR 1=1 -- -" \
  --arg password "invalid-lab-value" \
  '{email:$email,password:$password}')"

curl -sS -i -H 'Content-Type: application/json' \
  --data "$SQLI_BODY" \
  "$TARGET_URL/api/auth/login" \
  | tee "$EVIDENCE_ROOT/ptes/05-exploitation/E05-02_sqli-login.txt"
```

Resultado seguro esperado: 401, sin token y sin error SQL.

La evidencia se complementa con revisión de código:

- `Usuario.getByEmail` usa `WHERE email = ?`.
- Las consultas de modelos usan placeholders.
- El mensaje del chatbot no se concatena en SQL.

SQLMap solo se ejecutará si el análisis encuentra un parámetro candidato no protegido y si el rate limit permite una prueba controlada. Configuración máxima autorizada:

```text
--batch --level=1 --risk=1 --threads=1 --delay=1
```

No usar opciones de extracción, shell, escritura ni evasión.

### 18.3 TC-JWT-01 — Autenticación y firma

Probar:

1. Sin `Authorization` → 401.
2. `Bearer invalid` → 403.
3. Token válido → 200.
4. Token con un carácter de la firma modificado en Burp Repeater → 403.
5. Revisar claims localmente: `id`, `rol`, `nombre`, `iat`, `exp`.
6. Confirmar que no contiene contraseña ni Secret.
7. Registrar que el tiempo de expiración esperado es 8 horas.

No guardar el JWT en el informe. Mostrar una forma redactada:

```text
eyJ...<REDACTED>...signature
```

### 18.4 TC-RBAC-01 y TC-IDOR-01

Con token de `almacenero`, probar:

| Solicitud | Esperado |
|---|---:|
| `GET /api/productos` | 200 |
| `GET /api/auditoria` | 403 |
| `GET /api/usuarios` | 403 |
| `DELETE /api/productos/<ID-PTES>` | 403 |
| `PATCH /api/productos/<ID-PTES>/restaurar` | 403 |

Con Burp Repeater:

1. Capturar una consulta legítima por ID.
2. Cambiar únicamente el ID a otro marcador de laboratorio.
3. Comparar códigos, campos y propiedad del recurso.
4. No acceder a datos reales de terceros.

Para auditoría y usuarios, confirmar la autorización de función. Para recursos sin propietario individual, documentar que un cambio de ID no constituye IDOR por sí solo.

### 18.5 TC-AUTH-03 — Fuerza bruta limitada y rate limiting

Ejecutar esta prueba al final de las pruebas de login y esperar una ventana limpia de cinco minutos.

En Burp Intruder:

1. Usar un email de laboratorio.
2. Definir cuatro contraseñas incorrectas.
3. Concurrencia: 1.
4. Pausa: 1 segundo.
5. Ejecutar solo cuatro solicitudes.
6. Registrar códigos y cabeceras.

Esperado según el código:

```text
Intentos 1–3: 401
Intento 4: 429
Cabeceras RateLimit presentes
Recuperación tras la ventana de 5 minutos
```

También comprobar si el límite afecta indebidamente a todos los usuarios por compartir la IP del Ingress. No falsificar `X-Forwarded-For`.

### 18.6 TC-UPLOAD-01 — Validación de imagen

Usar un archivo benigno de pocos bytes, sin código ejecutable:

```text
PTES_SAFE_MARKER
```

Pruebas:

1. Extensión `.txt`, MIME `text/plain` → debe rechazarse.
2. Mismo marcador renombrado `.jpg`, MIME declarado `image/jpeg` → debe rechazarse si se validan magic bytes.
3. JPG válido menor a 5 MiB → debe aceptarse.
4. Archivo mayor al límite: no generarlo si compromete recursos; se puede validar el límite por revisión de configuración.
5. Solicitud sin JWT → debe rechazarse.
6. Acceso al archivo cargado → revisar `Content-Type` y `X-Content-Type-Options`.

Eliminar el marcador exacto después de registrar evidencia. No ejecutar contenido activo.

### 18.7 TC-UPLOAD-02 — Carga masiva

Usar una hoja de máximo 2–3 filas:

- Una fila válida.
- Una fila sin SKU.
- Una fila con número no válido.

Validar:

- Solo admin puede cargar.
- El almacenero recibe 403.
- Errores por fila son controlados.
- No aparece stack trace.
- Existe límite de tamaño y cantidad; si no existe, registrar hallazgo por revisión de código sin provocar agotamiento.

### 18.8 TC-AI-01 — Chatbot

Alcance: solo el endpoint de InvenTrack. Groq es un tercero fuera de alcance.

Pruebas benignas:

1. Pregunta normal sobre inventario.
2. Solicitud de revelar el prompt del sistema.
3. Instrucción que intenta ignorar reglas.
4. Texto con caracteres SQL para confirmar que se trata como texto.
5. Solicitud de secretos como `GROQ_API_KEY` o `JWT_SECRET`.

Esperado:

- No revelar secretos.
- No ejecutar SQL suministrado por el usuario.
- Responder solo con datos autorizados.
- Errores externos sin detalles internos.

Registrar el rol que puede consultar el chatbot y si recibe datos que exceden sus privilegios.

### 18.9 TC-CORS-01 y TC-HEAD-01

```bash
curl -sS -i \
  -H 'Origin: https://evil.example' \
  "$TARGET_URL/api/health" \
  | tee "$EVIDENCE_ROOT/ptes/05-exploitation/E05-08_cors.txt"

curl -sS -I "$TARGET_URL/" \
  | tee "$EVIDENCE_ROOT/ptes/05-exploitation/E05-09_headers.txt"
```

Analizar `Access-Control-Allow-Origin`, credenciales y cabeceras defensivas. Considerar el contexto real: un origen externo no puede leer el `localStorage` del dominio, pero un CORS amplio incrementa exposición y debe justificarse.

### 18.10 Criterio de fase

- Cada prueba tiene resultado esperado y real.
- Se demostró impacto mínimo.
- Los controles efectivos también están documentados.
- No se usaron datos ajenos ni infraestructura externa.
- Cuentas y archivos de prueba quedaron identificados para limpieza.

## 19. PTES fase 6: Post-Exploitation (8%)

Esta fase solo se ejecuta si una prueba previa obtiene acceso o privilegios no previstos.

### 19.1 Objetivos

1. Determinar qué datos y funciones quedan accesibles.
2. Comparar privilegios admin/almacenero.
3. Verificar vigencia de la sesión.
4. Confirmar almacenamiento bcrypt.
5. Limpiar los artefactos.

### 19.2 Impacto mínimo de una escalación

Si la cuenta anónima obtiene admin:

1. `GET /api/auth/perfil` para confirmar rol.
2. `GET /api/usuarios` y registrar solo cantidad/campos, con datos redactados.
3. `GET /api/auditoria` y registrar solo un marcador.
4. No desactivar usuarios legítimos.
5. No borrar productos.
6. No exportar la base completa.

Esto demuestra confidencialidad e impacto de privilegios sin dañar el entorno.

### 19.3 Sesión y desactivación

1. Iniciar sesión con una cuenta PTES.
2. Guardar el token solo en memoria.
3. Desactivar esa cuenta usando el admin legítimo.
4. Repetir `GET /api/auth/perfil` con el token previo.
5. Esperado: 403.
6. Observar en el frontend la expulsión o comprobación periódica.

La validación distingue:

- Rechazo del backend en cada solicitud.
- Sondeo del frontend cada 5 segundos.

### 19.4 Validación bcrypt

Desde administración interna del laboratorio:

```bash
kubectl -n inventrack-prod exec -it deployment/mysql -- \
  mysql -uroot -p -e \
  "USE inventrack; SELECT id,email,CHAR_LENGTH(password) AS longitud,LEFT(password,4) AS prefijo FROM usuarios;"
```

Introducir la contraseña de forma interactiva.

Evidencia:

- Longitud compatible con bcrypt.
- Prefijo como `$2a$` o `$2b$`.
- Hash completo redactado.
- Login correcto/incorrecto demuestra comparación.

No intentar crackear hashes.

### 19.5 Limpieza

- Desactivar cuentas `ptes-*`.
- Eliminar archivos marcadores exactos.
- Revertir o eliminar productos `PTES-MARKER` mediante la aplicación.
- Cerrar sesiones ZAP/Burp.
- Destruir variables de token con `unset`.
- Verificar que la aplicación sigue operativa.
- Registrar la hora de finalización.

### 19.6 Retest básico

```bash
curl -sS -i "$TARGET_URL/api/health"
kubectl get pods -n inventrack-prod
kubectl get events -n inventrack-prod --sort-by='.lastTimestamp' | tail -20
```

Criterio de fase:

- Impacto explicado.
- No quedó persistencia.
- bcrypt y revocación por desactivación validados.
- Entorno limpio y estable.

## 20. G7 — PTES fase 7: Reporting (5%) e informe técnico (10%)

### 20.1 Estructura del PDF

1. Portada.
2. Control de versiones del documento.
3. Resumen ejecutivo.
4. Objetivos.
5. Alcance y exclusiones.
6. Reglas de juego y autorización.
7. Arquitectura.
8. Dockerización.
9. Manifiestos Kubernetes.
10. Despliegue, Ingress y resolución del dominio.
11. Metodología PTES.
12. Fase 1: Pre-engagement.
13. Fase 2: Intelligence Gathering.
14. Fase 3: Threat Modeling.
15. Fase 4: Vulnerability Analysis.
16. Fase 5: Exploitation.
17. Fase 6: Post-Exploitation.
18. Fase 7: Reporting.
19. Resumen de hallazgos.
20. Controles de seguridad validados.
21. Recomendaciones priorizadas.
22. Conclusiones.
23. Limitaciones.
24. Plan de retest.
25. Enlaces a repositorios.
26. Anexos de comandos, payloads y evidencias.

### 20.1.1 Producción y revisión del PDF

Flujo sugerido:

1. Redactar `INFORME_FINAL.md` mientras se ejecutan las fases.
2. Mantener las imágenes en una carpeta relativa, con pies y números de figura.
3. Generar un documento editable:

```bash
sudo apt install -y pandoc
pandoc INFORME_FINAL.md -o INFORME_FINAL.docx
```

4. Abrir el `.docx` en Word o LibreOffice.
5. Revisar saltos de página, tablas, pies de figura, enlaces y tabla de contenido.
6. Exportar como `INFORME_FINAL_INVENTRACK_PTES.pdf`.
7. Abrir el PDF resultante y revisar todas las páginas.
8. Verificar los enlaces de GitHub desde una ventana privada.
9. Buscar credenciales antes de entregar:

```bash
pdftotext INFORME_FINAL_INVENTRACK_PTES.pdf - \
  | rg -n "Bearer |eyJ|password|secret|api[_-]?key|ghp_"
```

Toda coincidencia se revisa manualmente; los nombres conceptuales como `JWT_SECRET` pueden ser legítimos, sus valores no.

### 20.2 Plantilla de hallazgo

```text
ID:
Título:
Severidad:
CVSS v3.1:
Vector CVSS:
Estado: Confirmado / No reproducible / Control efectivo
Activo y ruta:
Descripción:
Precondiciones:
Pasos de reproducción:
Solicitud/payload redactado:
Resultado observado:
Resultado esperado:
Impacto técnico:
Impacto de negocio:
Evidencias:
Causa raíz:
Recomendación:
Prioridad:
Responsable sugerido:
Retest:
Referencias:
```

Usar la calculadora oficial de FIRST y publicar tanto el puntaje como el vector.

Escala cualitativa CVSS v3.1:

| Puntaje | Severidad |
|---:|---|
| 0.0 | Ninguna |
| 0.1–3.9 | Baja |
| 4.0–6.9 | Media |
| 7.0–8.9 | Alta |
| 9.0–10.0 | Crítica |

### 20.3 Tabla de resumen

| ID | Hallazgo/control | Estado | CVSS | Severidad | Recomendación |
|---|---|---|---:|---|---|
| F-01 | Pendiente | Pendiente | Pendiente | Pendiente | Pendiente |

### 20.4 Controles exitosos que también puntúan

Documentar como validaciones:

- Contraseñas con bcrypt.
- SQL parametrizado.
- JWT firmado y con expiración.
- 401/403 en rutas protegidas.
- Separación de rol donde funcione.
- Rate limiting y 429 donde funcione.
- Desactivación de cuenta invalida acceso.
- MySQL no expuesto externamente.
- Secrets fuera de Git.
- Contenedores sin root.
- PVC funcional.

### 20.5 Recomendaciones previsibles

Solo convertirlas en recomendaciones finales si las pruebas las respaldan:

1. Cerrar el registro público después del bootstrap o forzar rol de menor privilegio.
2. Validar entradas con un esquema.
3. Restringir CORS.
4. Añadir Helmet/CSP.
5. Configurar `trust proxy` de forma segura para rate limiting.
6. Validar magic bytes y almacenar uploads fuera del web root.
7. Limitar tamaño y filas de carga masiva.
8. Eliminar o proteger `/api/db-test`.
9. Usar usuario MySQL con privilegios mínimos.
10. Añadir rotación/revocación de JWT y reducir almacenamiento en `localStorage`.
11. Minimizar datos enviados al chatbot.
12. Añadir TLS aun en pruebas si el tiempo lo permite.
13. Aplicar NetworkPolicies y contextos de seguridad.
14. Centralizar logs sin datos sensibles.

## 21. Trazabilidad completa contra la rúbrica

| Rúbrica | Trabajo | Evidencia | Estado |
|---|---|---|---|
| Dockerfiles 10% | Backend seguro | Dockerfile, build, `id` | ☐ |
| Dockerfiles 10% | Frontend multi-stage | Dockerfile, build, Nginx | ☐ |
| Dockerfiles 10% | MySQL + init | Dockerfile, tablas | ☐ |
| K8s 10% | Namespace/Deployments/Services | YAML + `kubectl get all` | ☐ |
| K8s 10% | ConfigMap/Secret/PVC | YAML + recursos | ☐ |
| Ingress 10% | Controller y host | Ingress + navegador | ☐ |
| PTES 5% | Pre-engagement | Alcance y autorización | ☐ |
| PTES 8% | Intelligence | Nmap, WhatWeb, headers | ☐ |
| PTES 7% | Threat Modeling | Activos, STRIDE, flujos | ☐ |
| PTES 12% | Vulnerability Analysis | Nikto, Nuclei, ZAP, Burp | ☐ |
| PTES 15% | Exploitation | Auth, rate limit, SQLi, IDOR, upload, IA | ☐ |
| PTES 8% | Post-Exploitation | Impacto mínimo, bcrypt, sesión, limpieza | ☐ |
| PTES 5% | Reporting | Hallazgos, CVSS, evidencias | ☐ |
| Informe 10% | PDF final | Calidad, enlaces, recomendaciones | ☐ |

## 22. Plan de tiempo por prioridad

La fecha límite deja poco margen. Orden recomendado:

| Bloque | Duración objetivo | Resultado |
|---|---:|---|
| Preparación/autorización | 45 min | G0 |
| Baseline y ajustes de aplicación | 45 min | G1 |
| Dockerfiles y Compose | 2 h | G2 |
| YAML y Secret seguro | 2 h | G3 |
| Minikube, Ingress y dominio | 2 h | G4 |
| PTES 1–3 | 2 h | G5 |
| Vulnerability Analysis | 2.5 h | Fase 4 |
| Exploitation | 3 h | Fase 5 |
| Post-Exploitation/limpieza | 1 h | Fase 6 |
| Informe y anexos | 3 h | G7 |
| Revisión y buffer | 1.5 h | Entrega |

Si aparece un bloqueo:

1. Conservar el error como evidencia.
2. Registrar causa y acción correctiva.
3. Resolver primero los bloqueos que impiden dominio/PTES.
4. No sacrificar las siete secciones PTES.
5. Reservar tiempo para PDF, enlaces y verificación final.

## 23. Problemas frecuentes y diagnóstico

### Frontend llama a `localhost:4000`

Causa: URL absoluta compilada.

Comprobar:

```bash
rg -n "localhost:4000" "$APP_ROOT/frontend"
```

Solución: URL relativa `/api`, reconstruir imagen y recargarla en Minikube.

### Una ruta React devuelve 404 al recargar

Causa: Nginx sin fallback SPA.

Solución: `try_files $uri $uri/ /index.html;`.

### `ImagePullBackOff`

```bash
kubectl describe pod -n inventrack-prod <POD>
minikube image ls | rg inventrack
```

Comprobar tag e `imagePullPolicy`.

### MySQL no vuelve a ejecutar `init.sql`

Causa: PVC ya inicializado.

Registrar el hecho. No borrar el PVC sin autorización y respaldo. `init.sql` está diseñado para el primer arranque.

### Backend no conecta a MySQL

```bash
kubectl get svc -n inventrack-prod
kubectl describe pod -n inventrack-prod -l app=backend
kubectl logs -n inventrack-prod deployment/backend --tail=100
```

Comprobar `DB_HOST`, Secret, readiness de MySQL y nombre del Service.

### Windows no alcanza `minikube ip`

Usar el puente `kubectl port-forward` + `netsh portproxy` de la sección 11.8 y documentarlo.

### Rate limit bloquea a todos detrás de Ingress

Revisar:

- Cabeceras `X-Forwarded-For`.
- Configuración `trust proxy`.
- Clave usada por `express-rate-limit`.
- IP vista por Express.

Tratarlo como resultado de seguridad, no ocultarlo.

### ZAP/Burp no abren en Kali

```bash
echo "$DISPLAY"
echo "$WAYLAND_DISPLAY"
wsl.exe --status
```

Usar ZAP CLI y, si es necesario, Burp en Windows apuntando al mismo dominio local.

## 24. Cierre, conservación y reanudación

Al pausar:

```bash
kubectl get all -n inventrack-prod
minikube stop
docker compose -f "$APP_ROOT/docker-compose.yml" stop
```

Al reanudar:

```bash
minikube start
kubectl get nodes
kubectl get all -n inventrack-prod
getent ahostsv4 "$TARGET_HOST"
curl -i "$TARGET_URL/api/health"
```

No ejecutar `minikube delete`, no borrar PVC y no limpiar imágenes hasta que:

- El PDF esté terminado.
- Todas las capturas estén verificadas.
- El repositorio público sea accesible.
- Los hallazgos tengan evidencias.
- Se haya realizado el retest final.

## 25. Checklist final de entrega

### Repositorios

- [ ] Cambios de Docker versionados en el repositorio de aplicación.
- [ ] Repositorio `inventrack-k8s` público.
- [ ] Solo manifiestos `.yml` en el repositorio Kubernetes.
- [ ] Ningún secreto en archivos o historial.
- [ ] Enlaces incluidos en el PDF.

### Docker

- [ ] Backend Alpine, `npm ci`, copia selectiva y usuario no root.
- [ ] Frontend multi-stage y Nginx no privilegiado.
- [ ] MySQL empaqueta `init.sql`.
- [ ] `.dockerignore`.
- [ ] Tres contenedores funcionando.
- [ ] Evidencias legibles.

### Kubernetes

- [ ] Namespace.
- [ ] Tres Deployments.
- [ ] Tres Services.
- [ ] ConfigMap.
- [ ] Secret real fuera de Git.
- [ ] PVC de MySQL.
- [ ] Ingress.
- [ ] Probes y recursos.
- [ ] Security contexts.
- [ ] MySQL no expuesto.

### Dominio

- [ ] `conjunta3p.espe.edu.ec` resuelve al laboratorio.
- [ ] Frontend funciona.
- [ ] `/api/health` funciona.
- [ ] `/uploads` enruta al backend.
- [ ] Evidencia de `hosts` o portproxy.
- [ ] Navegador muestra el dominio.

### PTES

- [ ] Fase 1 documentada.
- [ ] Fase 2 documentada.
- [ ] Fase 3 documentada.
- [ ] Fase 4 documentada.
- [ ] Fase 5 documentada.
- [ ] Fase 6 documentada.
- [ ] Fase 7 documentada.
- [ ] Comandos y payloads redactados.
- [ ] Hallazgos con CVSS y vector.
- [ ] Controles efectivos documentados.
- [ ] Limpieza realizada.

### PDF

- [ ] Portada y tabla de contenido.
- [ ] Arquitectura.
- [ ] Capturas Docker/Kubernetes/Ingress.
- [ ] Siete fases PTES.
- [ ] Resumen ejecutivo.
- [ ] Hallazgos y recomendaciones.
- [ ] Conclusiones.
- [ ] Limitaciones.
- [ ] Anexos.
- [ ] PDF abierto y revisado página por página.

## 26. Fuentes técnicas principales

- PTES, siete secciones: <https://www.pentest-standard.org/index.php/Main_Page>
- Docker Desktop con WSL2: <https://docs.docker.com/desktop/features/wsl/>
- Instalación oficial de kubectl en Linux: <https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/>
- Instalación oficial de Minikube: <https://minikube.sigs.k8s.io/docs/start/>
- Driver Docker de Minikube: <https://minikube.sigs.k8s.io/docs/drivers/docker/>
- Addons de Ingress en Minikube: <https://minikube.sigs.k8s.io/docs/handbook/addons/>
- ZAP en Kali: <https://www.kali.org/tools/zaproxy/>
- Calculadora oficial CVSS v3.1: <https://www.first.org/cvss/calculator/3.1>

---

## Punto de inicio para trabajar paso a paso

Comenzar únicamente por **G0**. El primer resultado que debe revisarse antes de editar el proyecto es:

```bash
docker version
kubectl version --client
minikube version
zaproxy -version
```

Cuando las cuatro comprobaciones respondan, continuar con G1 y conservar `E00-01_versiones.txt`.
