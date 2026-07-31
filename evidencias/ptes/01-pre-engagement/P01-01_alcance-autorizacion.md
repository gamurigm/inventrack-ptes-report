# PTES Fase 1 - Pre-engagement Interactions

Fecha de autorizacion: 2026-07-30
Propietario del laboratorio: estudiante/equipo
Origen de las pruebas: Kali Linux WSL, usuario ryuzakizeitan

## Alcance autorizado

- Host: conjunta3p.espe.edu.ec
- IP local verificada: 192.168.49.2, correspondiente a Minikube
- Aplicacion: InvenTrack desplegada en el namespace inventrack-prod
- Rutas: /, /login, /api, /uploads y endpoints conocidos de InvenTrack
- Activos: frontend, backend Express, autenticacion JWT, roles, inventario, kardex, auditoria y cargas de archivos

## Objetivos

1. Identificar la superficie expuesta por el Ingress.
2. Validar autenticacion, autorizacion por roles, JWT y rate limiting.
3. Comprobar controles de entradas, SQL parametrizado y cargas pequenas.
4. Evaluar impacto minimo y documentar controles efectivos.
5. Proponer mitigaciones trazables y verificables.

## Reglas de juego

- Pruebas unicamente contra la instancia local de InvenTrack.
- Bajo volumen y concurrencia maxima de 2 solicitudes simultaneas.
- Nuclei limitado a 5 solicitudes por segundo.
- Intruder/Hydra solo secuencial y con pocas credenciales de laboratorio.
- Archivos de prueba pequenos y sin datos reales.
- No se extraen datos completos ni se realizan cambios masivos.
- Los tokens, contrasenas, API keys y hashes se redactan en evidencias.
- Se conserva el estado del laboratorio y se documenta cualquier cambio.

## Fuera de alcance

- Infraestructura real de espe.edu.ec y cualquier otro subdominio.
- Windows host, API de Kubernetes y servicios internos no publicados.
- MySQL directo desde Kali.
- API externa de Groq.
- DoS, cargas ilimitadas, ransomware, persistencia o evasion.
- Borrado masivo, alteracion destructiva o extraccion completa de datos.

## Criterios de parada

- El host resuelve a una IP publica o distinta de 192.168.49.2.
- Se observa degradacion, caida o reinicio inesperado de la aplicacion.
- Existe riesgo de perdida de datos o impacto fuera del namespace de laboratorio.
- Una prueba requiere aumentar volumen o privilegios fuera de lo autorizado.

## Cuentas de laboratorio

- Admin de laboratorio Kubernetes: ptes.k8s.admin@inventrack.local
- Cuenta almacenero: creada antes de las pruebas RBAC
- No se incluyen contrasenas en este documento.

Autorizacion: confirmada por el estudiante para esta practica sobre el entorno local controlado.
## Comandos ejecutados desde Kali

~~~bash
export TARGET_HOST="conjunta3p.espe.edu.ec"
export TARGET_IP="192.168.49.2"
getent ahostsv4 "$TARGET_HOST"
test "$(getent ahostsv4 "$TARGET_HOST" | awk '{print $1}' | sort -u)" = "$TARGET_IP"
curl -sS -i --max-time 10 "http://$TARGET_HOST/api/health"
~~~