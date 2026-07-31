# PTES Fase 3 - Threat Modeling

Fecha: 2026-07-30
Sistema: InvenTrack local
Host: conjunta3p.espe.edu.ec
IP: 192.168.49.2

## Activos

| Activo | Valor | Impacto |
|---|---|---|
| Credenciales y roles | Acceso y privilegios | Suplantacion y escalacion |
| JWT | Sesion y rol del usuario | Acceso no autorizado |
| Productos e inventario | Integridad operativa | Fraude, perdida o alteracion |
| Movimientos y auditoria | Trazabilidad | Ocultamiento de acciones |
| Uploads y archivos Excel/CSV | Entrada y contenido servido | XSS, malware o consumo de recursos |
| MySQL y PVC | Persistencia de datos | Exposicion o perdida |
| Endpoint db-test | Diagnostico | Divulgacion de informacion interna |
| Chatbot | Procesamiento de consultas | Fuga de datos o prompt injection |

## Limites de confianza

1. Navegador/Kali hacia Ingress Nginx por HTTP.
2. Ingress hacia frontend y backend mediante Services ClusterIP.
3. Backend hacia MySQL por el Service interno.
4. Backend hacia Groq, excluido de pruebas directas.
5. MySQL y PVC fuera de la superficie HTTP directa.

## Vectores priorizados

| ID | Hipotesis | Precondicion | Prueba controlada |
|---|---|---|---|
| TM-01 | Registro publico permite solicitar rol admin | Endpoint register accesible | Registrar cuenta de laboratorio y validar privilegios |
| TM-02 | Bypass o debilidad de autenticacion | Ruta protegida | Credenciales invalidas, token alterado y expiracion |
| TM-03 | Fallo RBAC o IDOR | Cuenta admin/almacenero | Comparar acceso a productos, usuarios, auditoria y movimientos |
| TM-04 | SQLi en login o filtros | Entrada HTTP | Payloads pequenos y respuestas comparativas |
| TM-05 | Carga insegura de archivos | Cuenta admin y archivo pequeno | Extension, tipo MIME, tamano y ruta servida |
| TM-06 | Rate limit insuficiente detras de Ingress | Endpoint login | Pocos intentos secuenciales y registro de 429 |
| TM-07 | Divulgacion por db-test, errores o CORS | Ruta publica | Solicitud sin credenciales y revision de respuesta |
| TM-08 | Prompt injection o fuga en chatbot | Cuenta autenticada | Marcadores de laboratorio, sin API externa directa |

## Controles existentes a validar

- bcrypt para contrasenas.
- JWT con expiracion.
- Middleware de autenticacion y roles.
- Rate limiting en login.
- Consultas SQL parametrizadas.
- Services ClusterIP y NetworkPolicies.
- Contenedores backend/frontend sin root.
- Secret real fuera de Git.

## Criterio

Las hipotesis anteriores no son hallazgos confirmados. Se probaran en Fases 4 y 5 con bajo volumen, datos demo y evidencias redactadas.
## Base teorica Kubernetes aplicada

Se uso guia-pentest-k8s.md como referencia teorica para identificar:

- Ingress como frontera publica.
- Namespace inventrack-prod como limite logico.
- Services ClusterIP como comunicacion interna.
- NetworkPolicies como control de flujo entre frontend, backend y MySQL.
- Secrets y PVC como activos de confidencialidad y persistencia.
- securityContext no-root como control de ejecucion.
- ServiceAccount, API Server, kubelet y etcd como superficies teoricas de Kubernetes.

## Adaptacion al alcance de esta practica

La prueba activa se limita a la aplicacion accesible por conjunta3p.espe.edu.ec y a sus endpoints HTTP. No se escanearon ni explotaron API Server, kubelet, etcd, Dashboard, ServiceAccount tokens, Secrets internos, red pod a pod, RCE, escape de contenedor, movimiento lateral, MySQL directo ni denegacion de servicio. Estas exclusiones respetan implement.md, P01-01 y el plan operativo.