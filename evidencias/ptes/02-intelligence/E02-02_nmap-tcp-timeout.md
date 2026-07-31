# Nota de trazabilidad sobre E02-02 - Nmap TCP completo

Se realizo un primer intento con limite operativo de 180 segundos. Ese intento no
completo los 65535 puertos y no se aumento la velocidad ni la concurrencia.

Posteriormente se repitio el mismo barrido moderado desde Kali, sin el limite
externo de 180 segundos, sobre el unico host local autorizado:

```bash
nmap -Pn -sT -T3 --max-rate 100 -p- conjunta3p.espe.edu.ec -oA E02-02_nmap-tcp
```

La segunda ejecucion finalizo en 655.48 segundos. Los archivos
`E02-02_nmap-tcp.nmap`, `.gnmap` y `.xml` corresponden a esa ejecucion completa,
como demuestran las marcas de inicio y fin de Nmap. El escaneo encontro los
puertos 22, 80, 443, 2376, 2379, 2380, 8443, 10010, 10249, 10250, 10256, 31358,
31454 y 33337. Solo 80/tcp y 443/tcp se enumeraron como servicios web de la
aplicacion. Los puertos de nodo y plano de control se registraron como superficie
de la topologia local, pero no se enumeraron ni explotaron porque permanecen
fuera del alcance autorizado.
