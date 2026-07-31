NRC: Desarrollo de Software Seguro

Proyecto Base: InvenTrack (Sistema de gestión de inventario full stack)

Repositorio: [https://github.com/agcudco/conjunta-desarrollo-seguro.git](https://github.com/agcudco/conjunta-desarrollo-seguro.git)

Fecha de Entrega Límite: Viernes 31 de julio a las 23h59

Objetivo
El estudiante debe containerizar la aplicación InvenTrack (Backend, Frontend y Base de Datos), desplegarla en un clúster de Kubernetes exponiéndola mediante Ingress bajo un dominio institucional, y posteriormente ejecutar una auditoría de seguridad aplicando la metodología PTES (Penetration Testing Execution Standard) utilizando Kali Linux. Todo el proceso debe ser respaldado mediante evidencia técnica y repositorios de control de versiones.

Entregables y Requerimientos
Para aprobar la evaluación, se deben cumplir los siguientes 5 entregables:

1. Dockerización de Componentes

Crear los Dockerfile optimizados y seguros para cada componente del sistema:

Backend (Node.js/Express): Debe usar una imagen base ligera (ej. node:alpine), establecer un usuario no root para ejecutar la aplicación y copiar solo los archivos necesarios.
Frontend (React/Vite): Debe usar un multi-stage build (compilación con Node y servir con Nginx).
Base de Datos (MySQL): Configurar el init.sql para que se ejecute automáticamente al levantar el contenedor.
2.     Manifiestos de Kubernetes (Repositorio GitHub)

Crear un repositorio público en GitHub (ej. inventrack-k8s) que contenga exclusivamente los manifiestos de despliegue de Kubernetes (archivos .yml). Debe incluir:

Namespaces: Separación lógica (ej. inventrack-prod).
Deployments y Services: Para backend, frontend y base de datos.
ConfigMaps y Secrets: Para variables de entorno (JWT_SECRET, credenciales de DB, GROQ_API_KEY). Nunca hardcoded.
PersistentVolumeClaim (PVC): Para la persistencia de los datos en MySQL.
Ingress: Configuración para enrutar el tráfico hacia el frontend y backend.
3.     Despliegue en Clúster y Configuración de Ingress

Desplegar los manifiestos en un clúster de Kubernetes (puede ser local con Minikube/Kind o en la nube).
Configurar un controlador Ingress (ej. Nginx Ingress Controller).
Dominio obligatorio: La aplicación debe ser accesible desde el navegador utilizando el dominio: conjunta3p.espe.edu.ec. (Justificar mediante evidencia en el informe cómo se resolvió la resolución DNS o el uso de un archivo hosts para el entorno de prueba).
4.     Auditoría de Seguridad (Pentesting con Kali Linux)

Ejecutar una prueba de penetración sobre la aplicación desplegada utilizando herramientas de Kali Linux, siguiendo estrictamente las Fases Preliminares y de Ejecución de la metodología PTES:

Fase 1: Interacciones Preliminares (Pre-engagement): Definir el alcance, objetivos y reglas de juego (documentado en el informe).
Fase 2: Recopilación de Inteligencia (Intelligence Gathering): Mapeo de la infraestructura de InvenTrack (puertos expuestos, rutas de Ingress, cabeceras HTTP). Uso de Nmap, WhatWeb, etc.
Fase 3: Modelado de Amenazas (Threat Modeling): Identificar activos (API de backend, Base de datos MySQL, Tokens JWT, cargas masivas por Multer).
Fase 4: Análisis de Vulnerabilidades (Vulnerability Analysis): Escaneo automatizado y manual (uso de Nikto, OWASP ZAP o Burp Suite) sobre el dominio conjunta3p.espe.edu.ec.
Fase 5: Explotación (Exploitation): Intento de bypass de autenticación, fuerza bruta (para probar el rate limiting), o inyección SQL en el login o en el chatbot de IA.
5.     Informe Técnico Final

Redactar un documento PDF que incluya:

Enlace al repositorio de GitHub con los manifiestos .yml de Kubernetes.
Evidencia visual (capturas de pantalla) de:
Contenedores corriendo.
Pods, Services e Ingress funcionando en Kubernetes (kubectl get all).
InvenTrack funcionando en el navegador bajo el dominio conjunta3p.espe.edu.ec.
Informe de Pentesting basado en PTES:
Detalle de las fases preliminares ejecutadas.
Herramientas utilizadas de Kali Linux y comandos ejecutados.
Hallazgos de seguridad (Vulnerabilidades encontradas o validaciones de seguridad exitosas, como el correcto funcionamiento del bloqueo por fuerza bruta o el hasheo con bcrypt).
Conclusiones y recomendaciones de mejora para InvenTrack.
Criterios de Evaluación General
La evaluación se enfoca principalmente en la ejecución rigurosa del proceso de pentesting aplicando la metodología PTES sobre la aplicación InvenTrack desplegada. El proceso de pentesting representa el 60% de la calificación final, mientras que el resto se distribuye entre la containerización, despliegue en Kubernetes y el informe técnico.

Rúbrica de Evaluación Detallada

Criterio

Descripción

Puntaje

1. Dockerfiles

Creación correcta y segura de los Dockerfiles para Backend (Node.js/Express), Frontend (React/Vite multi-stage con Nginx) y MySQL. Uso de imágenes base ligeras (alpine), usuarios no root y copia selectiva de archivos.

10%

1. Manifiestos K8s

Archivos YAML correctamente estructurados en repositorio GitHub (Deployments, Services, ConfigMaps, Secrets, PVC). Uso de Secrets para credenciales sensibles (JWT_SECRET, GROQ_API_KEY).

10%

1. Despliegue e Ingress

Despliegue exitoso en el clúster de Kubernetes y enrutamiento funcional bajo el dominio conjunta3p.espe.edu.ec mediante Ingress Controller.

10%

1. Proceso de Pentesting (PTES)

Aplicación rigurosa de las 7 fases de PTES utilizando Kali Linux sobre la aplicación desplegada. Detalle del desglose en la siguiente tabla.

60%

1. Informe Técnico

Calidad del documento, evidencias claras, análisis de resultados PTES, recomendaciones de mejora para InvenTrack y enlace al repositorio de GitHub.

10%

Total

100%

Desglose del 60% — Proceso de Pentesting (PTES)
El proceso de pentesting se evalúa siguiendo estrictamente las 7 fases del Penetration Testing Execution Standard (PTES), ejecutadas con herramientas de Kali Linux sobre la aplicación desplegada en el dominio conjunta3p.espe.edu.ec.

Fase PTES

Descripción del Criterio

Puntaje

Fase 1: Pre-engagement Interactions

Documentación del alcance, objetivos, restricciones, reglas de juego y autorizaciones del pentesting sobre InvenTrack. Definición clara de los activos a probar (API backend, MySQL, JWT, chatbot IA).

5%

Fase 2: Intelligence Gathering

Recopilación de información pasiva y activa sobre el objetivo: mapeo de puertos expuestos (Nmap), rutas de Ingress, cabeceras HTTP, tecnologías detectadas (WhatWeb, Wappalyzer). Identificación de subdominios y servicios.

8%

Fase 3: Threat Modeling

Modelado de amenazas identificando activos críticos, vectores de ataque potenciales y superficies de exposición (API REST, autenticación JWT, carga de archivos con Multer, carga masiva Excel/CSV, chatbot con Groq).

7%

Fase 4: Vulnerability Analysis

Escaneo automatizado y análisis manual de vulnerabilidades usando herramientas de Kali Linux (Nikto, OWASP ZAP, Burp Suite, Nuclei). Detección de fallos en validación de entradas, cabeceras de seguridad, exposición de endpoints.

12%

Fase 5: Exploitation

Intento de explotación de vulnerabilidades encontradas: bypass de autenticación, fuerza bruta contra login (Hydra/Burp Intruder) para validar el rate limiting, inyección SQL en login o chatbot, pruebas de IDOR en endpoints de auditoría/kardex.

15%

Fase 6: Post-Exploitation

Análisis del impacto tras una explotación exitosa: acceso a datos sensibles, escalación de privilegios (admin vs almacenero), extracción de información de la base de datos, persistencia de sesión y validación del hasheo con bcrypt.

8%

Fase 7: Reporting

Elaboración del informe técnico de pentesting con hallazgos clasificados por severidad (CVSS), evidencias (capturas, comandos, payloads), validación de controles de seguridad exitosos y recomendaciones de mitigación específicas para InvenTrack.

5%

Subtotal Pentesting

60%

Consideraciones Clave

El 60% del pentesting exige que todas las 7 fases de PTES estén documentadas con evidencias técnicas (capturas de pantalla, comandos ejecutados y resultados obtenidos).
Las fases de Exploitation (15%) y Vulnerability Analysis (12%) tienen el mayor peso individual, por lo que el estudiante debe demostrar capacidad técnica real para identificar y explotar vulnerabilidades en InvenTrack.
El informe técnico (10%) debe integrar los resultados de las 7 fases PTES, no limitarse a un resumen superficial; debe incluir clasificación de hallazgos por severidad y recomendaciones accionables de mejora para el proyecto InvenTrack.
Los controles de seguridad ya implementados en InvenTrack (rate limiting, bcrypt, JWT, verificación de sesión cada 5s) deben ser validados durante la explotación y documentados como controles efectivos o como controles fallidos según corresponda.
