# InvenTrack - Informe PTES en LaTeX

Repositorio del informe técnico final de la práctica de Desarrollo Seguro:
Docker, Kubernetes con Minikube, Ingress y siete fases PTES.

Autor: Gabriel Murillo  
Institución: Universidad de las Fuerzas Armadas ESPE  
Periodo: ESPE VII SI 2026

## Estructura

- `main.tex`: documento principal.
- `preambulo.tex`: estilos, tipografía, colores y bloques `tcolorbox`.
- `secciones/`: capítulos incorporados mediante `\input`.
- `anexos/`: mapa completo de evidencias y repositorios.
- `evidencias/`: salidas técnicas, análisis y capturas.
- `scripts/`: conversión del informe y generación del mapa.
- `output/pdf/`: PDF final compilado.

## Compilación

```powershell
powershell -ExecutionPolicy Bypass -File .\build.ps1
```

El PDF queda en:

`output/pdf/INFORME_FINAL_INVENTRACK_PTES.pdf`

## Repositorios relacionados

- Kubernetes: <https://github.com/gamurigm/inventrack-k8s>
- Aplicación original: <https://github.com/agcudco/conjunta-desarrollo-seguro>
- Informe y evidencias: <https://github.com/gamurigm/inventrack-ptes-report>
