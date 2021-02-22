---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-22
linktitle: Documentacion Docker 1
type:
- post
- posts
title: Introduccion a Docker
weight: 10
series:
- Hugo 101
images:
tags:
  - Docker
  - Documentacion
  - Apuntes
  - Introduccion
  - Web
  - Aplicaciones
  - Nextcloud
  - Apache
  - Ningx
  - DockerHub
---

## Introducción a Docker

El objetivo de **Docker** es el despliegue de aplicaciones en capsuladas en contenedores, en lugar de desplegar las aplicaciones en máquinas virtuales.

**Docker** está formado por varios componentes:

* **Docker Engine:** Es un demonio de cualquier distribución Linux, el cual tiene una API para gestionar las imágenes y contenedores. Sirve para crear imágenes, subirlas y bajarlas de un registro docker, ejecutar y gestionar contenedores.

* **Docker Client:** Este es el CLI (Command Line Interface) que nos permite controlar `Docker Engine`. Este cliente se puede configurar tanto local como remoto permitiéndonos gestionar nuestro entorno de desarrollo local como nuestro entorno de producción remoto.

* **Docker Registry:** Almacena las imágenes gestionadas por `Docker Engine`. Este apartado de docker es totalmente fundamental, ya que es el que se encarga de distribuir nuestras aplicaciones. Se puede instalar en cualquier servidor y de manera totalmente independiente, pero el proyecto docker nos ofrece **Docker Hub**.

## Instalación de Docker

* Instalación de la comunidad
~~~
sudo apt-get install docker.io
~~~

* Si queremos usar docker con el usuario sin privilegios
~~~
sudo usermod -aG docker usuario
~~~

## El "Hola Mundo" de Docker

Comprobaremos que todo esto funciona ejecutando nuestro primer contenedor llamado `hello-world`.
~~~
docker run hello-world
~~~

* ¿Qué es lo que ocurre cuando ejecutamos `docker run hello-world`?

	* Al ser la primera vez que ejecuto un contenedor basado en la imagen `hello-world`, esta se descarga desde el repositorio que se encuentra en el registro que vamos a usar, en nuestro caso es `DockerHub`.

	* Después de descargarse muestra el mensaje de bienvenida, consecuencia de crear y arrancar un contenedor basado en la imagen `hello-world`.

**Otro ejemplo:**
~~~
docker run ubuntu /bin/echo 'Hello world'
~~~

Con el comando `run` vamos a ejecutar un contenedor en el que vamos a ejecutar un comando, en este caso, hemos creado un contenedor con una imagen basada en `ubuntu`. Como es la primera vez que ejecutamos un contenedor basado en esta imagen, se descargará de `DockerHub`, si no es así, esta no se descargará y simplemente se ejecutará el contenedor.

Después podemos comprobar que se ha ejecutado con el comando `ps -a`, de esta forma podemos ver todos los contenedores que hemos ejecutado
~~~
docker ps -a
~~~

## Comandos de Docker

* Listar los contenedores que se están ejecutando
~~~
docker ps
~~~

* Listar todos los contenedores
~~~
docker ps -a
~~~

* Eliminar un contenedor identificando su `ID`
~~~
docker rm [ID]
~~~

* Eliminar un contenedor por su nombre
~~~
docker rm [nombre]
~~~

* Ver todas las imágenes que tenemos descargadas:
~~~
docker images
~~~

* Iniciar un contenedor
~~~
docker start [nombre]
~~~

* Conectarse a un contenedor
~~~
docker attach [nombre]
~~~

* Ver lo que está haciendo un contenedor
~~~
docker logs [nombre]
~~~

* Parar un contenedor
~~~
docker stop [nombre]
~~~

* Eliminar un contenedor
~~~
docker rm [nombre]
~~~

## Ejecutando un contenedor interactivo

Para abrir una sesión interactiva deberemos ejecutar el parámetro `-i` y con la opción `-t` nos permite usar un pseudo-terminal que nos permite interactuar con el contenedor ejecutado. También le podemos indicar un nombre con la opción `--name` y después acompañamos a este comando con el nombre de la imágen que vamos a usar, en este caso `ubuntu` y por último, ponemos el comando que vamos a ejecutar, el cual será `/bin/bash`, el cual lanzará una `bash` desde el contenedor.
~~~
docker run -it --name contenedor1 ubuntu /bin/bash
~~~

* Resumen del comando:

	* **-i:** Abrir una sesión de forma interactiva
	* **-t:** Usar una terminal
	* **--name [nombre]:** Definimos el nombre que queremos que tenga el contenedor que vamos a ejecutar
	* **ubuntu:** Es el nombre de la imagen que vamos a usar en este contenedor
	* **/bin/bash:** Es el comando que va a ejecutar el contenedor cuando éste se ejecute.

Los conetedores son efímeros, es decir, nada más que el contenedor termine su trabajo, éste se para. Si queremos volver a usar un contenedor que ya hemos ejecutado con anterioridad usaremos el comando `start` y si nos queremos conectar a él usamos la opción `attach`
~~~
docker start contenedor1
docker attach contenedor1
~~~

Si el contenedor ya se está ejecutando, podemos ejecutar comandos en él con el comando `exec`
~~~
docker exec contenedor1 ls -l
~~~

Si lo que queremos es reiniciar el contenedor, solo deberemos usar el comando `restart`
~~~
docker restart contenedor1
~~~

Para ver información del contenedor
~~~
docker inspect contenedor1
~~~

En realidad, todas las `imágenes docker` tienen definidas un proceso que se ejecuta. En la imagen `ubuntu`, por ejemplo, el proceso por defecto que se ejecuta es `bash`, por lo que podríamos haber ejecutado
~~~
docker run -it --name contenedor1 ubuntu
~~~

Esto quiere decir que no era necesario acompañar a dicho comando con el comando del final `/bin/bash`, ya que la imagen lo ejecuta por defecto.

## Creando un contenedor demonio

Podemos crear un contenedor demonio con la opción `-d` del comando `run`, para que el contenedor se quede corriendo en segundo plano.
~~~
docker run -d --name contenedor2 ubuntu /bin/sh -c "yes hello world"
~~~

Vamos a comprobar que se está ejecutando
~~~
docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
32d7577b9a6c        ubuntu              "/bin/sh -c 'yes hel…"   26 seconds ago      Up 25 seconds                           contenedor2
~~~

Podemos comprobar qué es lo que está haciendo dicho contenedor con el comando
~~~
docker logs contenedor2
~~~

Para parar un contenedor y eliminarlo
~~~
docker stop contenedor2
docker rm contenedor2
~~~

Comprobamos que se ha eliminado
~~~
docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
~~~

Como no se puede eliminar un contenedor que está en ejecución , podemos forzar su eliminación con el comando
~~~
docker rm -f contenedor2
~~~

## Creando un contenedor con un servidor web

Tenemos muchas imágenes en el repositorio público de **DockerHub**. Si queremos crear un contenedor con un servidor `apache 2.4`
~~~
docker run -d --name my-apache-app -p 8080:80 httpd:2.4
~~~

* **-p 8080:80:** Con esta opción mapeamos un puerto del equipo donde tenemos instalado `docker` con un puerto del contenedor. Para comprobar que esto funciona, podemos entrar desde nuestro navegador a la `IP del contenedor` y al `puerto 8080`

Podemos ver lo que está haciendo `apache` mirando los logs con el comando que hemos visto antes, pero si le añadimos la opción `-f` podremos ver los logs e3n tiempo real
~~~
docker logs -f my-apache-app
~~~

## Configuración de contenedores con variables de entorno

Ahora veremos que al crear un contenedor, dependiendo de lo que queramos hacer, requiere una configuración específica, así que crearemos variables de entorno para poder configurarlo. Para crear las variables de entorno usaremos la opción `-e` o `--env`
~~~
docker run -it --name prueba -e USUARIO=prueba ubuntu bash
root@18edc1b5414e:/# echo $USUARIO
prueba
~~~

En algunas ocasiones, es necesario inicializar alguna variable de entorno para que el contenedor pueda ser ejecutado. Si miramos la [documentación](https://hub.docker.com/_/mariadb) en DockerHub de la imagen de `mariadb`, vemos que podemos definir algunas variables de entorno como pueden ser: `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, etc... pero una de ellas hay que indicarlas de manera obligatoria para poder ejecutar dicho contenedor y esa variable es la contraseña del usuario `root` (`MYSQL_ROOT_PASSWORD`), por lo tanto, el comando de ejecución del contenedor con la imagen de `mariadb` es
~~~
docker run --name contenedor_mariadb -e MYSQL_ROOT_PASSWORD=root -d mariadb
~~~

Podemos verificar que está funcionando
~~~
docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
0922f9029852        mariadb             "docker-entrypoint.s…"   6 seconds ago       Up 4 seconds        3306/tcp            contenedor_mariadb
~~~

Entre todas las veriables de entorno que tiene definidas por defecto la imagen de `mariadb`, podemos encontrar la variable `MYSQL_ROOT_PASSWORD` con el valor `root` que le hemos definido. Para ver todas las variables de entorno de un contenedor podemos ejecutar el siguiente comando
~~~
docker exec -it contenedor_mariadb env
[...]
MYSQL_ROOT_PASSWORD=root
[...]
~~~

Y si queremos acceder a dicha máquina para comprobar que podemos acceder a la base de datos con esa contraseña, podemos ejecutar
~~~
root@0922f9029852:/# mysql -u root -p$MYSQL_ROOT_PASSWORD
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 4
Server version: 10.5.8-MariaDB-1:10.5.8+maria~focal mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]>
~~~

# Ejercicios

1. **Instala un docker en una máquina y configúralo para que se pueda acceder sin privilegios**

* Instalación
~~~
sudo apt-get install docker.io
~~~

* Configuración para acceder sin privilegios
~~~
sudo usermod -aG docker juanan
~~~

2. **Crea un contenedor interactivo desde una imagen debian. Instala un paquete (por ejemplo `nano`). Sal de la terminal, ¿sigue el contenedor corriendo?¿Por qué? Vuelve a iniciar el contenedor y accede de nuevo a él de forma interactiva. ¿Sigue instalado el `nano`? Sal del contenedor y bórralo. Crea un nuevo contenedor interactivo desde la misma imagen. ¿Tiene el `nano` instalado?**

* Creo un contenedor interactivo con la imagen `debian`
~~~
docker run -it --name contenedor_debian debian /bin/bash
~~~

* Instalo `nano` en el contenedor
~~~
root@e0e5f5265ae7:/# apt-get update
root@e0e5f5265ae7:/# apt-get install nano
~~~

* Salgo de la terminal y compruebo si el contenedor sigue corriendo
~~~
root@e0e5f5265ae7:/# exit
exit
juanan@juananpc:~$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
~~~

	* El `contenedor` no sigue corriendo porque los `contenedores docker` son efímeros y cuando terminan su función principal, estos se paran y se quedan guardados, pero parados. Podemos ver los contenedores que están creados, pero parados con el comando `ps -a`
~~~
juanan@juananpc:~$ docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS                          PORTS               NAMES
e0e5f5265ae7        debian              "/bin/bash"         3 minutes ago       Exited (0) About a minute ago                       contenedor_debian
~~~

* Vuelvo a iniciar el contenedor y accedo a él de forma interactiva
~~~
juanan@juananpc:~$ docker start contenedor_debian
contenedor_debian
juanan@juananpc:~$ docker attach contenedor_debian
root@e0e5f5265ae7:/# whereis nano
nano: /bin/nano /usr/share/nano /usr/share/man/man1/nano.1.gz /usr/share/info/nano.info.gz
~~~

	* Al volver a iniciar el contenedor sí que sigue teniendo instalado `nano`

* Salgo del contenedor, lo borro, vuelvo a crear un nuevo contenedor con la misma imagen y compruebo si tiene `nano` instalado
~~~
root@e0e5f5265ae7:/# exit
exit
juanan@juananpc:~$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
juanan@juananpc:~$ docker rm contenedor_debian
contenedor_debian
juanan@juananpc:~$ docker run -it --name contenedor_debian2 debian /bin/bash
root@cc6520b717b2:/# whereis nano
nano:
~~~

	* No tiene `nano` instalado, ya que hemos eliminado el contenedor entero y éste no tenía ningún dispositivo de almacenamiento.

3. **Crea un contenedor demonio con un servidor `nginx`. Al crear el contenedor, ¿has tenido que indicar algún comando para que lo ejecute? Accede al navegador web y comprueba que el servidor está funcionando. Muestra los logs del contenedor.**

* Creo un contenedor demonio con una imagen de nginx
~~~
docker run -p 8080:80 --name docker_nginx -d nginx
~~~

	* No, no he tenido que ejecutar ningún comando para que el contenedor ejecute el servicio de `nginx` al ser creado.

* Accedo a mi navegador web y compruebo que está ejecutando el servicio de `nginx`. A esta página web podemos acceder de tres formas:

	* A través de la ip del contenedor, para ello deberemos averiguarla con el siguiente comando
~~~
docker inspect docker_nginx
[...]
"IPAddress": "172.17.0.2",
[...]
~~~

	* A través de nuestra ip de la tarjeta de red y poniendo al final `:8080`

	* A través de nuestra ip de `loopback` y el puerto `:8080` (`127.0.0.1:8080`)

![Captura 1](/Docker/Documentacion/1.png)

* Muestro los logs del contenedor
~~~
juanan@juananpc:~$ docker logs docker_nginx
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
172.17.0.1 - - [22/Feb/2021:20:29:17 +0000] "GET / HTTP/1.1" 200 612 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36" "-"
172.17.0.1 - - [22/Feb/2021:20:29:17 +0000] "GET /favicon.ico HTTP/1.1" 404 555 "http://192.168.1.112:8080/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36" "-"
2021/02/22 20:29:17 [error] 30#30: *2 open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory), client: 172.17.0.1, server: localhost, request: "GET /favicon.ico HTTP/1.1", host: "192.168.1.112:8080", referrer: "http://192.168.1.112:8080/"
172.17.0.1 - - [22/Feb/2021:20:29:22 +0000] "GET / HTTP/1.1" 200 612 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36" "-"
2021/02/22 20:29:22 [error] 30#30: *4 open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory), client: 172.17.0.1, server: localhost, request: "GET /favicon.ico HTTP/1.1", host: "127.0.0.1:8080", referrer: "http://127.0.0.1:8080/"
172.17.0.1 - - [22/Feb/2021:20:29:22 +0000] "GET /favicon.ico HTTP/1.1" 404 555 "http://127.0.0.1:8080/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36" "-"
~~~

4. **Crea un contenedor con la aplicación `Nextcloud`, mirando la documentación de DockerHub, para personalizar el nombre de la base de datos sqlite que va a utilizar**

* Creo un contenedor con la imagen de `Nextcloud` con la variable de entorno `SQLITE_DATABASE` cuyo nombre va a ser `juanan_db`
~~~
docker run -p 8080:80 --name docker_nextcloud -e SQLITE_DATABASE=juanan_db -d nextcloud
~~~

* Comprobamos que funciona
![Captura 2](/Docker/Documentacion/2.png)
