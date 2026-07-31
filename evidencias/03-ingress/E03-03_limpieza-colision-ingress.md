# E03-03 - Limpieza de colision de Ingress

**Fecha:** 2026-07-30  
**Entorno:** Minikube local en WSL Ubuntu  
**Alcance:** Solo el cluster de laboratorio

## Contexto

Antes de publicar InvenTrack, el cluster contenia el namespace murillo-lopez y el Ingress cavalocal, usando el mismo host y rutas que la practica. La admision del nuevo Ingress produjo una colision de host.

La inspeccion de solo lectura confirmo que murillo-lopez correspondia exclusivamente al despliegue anterior de Cavalocal y sus recursos asociados. La eliminacion fue autorizada expresamente para esta practica.

## Acciones

Comandos ejecutados:

    kubectl get ingress -A
    kubectl get all,pvc,secret,configmap -n murillo-lopez
    kubectl delete namespace murillo-lopez --wait=true --timeout=180s
    kubectl get namespace murillo-lopez
    kubectl get ingress -A

## Resultado

- El namespace murillo-lopez fue eliminado correctamente.
- Sus recursos asociados dejaron de formar parte del cluster de laboratorio.
- La colision de host desaparecio.
- El Ingress inventrack-ingress pudo aplicarse en inventrack-prod.
- No se incluyen valores de Secret, contrasenas, tokens ni datos sensibles.

## Criterio de seguridad

La accion se limito al namespace antiguo identificado durante la inspeccion previa. No se eliminaron namespaces, workloads ni recursos ajenos a la practica.