# BORRADOR - Ampliacion de alcance para segmentacion y movimiento lateral

> Estado: NO AUTORIZADO. Este archivo es una propuesta y no habilita pruebas.
> Debe completarse y aprobarse expresamente antes de ejecutar cualquier caso.

## Motivo

Evaluar el radio de impacto bajo un escenario de brecha asumida dentro del
namespace local `inventrack-prod`, sin afirmar que el acceso al pod fue obtenido
mediante la vulnerabilidad F-01. El acceso por `kubectl exec` se documentaria como
simulacion administrativa de compromiso, no como explotacion real.

## Alcance propuesto

- Entorno: Minikube local en WSL Ubuntu.
- Namespace: `inventrack-prod`.
- Workloads: frontend, backend y MySQL del laboratorio.
- Origen de observacion externa: Kali WSL contra el dominio local validado.
- Datos: cuentas y marcadores PTES; ningun dato real.
- Ventana autorizada: PENDIENTE.
- Responsable y aprobador: PENDIENTE.

## Pruebas propuestas de bajo impacto

| ID | Origen simulado | Destino | Accion | Resultado esperado |
|---|---|---|---|---|
| ML-01 | frontend | backend:4000 | Conexion TCP/HTTP unica | Permitida por la politica actual |
| ML-02 | frontend | mysql:3306 | Conexion TCP unica, sin login | Bloqueada |
| ML-03 | pod temporal sin etiquetas | backend/frontend/mysql | Una conexion por puerto | Bloqueada |
| ML-04 | backend | mysql:3306 | Conexion TCP y `SELECT CURRENT_USER()` redactado | Permitida; confirmar usuario efectivo |
| ML-05 | backend | otros destinos internos | Matriz minima de conectividad | Bloqueada salvo destinos autorizados |

## Evidencia requerida

- Manifiesto exacto del pod temporal, sin privilegios ni montajes del host.
- Comando, origen, destino, fecha y resultado de cada conexion.
- Sin tokens, contrasenas, Secret values, hashes completos ni volcados.
- Estado de pods y health antes y despues.
- Eliminacion del pod temporal y variables de sesion.

## Fuera de alcance incluso con esta propuesta

- API Server, kubelet, etcd, Docker daemon y Dashboard.
- Lectura o reutilizacion de ServiceAccount tokens.
- Lectura o decodificacion de Secrets de Kubernetes.
- RCE, escape de contenedor, hostPath, modo privilegiado o capacidades elevadas.
- Persistencia, exfiltracion, DoS, fuerza bruta o escaneo masivo.
- Infraestructura real de ESPE y API externa de Groq.

## Criterio metodologico

Una conexion permitida o bloqueada valida segmentacion. Solo existe movimiento
lateral explotado si un punto de apoyo obtenido por una vulnerabilidad permite
alcanzar otro activo sin usar privilegios administrativos externos. Si el punto
de entrada es `kubectl exec`, el resultado debe llamarse `simulacion de brecha
asumida` y no `movimiento lateral explotado`.

## Aprobacion

- Aprobado por: PENDIENTE
- Fecha y hora: PENDIENTE
- Confirmacion expresa de ejecucion: PENDIENTE
