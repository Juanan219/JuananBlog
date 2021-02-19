---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-19
linktitle: Proxys y balanceadores
type:
- post
- posts
title: Apuntes de Proxy, Proxy Inverso y Balanceador de carga
weight: 10
series:
- Hugo 101
images:
tags:
  - Apuntes
  - Squid
  - Servidores
  - Proxy
  - Inverso
  - Balanceador
  - HTTP
  - HTTPS
  - Cache
  - DansGuardian
  - Sarg
---

## Proxy/Caché

* **Proxy:** Proporcionaconexión a internet cuando no tenemos enrutadores / NAT. Por lo tanto gestiona la comunicación HTTP y la podemos filtrar.

* **Caché:** Guarda ficheros de internet para que las futuras búsquedas de esos ficheros en la red no sea necesario volver a descargarlos de internet, sino descargarlosn directamente desde el proxy.

### Herramientas

* **DansGuardian:** es un software de filtro de contenido, diseñado para controlar el acceso a sitios web.

* **Sarg (Squid Analysis Report Generator):** es una herramienta que permite a los administradores de sistemas ver de una manera sencilla y amigable qué sitios de Internet visitan los usuarios de la red local usando los logs de Squid.

## Proxy inverso

* Un proxy inverso es un tipo de servidor proxy que recupera los recursos en nombre de un cliente desde uno o más servidores. Por lo tanto el cliente hace la petición al puerto 80 del proxy y éste es el que hace la petición al servidor web que normalmente está en una red interna no accesible desde el cliente.

* Un proxy inverso también  puede teer funciones de **caché** cuando es capaz de guardar informaiṕon de los servidores internos y ofrecerla en las próximas peticiones.

* Teienen proxy inverso `apache2`, `nginx`, `varnish`, `traefikck`, etc...

## Balanceador de varga

* Un **Balanceador de carga** fundamentalmente es un dispositivo de hardware o software que se pone al frente de un conjunto de servidores que atienden a una aplicación y tal como su nombre lo indica, asigna o balancea las solicitudes que llegan de los clientes a los servidores usando algún algoritmo.
