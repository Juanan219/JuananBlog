---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-23
linktitle: Imagenes Docker
type:
- post
- posts
title: Uso de las Imagenes Docker
weight: 10
series:
- Hugo 101
images:
tags:
  - Docker
  - Apuntes
  - Documentacion
  - Imagenes
  - Ejercicios
  - PHP
  - Web
  - Apache
  - DockerHub
---

## Registros de Imágenes: DockerHub

![Captura 3](/Docker/Documentacion/3.png)

Las imágenes de Docker son plantillas de solo lectura, es decir, una imagen que contiene archivos de un sistema operativo como Debian, solo nos permitirá crear contenedores basados en dicha imagen, pero los cambios que hagamos en el contenedor, una vez que se ha detenido, no se verán reflejados en la imagen.

El nombre de una imágen suele estar formado por tres partes:
~~~
usuario/nombre:etiqueta
~~~

* **`usuario`:** El nombre del usuario que ha generado la imagen. Si la subimos a DockerHub, este nombre debe de ser el mismo con el que nos hemos dado de alta en la plataforma. Las **imágenes oficiales** en DockerHub no tienen nombre de usuario, sino que se llaman igual que la imagen. Por ejemplo, la imagen de debian se llamaría `debian/debian`

* **`nombre`:** Nombre significativo de la imagen.

* **`etiqueta`:** Nos permite versionar las imágenes. De esta manera podemos controlar los cambios que vamos haciendo en ellas. Si al descargar una imagen no le ponemos etiqueta, por defecto se descargará la versión `latest`, por lo que la mayoría de las imágenes tienen una versión con ese nombre.

## Gestión de imágenes

Para crear un contenedor, es necesario crearlo con una imagen que tengamos descargada en nuestro registro local. Por lo tanto al ejecutar `docker run` se comprueba si tenemos la versión indicada de la imagen, si no es así, se procede a descargarla.

Las principales instrucciones para trabajar con imágenes son:

* **`docker images`:** Muestra las imágenes que tenemos en nuestro registro local.

* **`docker pull`:** Nos permite descargar la última versión de la imagen indicada.

* **`docker rmi`:** Nos permite eliminar imágenes (No podemos eliminar una imagen si tenemos un contenedor usándola).

* **`docker search`:** Busca imágenes en DockerHub.

* **`docker inspect`:** No da información sobre la imagen indicada:

	* `ID` y `checksum` de la imagen.

	* Los puertos abiertos

	* La arquitectura y el sistema operativo de la imagen

	* El tamaño de la imagen

	* Los volúmenes

	* El ENTRYPOINT (es lo que ejecuta el comando `docker run`)

	* Las capas

	* Etc...

## ¿Cómo se organizan las imágenes?

Las imágenes están hechas de **capas ordenadas**. Las capas son un conjunto de cambios en el sistema de archivos. Cuando tomas todas las capas y las apilas obtienes una nueva imagen que tiene todos los cambios acumulados.

Si tienes varias imágenes que tienen capas en común, estas capas se almacenarán sólo una vez.

![Captura 4](/Docker/Documentacion/4.png)

Cuando se crea un nuevo contenedor, todas las capas de la imagen son de sólo lectura, pero se le agrega encima una pequeña capa de lectura-escritura, con lo cual, todos los cambios realizados en dicho contenedor son almacenados en esa capa que se le ha añadido.

El propio contenedor no puede modificar la imágen (ya que es de sólo lectura), por lo que creará una copia del fichero en su capa superior y desde ahí en adelante, cualquiera que trate de acceder al archivo, obtendrá la capa superior.

![Captura 5](/Docker/Documentacion/5.png)

Cuando creamos un contenedor, éste ocupa muy poco espacio en el disco, esto se debe a que las capas de la imagen desde la que se ha creado dicho contenedor, se comparten entre otros contenedores.

Este es el tamaño de la imagen `debian` que hemos usado en la documentación anterior:
~~~
juanan@juananpc:~$ docker images
REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
[...]
debian                        latest              5890f8ba95f6        2 weeks ago         114MB
[...]
~~~

Vamos a crear un contenedor interactivo y después visualizamos los contenedores con la opción `-s` (size o tamaño en español) para ver cuánto ocupan
~~~
juanan@juananpc:~$ docker run -it --name contenedor_debian debian /bin/bash
root@3f284a03c3d9:/# exit

juanan@juananpc:~$ docker ps -a -s
CONTAINER ID      IMAGE            COMMAND           CREATED           STATUS                     PORTS        NAMES               SIZE
3f284a03c3d9      debian           "/bin/bash"       8 seconds ago     Exited (0) 5 seconds ago                contenedor_debian   0B (virtual 114MB)
~~~

Podemos ver que el tamaño del contenedor es de `0B` y el tamaño virtual es de `114MB`, que es el tamaño de la imagen `debian`, pero si volvemos a arrancar el contenedor, nos conectamos y creamos un fichero, podemos ver que el tamaño cambia
~~~
juanan@juananpc:~$ docker start contenedor_debian
contenedor_debian

juanan@juananpc:~$ docker attach contenedor_debian
root@3f284a03c3d9:/# echo 'Hola, esto es un fichero de prueba' > fichero.txt
root@3f284a03c3d9:/# exit

juanan@juananpc:~$ docker ps -a -s
CONTAINER ID      IMAGE             COMMAND           CREATED           STATUS                     PORTS          NAMES               SIZE
3f284a03c3d9      debian            "/bin/bash"       4 minutes ago     Exited (0) 6 seconds ago                  contenedor_debian   91B (virtual 114MB)
~~~

Por último, si solicitamos información sobre una imagen podemos ver información sobre las capas:
~~~
docker inspect debian
[...]
"RootFS": {
            "Type": "layers",
            "Layers": [
                "sha256:7f03bfe4d6dc12155877f0d2e8b3429090bad1af7b005f75b7b3a874f386fd5a"
            ]
        },
[...]
~~~

## Creación de instancias desde imágenes

Hay dos tipos de imágenes en los repositorios y se dividen según la utilidad que nos ofrecen:

* Imágenes para ejecutar contenedores de diferentes sistemas operativos (Ubuntu, CentOS, Debian, etc...)

* Imágenes para ejecutar servicios asociados (Apache, MySQL, Tomcat, etc...)

Todas las imágenes tienen un proceso que se ejecuta por defecto, pero nosotros, al crear un contenedor, podemos indicarle el proceso que queremos que realice al crear dicho contenedor.

Por ejemplo, en la imagen `ubuntu`, el proceso por defecto es `bash`, por lo que podemos ejecutar:
~~~
docker run -it --name contenedor_ubuntu ubuntu
~~~

Pero podemos indicar el comando que queremos ejecutar en la creación del contenedor
~~~
docker run -it --name contenedor_ubuntu ubuntu /bin/echo 'Hola mundo'
~~~

Otro ejemplo: la imagen `httpd:2.4` ejecuta un servidor web por defecto, por lo tanto podemos crear el contenedor de la siguiente forma:
~~~
docker run -d --name contenedor_apache -p 8080:80 httpd:2.4
~~~

# Ejercicios

1. **Descarga las siguientes imágenes: `ubuntu:18.04`, `httpd`, `tomcat:9.0.39-jdk11`, `jenkins/jenkins:lts`, `php:7.4-apache`**

* `ubuntu:18.04`:
~~~
docker pull ubuntu:18.04
~~~

* `httpd`:
~~~
docker pull httpd
~~~

* `tomcat:9.0.39-jdk11`:
~~~
docker pull tomcat:9.0.39-jdk11
~~~

* `jenkins/jenkins:lts`
~~~
docker pull jenkins/jenkins
~~~

* `php:7.4-apache`:
~~~
docker pull php:7.4-apache
~~~

2. **Muestra las imágenes que tienes descargadas**
~~~
docker images
~~~

3. **Crea un contenedor demonio con la imagen `php:7.4-apache`**
~~~
docker run --name php_apache -p 8080:80 -d php:7.4-apache
371dba835efa5e4739efbf9d2bdc59f66c79d636dbc20f80e9388b83724adb7e

docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
371dba835efa        php:7.4-apache      "docker-php-entrypoi…"   8 seconds ago       Up 7 seconds        0.0.0.0:8080->80/tcp   php_apache
~~~

4. **Comprueba el tamaño del contenedor en el disco duro**
~~~
docker ps -s
CONTAINER ID     IMAGE             COMMAND                  CREATED              STATUS              PORTS                  NAMES          SIZE
371dba835efa     php:7.4-apache    "docker-php-entrypoi…"   About a minute ago   Up About a minute   0.0.0.0:8080->80/tcp   php_apache     2B (virtual 414MB)
~~~

El tamaño del contenedor es de `2B`

5. **Con la opción `docker cp` podemos copiar ficheros desde o hacia un contenedor. Copia el fichero `info.php` al directorio `/var/www/html` del contenedor**
~~~
echo '<?php phpinfo(); ?>' > info.php

docker cp info.php php_apache:/var/www/html
~~~

Ahora el contenedor ocupa `22B`

6. **Vuelve a comprobar el espacio del contenedor**
~~~
docker ps -s
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES          SIZE
371dba835efa        php:7.4-apache      "docker-php-entrypoi…"   5 minutes ago       Up 5 minutes        0.0.0.0:8080->80/tcp   php_apache     22B (virtual 414MB)
~~~

7. **Accede al fichero `info.php` desde un navegador**

![Captura 6](/Docker/Documentacion/6.png)
