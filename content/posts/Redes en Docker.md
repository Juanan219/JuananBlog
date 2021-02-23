---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-23
linktitle: Redes en Docker
type:
- post
- posts
title: Redes en Docker
weight: 10
series:
- Hugo 101
images:
tags:
  - Docker
  - DockerHub
  - Ejercicios
  - Apuntes
  - Documentacion
  - Redes
  - Wordpress
  - MySQL
  - MariaDB
  - Joomla
  - PHP
  - CMS
---

## Introducción a las redes en Docker

Cada vez que creamos un contenedor en Docker, éste se conecta a una red virtual y docker hace una configuración del sistema (usando interfaces puente e iptables para que la máquina tenga una ip interna, tenga acceso al exterior, podamos mapear puertos (DNAT), etc...)

Podemos ver el comando ip si ejecutamos un contenedor con este comando.
~~~
docker run -it --rm --name docker_debian debian bash -c 'ip a'
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
56: eth0@if57: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
~~~

> **Nota:** Si usamos la opción `--rm` el contenedor se elimina nada más que termina de hacer el proceso que se le ha encargado.

Como podemos ver arriba, a nuestro contenedor se le ha asignado la ip `172.17.0.2/16` y se ha creado una interfaz tipo `bridge` en la máquina anfitriona, a la cual se conectan los contenedores.
~~~
ip a
[...]
6: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:65:cd:e3:5c brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:65ff:fecd:e35c/64 scope link 
       valid_lft forever preferred_lft forever
[...]
~~~

Además de que se han generado ciertas reglas en el cortafuegos para gestionar las conexiones de los contenedores. Podemos ejecutar `iptables -nL` e `iptables -t nat -nL` para comprobar estas reglas.

## Tipos de redes en Docker

Cuando instalamos docker tenemos las siguientes redes predefinidas:
~~~
docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
09540af8449f        bridge              bridge              local
2e4b519fab3b        host                host                local
0ac9f5f0f96b        none                null                local
~~~

* Si creamos cualquier contenedor, por defecto se va a conectar a la red llamada `bridge`, cuyo direccionamiento predeterminado es 172.17.0.0/16. Los contenedores conectados a esta red que quieren exponer algún puerto al exterior tienen que usar el parámetro `-p` para mapear puertos.

Este tipo de red nos permite:

	* Aislar los contenedores que tengo en distintas subredes docker, de tal manera de que los contenedores de esa subred puedan acceder exclusivamente a contenedores de su misma subred.

	* Aislar los contenedores del acceso exterior.

	* Publicar servicios que tengamos en los contenedores mediante redirecciones que docker implementará con las reglas iptables necesarias.

![Captura 13](/Docker/Documentacion/13.png)

* Si conectamos un contenedor a la red **host**, el contenedor estaría en la misma red que nuestra máquina anfitriona, por lo que cogerá direccionamiento IP de nuestro DHCP, además de que los puertos son accesibles directamente desde el host. Si queremos conectar un contenedor que vamos a crear a una red en concreto, deberemos hacer:
~~~
docker run --name docker_nginx --network host -d nginx
720ea83dafd587b86799717b5a9fe072245526aa85ca60ec910b7656decc769d

docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
b1f6a0f81813        nginx               "/docker-entrypoint.…"   7 seconds ago       Up 6 seconds                            docker_nginx
~~~

Ahora podremos acceder a la página de `nginx` directamente desde el puerto 80

![Captura 14](/Docker/Documentacion/14.png)

* La red **none** no configurará ninguna IP para el contenedor y no tiene acceso a ningún tipo de red ni equipos. Tiene una dirección `loopback` y se suele usar para ejecutar trabajos por lotes.

## Gestionando las redes en Docker

Tenemos que hacer una diferenciación entre dos tipos de redes **bridged**:

* La red creada por defecto por Docker para que funcionen todos los contenedores.

* Y las redes `bridged` definidas por el usuario.

Las redes `bridged` que usan por defecto los contenedores se diferencian en varios aspectos de las redes `bridged` creadas por nosotros. Estos aspectos son los siguientes:

* Las redes que definimos proporcionan **resolución DNS** entre los contenedores, cosa que no hace la red por defecto a no ser que usemos opciones que ya se consideran `deprecated` (como la opción `--link`).

* Puedo conectar en caliente los contenedores a redes `bridged` definidas por nosotros, mientras que si uso la red por defecto, tengo que parar previamente el contenedor.

* Me permite gestionar de manera más segura el aislamiento de los contenedores, ya que si no indico una red, al crear el contenedor, éste se conecta a la red por defecto, en la cual puede haber otros contenedores con servicios que no tienen nada que ver con él.

* Tengo más control sobre las redes si las defino yo, ya que los contenedores de una red por defecto comparten todos la misma configuración de red (MTU, reglas iptables, etc...)

* Los contenedores de la red por defecto comparten ciertas variables de entorno, por lo que pueden generar algunos conflictos.

Por todo esto, es muy importante que los contenedores que tenemos en producción se estén ejecutando en redes definidas por nosotros.

Para gestionar las redes definidas por el usuario:

* **`docker network ls`:** Lista las redes.

* **`docker network create`:** Crea redes, por ejemplo
~~~
docker network create red1

docker netwprk create -d bridge --subnet 172.24.0.0/16 --gateway 172.24.0.1 red2
~~~

* **`docker network prune`:** Elimina las redes que no se están usando

* **`docker network rm`:** Elimina la red o redes que le indiquemos, teniendo en cuenta siempre que no podemos eliminar una red mientras se está usando, por lo que deberemos eliminar o desconectar de dicha red el contenedor que la está usando.

* **`docker network inspect`:** Nos da información sobre la red

Cada red que creamos crea un puente de red específico para que podamos ver cada red definida con el comando `ip a` desde la máquina anfitriona.

![Captura 15](/Docker/Documentacion/15.png)

## Asociación de redes a los contenedores

Tenemos dos redes creadas por el usuario
~~~
docker network create --subnet 172.28.0.0/16 --gateway 172.28.0.1 red1
8ea35d168034d65ea8acc8b51af61467db3ef172efd1cb7130617903c27b61b1

docker network create red2
692f9cc348f7486e26f63f49f8184f94743160ebd88da65bed057f0508e5ce97

docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
[...]
8ea35d168034        red1                bridge              local
692f9cc348f7        red2                bridge              local
~~~

Vamos a crear dos contenedores conectados a la `red1`, el primer contenedor va a tener ls imagen `nginx` y el segundo va a tener la imagen `debian`, desde la cual vamos a realizar un dig hacia el servidor web nginx
~~~
docker run --name docker_nginx --network red1 -d nginx
4decc4259730743ca45883fe2540bddc9289211fe37dd011143b8899094ce7b1

docker run -it --name docker_debian --network red1 debian bash

root@d701cdcce43d:/# apt-get update

root@d701cdcce43d:/# apt-get install dnsutils

root@d701cdcce43d:/# dig docker_nginx

; <<>> DiG 9.11.5-P4-5.1+deb10u3-Debian <<>> docker_nginx
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 64571
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;docker_nginx.      IN  A

;; ANSWER SECTION:
docker_nginx.   600 IN  A 172.28.0.2

;; Query time: 0 msec
;; SERVER: 127.0.0.11#53(127.0.0.11)
;; WHEN: Tue Feb 23 13:10:26 UTC 2021
;; MSG SIZE  rcvd: 58
~~~

* **`docker network connect`:** Conectar contenedor a una red

* **`docker network disconnect`:** Desconectar contenedor de una red

Vamos a conectar el contenedor que está ejecutando la imagen de `nginx` a la `red2`
~~~
docker network connect red2 docker_nginx
~~~

Ahora lo vamos a desconectar
~~~
docker network disconnect red2 docker_nginx
~~~

Tanto al crear un contenedor con la opción `--network` como al usar el comando `docker network connect` podemos usar diferentes opciones:

* **`--dns`:** Para establecer servidores DNS predeterminados

* **`--ip6`:** Para establecer la dirección IPv6

* **`--hostname` o `-h`:** Para establecer el nombre de host del contenedor. Si no establecemos el `hostname` con esta opción, éste será el nombre del propio contenedor.

## Ejercicio: Instalación de Wordpress

Para la instalación de Workdpress necesitaremos dos contenedores:

* La base de datos (imagen `mariadb`)

* El servidor web con la aplicación (imagen `workpress`)

Los dos contenedores tienen que estar en la misma red y deben de tener acceso por nombres (resolución DNS) ya que de principio, no sabemos que IP tiene cada contenedor. Por lo tanto vamos a crear los contenedores en la misma red:

~~~
docker network create --subnet 172.10.0.0/16 --gateway 172.10.0.1 red_wp
2aa05c8085811dced11f38777f286d1e37f1a47654120a86f82026fd316847bf

mkdir -p wordpress/mariadb wordpress/wp

docker run --name maria_wp --network red_wp -v /home/juanan/wordpress/mariadb:/var/lib/mysql -e MYSQL_DATABASE=wp_db -e MYSQL_USER=usuario_wp -e MYSQL_PASSWORD=passwd_wp -e MYSQL_ROOT_PASSWORD=root -d mariadb
346f6aeb93f65f97e26e592922dc7d947d597da5f32d36caae74edb16b44240e

docker run --name docker_wp --network red_wp -v /home/juanan/wordpress/wp:/var/www/html/wp-content -e WORDPRESS_DB_HOST=maria_wp -e WORDPRESS_DB_USER=usuario_wp -e WORDPRESS_DB_PASSWORD=passwd_wp -e WORDPRESS_DB_NAME=wp_db -p 80:80 -d wordpress
aad713617b33eac4d316080fd0319516faea84d2719677ffee1a335426e17571

docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                NAMES
aad713617b33        wordpress           "docker-entrypoint.s…"   19 seconds ago      Up 17 seconds       0.0.0.0:80->80/tcp   docker_wp
346f6aeb93f6        mariadb             "docker-entrypoint.s…"   4 minutes ago       Up 4 minutes        3306/tcp             maria_wp
~~~

![Captura 16](/Docker/Documentacion/16.png)

# Ejercicios

1. **Ejecuta una instrucción docker para visualizar el contenido del fichero `wp-config.php` y verifica que los parámetros de conexión a la base de datos son los mismos que los que indicamos en las variables de entorno**
~~~
docker exec docker_wp bash -c 'cat /var/www/html/wp-config.php'
[...]
define( 'DB_NAME', 'wp_db');

/** MySQL database username */
define( 'DB_USER', 'usuario_wp');

/** MySQL database password */
define( 'DB_PASSWORD', 'passwd_wp');

/** MySQL hostname */
define( 'DB_HOST', 'maria_wp');
[...]
~~~

2. **Ejecuta una instrucción docker para comprobar que desde el servidor `docker_wp` podemos hacer un ping usando el nombre `maria_wp` (Tendrás que instalar el paquete `iputils-ping` en dicho contenedor)**

* Actualizamos la lista de paquetes e instalamos el paquete `iputils-ping`
~~~
docker exec docker_wp bash -c 'apt-get update && apt-get install -y iputils-ping && ping maria_wp'
[...]
PING maria_wp (172.10.0.2) 56(84) bytes of data.
64 bytes from maria_wp.red_wp (172.10.0.2): icmp_seq=1 ttl=64 time=0.156 ms
64 bytes from maria_wp.red_wp (172.10.0.2): icmp_seq=2 ttl=64 time=0.118 ms
64 bytes from maria_wp.red_wp (172.10.0.2): icmp_seq=3 ttl=64 time=0.122 ms
~~~

3. **Visualiza el fichero `/etc/mysql/mariadb.conf.d/50-server.cnf` del contenedor de la base de datos y comprueba cómo está configurado el parámetro `bind-address`**
~~~
docker exec maria_wp bash -c 'cat /etc/mysql/mariadb.conf.d/50-server.cnf | grep "bind-address"'
#bind-address            = 127.0.0.1
~~~

El parámetro `bind-address` está comentado

4. **Instala otro CMS PHP siguiendo la documentación de DockerHub de la aplicación seleccionada**
~~~
docker network create red_joomla
b19cc1d0fedb6a59b52b7dab3c99390b4cb9c1aa3a84bb84374dc18826d1bd56

docker run --name my_joomla --network red_joomla -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=joomla_db -e MYSQL_USER=joomla_user -e MYSQL_PASSWORD=joomla_passwd -d mariadb
938ec4c9b3beb8b4229b9d54e1bc327e6d6c09f1530ff451935750890d0c2d2a

docker run --name docker_joomla --network red_joomla -e JOOMLA_DB_HOST=my_joomla -e JOOMLA_DB_USER=joomla_user -e JOOMLA_DB_PASSWORD=joomla_passwd -e JOOMLA_DB_NAME=joomla_db -p 80:80 -d joomla
3815c6e2843428eb2a62d595365e8f868afcd3cfe0415b38f911d95132041768
~~~

![Captura 17](/Docker/Documentacion/17.png)
