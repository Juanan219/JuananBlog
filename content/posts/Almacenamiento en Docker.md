---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-23
linktitle: Almacenamiento en Docker
type:
- post
- posts
title: Almacenamiento en Docker
weight: 10
series:
- Hugo 101
images:
tags:
  - Docker
  - Almacenamiento
  - Volumenes
  - BindMount
  - Apache
  - PHP
  - Nginx
---

## Los contenedores son efímeros

Los contenedores de docker **son efímeros**, es decir, todo lo que generamos dentro de un contenedor resisten a las paradas de los contenedores, pero cuando eliminamos un contenedor, todo lo que hay en su interior se elimina con él. Veamos esto creando un contenedor y creando dentro de él un fichero, cuando lo eliminemos, crearemos otro contenedor para comprobar si ese archivo está
~~~
docker run --name docker_nginx -p 8080:80 -d nginx
c45464659bca8dc80372f7fcbcf1fa8e2abdb7f3d68dd7eb46a22ef6d5cf824f

docker exec docker_nginx bash -c 'echo "<h1>Esto es una prueba</h1>" > /usr/share/nginx/html/index.html'

curl 127.0.0.1:8080
<h1>Esto es una prueba</h1>

docker rm -f docker_nginx
docker_nginx

docker run --name docker_nginx -p 8080:80 -d nginx
9168378ab8621adea4936a49d556ba999c8b54d29eeaf99f1eabc6d5a2c7553c

curl 127.0.0.1:8080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
~~~

Como podemos ver, el fichero que habíamos creado anteriormente como `index.html` ha desaparecido y se ha sustituido por el fichero `index.html` predeterminado de `nginx`, esto quiere decir qu enuestro ficher se ha eliminado junto con el contenedor.

* **Explicación:** El comando que hemos usado para introducir el fichero contiene la opción `bash -c`, la cual nos permite ejecutar varias instrucciones de bash de forma más compleja (por ejemplo indicando ficheros dentro del sistema).

## Los datos de los contenedores

Ante la anterior situación, Docker nos proporciona varias formas de resolver este problema. Ahora veremos las dos soluciones más importantes, que son:

* **Volúmenes Docker:** Si elegimos resolver el problema anterior usando **volúmenes docker** quiere decir que vamos a guardar nuestros datos en una parte del sistema la cual es gestionada por Docker y a la que debido a sus permisos, sólo Docker tendrá acceso. Se guardan en `/var/lib/docker/volumes`. Esta solución se suele usar en los siguientes casos:

	* Para compartir datos entre contenedores, ya que simplemente deberán usar el mismo volúmen.

	* Para copias de seguridad.

	* Cuando queremos almacenar los datos de nuestros contenedores en un servidor cloud.

* **Bind Mount:** Al usar esta solución, lo que estamos haciendo es *mapear* (o montar) una parte de mi sistema de ficheros (de la que normalmente tenemos el control) con una parte del sistema de ficheros del contenedor. De esta forma conseguimos:

	* Compartir ficheros entre el *anfitrión* y el *contenedor*

	* Que otras aplicaciones que no sean docker tengan acceso a esos ficheros, ya sean código, ficheros, etc...

## Gestionando volúmenes

Algunos de los comandos más útiles para trabajas con volúmenes docker son:

* **`docker volume create`:** Crea un volumen con el nombre indicado.

* **`docker volume rm`:** Elimina el volumen indicado.

* **`docker volume prune`:** Elimina los volúmenes que no están siendo usados por ningún contenedor

* **`docker volume ls`:** Lista los volúmenes y proporciona algo de información adicional.

* **`docker volume inspect`:** También lista los volúmenes pero de forma mucho más detallada que `volume ls`.

## Asociando almacenamiento a los contenedores

Para usar tanto los **volúemenes docker** como los **bind mount** necesitaremos usar dos *flags* (u opciones) para usar cualquiera de los dos métodos de almacenamiento:

* `--volume` o `-v`

* `--mount`

Es importante que tengamos en cuenta dos cosas importantes para realizar estas dos operaciones:

* Si existe el directorio donde vamos a montar tanto los **volúmenes docker** como los **bind mount**, este se sobreescribirá, por lo que toda la información de dicho directorio (repito, si existe) se eliminará.

* Si nuestra carpeta donde hemos indicado el montaje no existe y hacemos un **bind mount** esta carpeta se creará y tendremos un directorio vacío como almacenamiento.

* Si usamos imágenes de DockerHub, debemos prestar atención ala información de su página, ya que ahí nos dice cómo persistir los datos de dicha imagen.

## Ejemplo usando Volúmenes Docker
~~~
docker volume create prueba
prueba

docker run --name docker_nginx --mount type=volume,src=prueba,dst=/usr/share/nginx/html/ -p 8080:80 -d nginx
c0b5f88eb32bcb96b0285b345d41e77d01f42a768ec09484cf4d1f2f0b79a3d0

docker exec docker_nginx bash -c 'echo "<h1>Esto es una prueba de almacenamiento</h1>" > /usr/share/nginx/html/index.html'

curl 127.0.0.1:8080
<h1>Esto es una prueba de almacenamiento</h1>

docker rm -f docker_nginx
docker_nginx

docker run --name docker_nginx2 -v prueba:/usr/share/nginx/html/ -p 8080:80 -d nginx
bfff1f83504544106dd916db40ca4e566e508ca9bb95b387d7efe9422660176d

curl 127.0.0.1:8080
<h1>Esto es una prueba de almacenamiento</h1>
~~~

Como podemos ver arriba, hemos creado un volumen llamado `prueba`, después hemos creado un contenedor y hemos montado el volumen que hemos creado en la ruta `/usr/share/nginx/html/`, la cual es la que usa `nginx` por defecto para servir su página de ejemplo, hemos usado el comando `exec` de docker y hemos sustituido el fichero `inde.html` predeterminado por uno modificado por mí, para después eliminar el contenedor y crear uno nuevo con el volumen `prueba` ya montado y como podemos ver, la información del fichero `index.html` modificado la seguimos teniendo.

Si ubiesemos usado la opción `--mount` de esta forma `--mount type=volume,dst=/usr/share/nginx/html/` se hubiese creado un nuevo volumen, ya que no hemos indicado ninguno que pueda usar.

Si usamos la opción `-v` e indicamos un nombre, se creará un nuevo volumen docker
~~~
docker run --name docker_nginx2 -v prueba2:/usr/share/nginx/html/ -p 8080:80 -d nginx
bab32cc75f4f2fea0fa51c4b4244cc942ea90e0220c7a5f105276b4be3c7ebd8

docker volume ls
DRIVER              VOLUME NAME
local               prueba
local               prueba2
~~~

## Ejemplo usando bind mount

En este caso vamos a crear un dicrectorio en el sistema de archivos del anfitrión y dentro de dicho directorio vamos a crear un archivo `index.html`
~~~
mkdir prueba

echo "<h1>Esto es una prueba de bind mount</h1>" > prueba/index.html

docker run --name docker_nginx -v /home/juanan/prueba:/usr/share/nginx/html/ -p 8080:80 -d nginx
98115c4a68a25f3b3ecedf3c81dbae1de5f3017ac84edf1c3ecc47636de0c993

curl 127.0.0.1:8080
<h1>Esto es una prueba de bind mount</h1>

docker rm -f docker_nginx
docker_nginx

docker run --name docker_nginx2 --mount type=bind,src=/home/juanan/prueba,dst=/usr/share/nginx/html/ -p 8080:80 -d nginx
b231eaf659b738d74e4e119165666db0de61cee862af7d9c8b56f4b9e62dacdb

curl 127.0.0.1:8080
<h1>Esto es una prueba de bind mount</h1>
~~~

En este ejemplo hemos hecho lo mismo que con los volúmenes, pero con la diferencia que en lugar de crear un volúmen hemos usado un **bind mount**, es decir, hemos creado un directorio que tiene en su interior un archivo `index.html`.

Como podemos comprobar, también podemos modificar el ficheor aunque el contenedor esté activo
~~~
echo "<h1>Este archivo se ha modificado</h1>" > prueba/index.html

curl 127.0.0.1:8080
<h1>Este archivo se ha modificado</h1>
~~~

## Ejercicio: Contenedor mariadb con almacenamiento persistente

En la [documentación de mariadb](https://hub.docker.com/_/mariadb) en DockerHub nos dice que podemos crear un contenedor co almacenamiento persistente de la siguiente manera
~~~
docker run --name some-mariadb -v /home/usuario/datadir:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mariadb
~~~

Esto quiere decir que se va a crear un directorio en `/home/usuario/datadir`, en el cual se va a guardar la información de la base de datos. Si tenemos que crear un nuevo contenedor, indicaremos ese directorio como **bind mount** y volveremos a tener accesible dicha información.

~~~
docker run --name docker_mariadb -v /home/juanan/datadir:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root -d mariadb
1f6d378308ff18e795969319bc48e4ae170f45ce3f6c5b6b60b4b7b3ee474a4c

ls datadir/
aria_log.00000001  aria_log_control  ib_buffer_pool  ibdata1  ib_logfile0  ibtmp1  multi-master.info  mysql  performance_schema

docker rm -f docker_mariadb
docker_mariadb

docker run --name docker_mariadb --mount type=bind,src=/home/juanan/datadir,dst=/var/lib/mysql -e MYSQL_ROOT_PASSWORD=root -d mariadb
12d8638feb79eac951036bcc80e3bf98885ca491b84d561d4f57d16f6056e0f9

docker exec -it docker_mariadb bash -c 'mysql -u root -p$MYSQL_ROOT_PASSWORD'
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 3
Server version: 10.5.8-MariaDB-1:10.5.8+maria~focal mariadb.org binary distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
3 rows in set (0.000 sec)
~~~

## ¿Qué información tenemos que guardar?

Para terminar: ¿Qué debemos guardar de forma persistente en un contenedor?

* Datos de una aplicación

* Logs del servicio

* Configuración del servicio: En este caso podemos añadir la configuración a la imagen, pero será necesaria la creación de una nueva imagen si cambiamos la configuración. Si la guardamos en un volumen hay que tener en cuenta de tener ese fichero en el entrono de producción (puede ser bueno, porque las configuraciones de los distintos entornos pueden variar).

# Ejercicios

1. **Vamos a trabajar con volúmenes docker:**

	* **Crea un volumen que se llame `miweb`**
~~~
docker volume create miweb
miweb
~~~

	* **Crea un contenedor desde la imagen `php:7.4-apache` donde montes en el directorio `/var/www/html` (que sabemos que es el `documentroot` del servidor que nos ofrece esa imagen) el volumen docker que has creado**
~~~
docker run --name apache_php --mount type=volume,src=miweb,dst=/var/www/html -p 8080:80 -d php:7.4-apache
2cd22b7170868556cfb8f3bc3dc599186bb5880bf903455f0175a9203f7c22dc
~~~

	* **Utiliza el comando `docker cp` para copiar un fichero `info.php` en el directorio `/var/www/html`**
~~~
echo "<?php phpinfo(); ?>" > info.php
docker cp info.php apache_php:/var/www/html
~~~

	* **Accede al contenedor desde el navegador para ver la información ofrecida por el fichero `php.info`**

![Captura 8](/Docker/Documentacion/8.png)

	* **Borra el contenedor**
~~~
docker rm -f apache_php
apache_php
~~~

	* **Crea un nuevo contenedor y monta el mismo volumen como en el ejercicio anterior**
~~~
docker run --name apache_php --mount type=volume,src=miweb,dst=/var/www/html -p 8080:80 -d php:7.4-apache
6a6735f1bfb70eecbeb60769dbf20dd4539211d60832294f1961101a52b53564
~~~

	* **Accede al contenedor desde el navegador para ver la información ofrecida por el fichero `info.php`. ¿Seguía existiendo ese fichero?**

![Captura 8](/Docker/Documentacion/8.png)

Sí, sigue existiendo el fichero, ya que está almacenado en el volumen.

2. **Vamos a trabajar con `bind mount`**

	* **Crea un directorio en tu host y dentro crea el fichero `index.html`**
~~~
mkdir miweb

echo "<h1>Esto es una prueba de Bind Mount</h1>" > miweb/index.html
~~~

	* **Crea un contenedor desde la imagen `php:7.4-apache` donde montes en el directorio `/var/www/html` el directorio que has creado por medio de `bind mount`**
~~~
docker run --name apache_php -v /home/juanan/miweb:/var/www/html -p 8080:80 -d php:7.4-apache
93b868e418f4713d450f8fec76848a57ab7bcff7887bf3f294fa04d029a66192
~~~

	* **Accede al contenedor desde el navegador para ver la información ofrecida por el fichero `index.html`**
![Captura 9](/Docker/Documentacion/9.png)

	* **Modifica el fichero `index.html` en tu host y comprueba que al refrescar la página ofrecida por el contenedor, el contenido ha cambiado**
~~~
echo "<h1>Esto es la segunda prueba de Bind Mount</h1>" > miweb/index.html
~~~

![Captura 10](/Docker/Documentacion/10.png)

	* **Borra el contenedor**
~~~
docker rm -f apache_php
apache_php
~~~

	* **Crea un nuevo contenedor y monta el mismo directorio como en el ejercicio anterior**
~~~
docker run --name apache_php -v /home/juanan/miweb:/var/www/html -p 8080:80 -d php:7.4-apache
122bcc07c2a88f0d685c5d09eaa02e144c57408a0e8dee8e2079d778381e0314
~~~

	* **Accede al contenedor desde el navegador para ver la información ofrecida por el fichero `index.html`. ¿Se sigue viendo el mismo contenido?**

![Captura 10](/Docker/Documentacion/10.png)

Sí, se sigue visualizando el mismo contenido, ya que el fichero `index.html` está almacenado en el directorio que usamos como **bind mount**.
