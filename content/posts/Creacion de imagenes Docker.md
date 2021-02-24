---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-24
linktitle: Creacion de imagenes Docker
type:
- post
- posts
title: Creación de Imagenes Docker
weight: 10
series:
- Hugo 101
images:
tags:
  - Apuntes
  - Documentacion
  - Docker
  - DockerHub
  - GitHub
  - Imagenes
  - Linux
  - DockeBuild
  - Dockerfile
---

Hasta ahora hemos usado imágenes de Docker que han hecho otras personas, pero para crear un contenedor que sirva nuestra aplicación, deberemos crear una imagen personalidada. A esto es a lo que llamamos *dockerizar* una aplicación.

![Captura 19](/Docker/Documentacion/19.png)

## Creación de una imagen a partir de un contenedor

La primera forma de crear nuestras propias imágenes personalizadas es **crearlas a partir de un contenedor** que ya está en ejecución. Para ello tenemos varias posibilidades:

1. Usar la secuencia de órdenes `docker commit` / `docker save` / `docker load`. En este caso, la distribución se producirá a partir de un fichero.

2. Utilizar la pareja de órdenes `docker commit` / `docker push`. En este caso, la distribución se producirá a partir de **DockerHub**

3. Utilizar la pareja de órdenes `docker export` / `docker import`. En este caso, la distribución se producirá a partir de un fichero.

Nosotros veremos las dos primeras formas de crear una imagen a partir de un contenedor, ya que la tercera forma se limita a copiar el sistema de archivos sin tener en cuenta la información de las imágenes de las que deriva el contenedor y, además, si tenemos algún volumen montado, esta opción lo obviará.

### Distribución a partir de un fichero

1. Arranca un contenedor a partir de una imagen base
~~~
docker run -it --name docker_debian debian bash
~~~

2. Realiza modificaciones en el contenedor
~~~
root@b3bcf59aefc2:/# apt-get update && apt-get install -y apache2
~~~

3. Crear una nueva imagen partiendo de ese contenedor usando `docker commit`. Con esta instrucción se creará una nueva imagen con las capas de la imagen base mas la capa propia del contenedor. Al creala no voy a poner etiqueta, por lo que será latest.
~~~
docker commit docker_debian juanan219/debian_prueba
sha256:fc7791340642d790bf921715c445c20b5ddfc6863d7e47ba98d7a1c73d462d1c

docker images
REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
juanan219/debian_prueba       latest              fc7791340642        14 seconds ago      243MB
[...]
~~~

4. Guardar esa imagen en un archivo `.tar` usando el comando `docker save`:
~~~
docker save juanan219/debian_prueba > debian_prueba.tar

ls
debian_prueba.tar
~~~

5. Distribuir el archivo `.tar`

6. Si me llega un fichero `.tar` puedo añadir la imagen a mi repositorio local
~~~
docker rmi juanan219/debian_prueba
Untagged: juanan219/debian_prueba:latest
Deleted: sha256:fc7791340642d790bf921715c445c20b5ddfc6863d7e47ba98d7a1c73d462d1c
Deleted: sha256:ffc144c3004d5f83465eb03998204ca52530598d6388c65367484e33523991fd

docker load -i debian_prueba.tar 
b124061f7913: Loading layer [==================================================>]  132.4MB/132.4MB
Loaded image: juanan219/debian_prueba:latest
~~~

### Distribución usando DockerHub

1. Arranca un contenedor a partir de una imagen base
~~~
docker run -it --name debian_prueba debian bash
~~~

2. Realiza modificaciones en el contenedor
~~~
root@b3bcf59aefc2:/# apt-get update && apt-get install -y apache2
~~~

3. Crear una nueva imagen partiendo de ese contenedor usando `docker commit`. Con esta instrucción se creará una nueva imagen con las capas de la imagen base mas la capa propia del contenedor. Al creala no voy a poner etiqueta, por lo que será latest.
~~~
docker commit debian_prueba juanan219/debian_prueba
sha256:fc7791340642d790bf921715c445c20b5ddfc6863d7e47ba98d7a1c73d462d1c

docker images
REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
juanan219/debian_prueba       latest              fc7791340642        28 seconds ago      243MB
[...]
~~~

4. Autentificarme en Docker Hub usando el comando `docker login`.
~~~
docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: juanan219
Password: 
Login Succeeded
~~~

5. Distribuir ese fichero subiendo la nueva imagen a DockerHub mediante `docker push`.
~~~
docker push juanan219/debian_prueba
The push refers to repository [docker.io/juanan219/debian_prueba]
fd7d86e14e9c: Pushed 
7f03bfe4d6dc: Mounted from jenkins/jenkins 
latest: digest: sha256:29ca12fb2ecadeff4625d4cbea5a3aba92782f8b0702329e8b90134f3bde832d size: 741
~~~

Después de realizar esto, cualquier puede descargarse nuestra imagen tanto utilizándola como usando el comando `docker pull`.

## Creación de imágenes con fichero dockerfile

Crear imágenes a partir de contenedores ya creados tiene dos inconvenientes.

* **No se puede reproducir la imagen**, es decir, que si la perdemos tenemos que recordar toda la secuencia de órdenes que habíamos realizado desde que arrancamos el contenedor hasta que teníamos una versión definitiva e hicimos el `docker commit`

* **No podemos cambiar la imagen de base**, es decir, que si ha habido alguna actualización, problemas de seguridad o algo por el estilo con la imagen base, tenemos que descargar la nueva versión, volver a crear un nuevo contenedor basado en ella y volver a ejecutar de nuevo toda la secuencia de órdenes.

Por estos dos problemas, el método preferido para crear imágenes es el uso del llamado `dockerfile` y el comando `docker build`. Estos son los pasos fundamentales:

1. Crear el fichero `dockerfile`.

2. Construir la imagen usando la definición guardada en el fichero `dockerfile` y el comando `docker build`.

3. Autentificarme en DockerHub usando el comando `docker login`.

4. Distribuir ese fichero subiendo la nueva imagen a DockerHub mediante el comando `docker push`.

Con este método podemos tener ciertas ventajas:

* **Reproducir la imagen fácilmente** ya que en el fichero `dockerfile` tenemos todas las instrucciones necesarias para la construcción de la imagen. Si además tenemos el `dockerfile` en un repositorio con control de versiones como `git`, podemos además asociar los cambios en el `dockerfile` a los cambios de versiones de las imágenes creadas.

* Si queremos cambiar la imagen de base, esto es muy sencillo con el fichero `dockerfile`, ya que simplemente deberemos modificar la primera línea del fichero, como explicaremos posteriormente.

### El fichero Dockerfile

El fichero `dockerfile` es un conjunto de instrucciones que se irán ejecutando secuencialmente para construir una nueva imagen Docker. Cada una de las instrucciones que ejecutemos, creará una nueva capa en la imagen que estamos creando.

Hay varias instrucciones que podemos usar en la construcción de un `dockerfile`, pero la estructura fundamental de este fichero es:

* **`FROM`:** Aquí indicamos la imagen base

* **`MANTEINER, LABEL`:** Metadatos

* **`RUN, COPY, ADD, WORKDIR`:** Instrucciones de construcción

* **`USER, EXPOSE, ENV`:** Configuración (Variables de entorno, usuarios, puertos)

* **`CMD, ENTRYPOINT`:** Instrucciones de arranque

Vamos a ver las principales instrucciones que podemos usar:

* **`FROM`:** Sirve para especificar la imagen sobre la que voy a construir la mía.
~~~
FROM: php:7.4-apache
~~~

* **`LABEL`:** Sirve para añadir metadatos a la imagen clave.
~~~
LABEL company=iesgn
~~~

* **`COPY`:** Sirve para copiar fichero desde mi equipo hacia la imagen. Esos ficheros deben de estar en la misma carpeta o repositorio. La sintáxis de `COPY` es:
~~~
COPY [--chown=<usuario>:<grupo>] src dest
~~~

	* Ejemplo de `COPY`:
~~~
COPY --chown=www-data:www-data wordpress/wp /var/www/html
~~~

* **`ADD`:** Es similar a `COPY` pero tiene funcionalidades adicionales, como especificar URLs y tratar archivos comprimidos.

* **`RUN`:** Ejecuta una orden creando una nueva capa. La sintáxis de `RUN` es:
~~~
RUN orden

RUN ["orden","parámetro 1", "parámetro 2"]
~~~

	* Ejemplo de `RUN`:
~~~
RUN apt-get update && apt-get install -y git
~~~

> En este caso, es muy importante ejecutar el comando de instalación de `git` con la opción `-y`, ya que en el proceso de creación de la imagen con el `dockerfile` no puede haber interacción con el usuario.

* **`WORKDIR`:** Establece el directorio de trabajo dentro de la imagen que estoy creando, para posteriormente usar las órdenes `RUN`, `COPY`, `ADD`, `CMD` o `ENTRYPOINT`.
~~~
WORKDIR /usr/local/apache/htdocs
~~~

* **`EXPOSE`:** Nos da información sobre qué puertos tendrá abiertos el contenedor cuando se cree uno en base a la imagen que estamos creando. Es meramente informativo.
~~~
EXPOSE 80
~~~

* **`USER`:** Para especificar meidante nombre o `UID`/`GID` el usuario de trabajo para todas las órdenes `RUN`, `CMD` y `ENTRYPOINT` posteriores.
~~~
USER jenkins

USER 10001:10001
~~~

* **`ARG`:** Define variables para las cuales los usuarios pueden especificar valores a la hora de hacer el proceso de `build` mediante la opción `--build-arg`. Su sintáxis es:
~~~
ARG nombre_variable

ARG nombre_variable=valor_por_defecto
~~~

	* Ejemplo de `ARG`:
~~~
ARG usuario=www-data
~~~

> No se puede usar ni en `ENTRYPOINT` ni en `CMD`

* **`ENV`:** Para establecer variables de entorno dentro del contenedor. Puede ser usado posteriormente en las opciones `RUN` añadiendo `$` delante del nombre de la variable de entorno.
~~~
ENV WEB_DOCUMENT_ROOT=/var/www/html
~~~

> No se puede usar ni en `ENTRYPOINT` ni en `CMD`

* **`ENTRYPOINT`:** sirve para establecer el ejecutable que se lanza siempre que se crea un contenedor con `docker run`, salvo que se especifique algo con la opción `--entrypoint`. La sintáxis de `ENTRYPOINT` es:
~~~
ENTRYPOINT <comando>

ENTRYPOINT ["ejecutable", "parámetro 1", "parámetro 2"]
~~~

	* Ejemplo de `ENTRYPOINT`:
~~~
ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
~~~

* **`CMD`:** Sirve para establecer un ejecutable por defecto (salvo que se sobreescriba desde la orden `docker run`) o para especificar parámetros para un `ENTRYPOINT`. Si tengo varios, sólo se ejecuta el último. La sintáxis de `CMD` es:
~~~
CMD parámetro1 parámetro2

CMD ["parámetro 1","parámetro 2"]

CMD ["comando","parámetro 1"]
~~~

	* Ejemplo de `CMD`:
~~~
CMD ["-c","/etc/nginx.conf"]

ENTRYPOINT ["nginx"]
~~~

* **Ejemplo:**

	* Si tenemos un fichero `dockerfile` que tiene las siguientes instrucciones
~~~
ENTRYPOINT ["http", "-v"]

CMD ["-p", "80"]
~~~

	* Podemos crear un contenedor a partir de la imagen generada:

		* `docker run centos:centos7`: Se creará un contenedor con el servidor web escuchando en el puerto `80`.

		* `docker run centos:centos7 -p 8080`: Se creará un contenedor con el servidor web escuchando en el puerto `8080`

### Construyendo imágenes con docker build

El comando `docker build` construye las imágenes leyendo las instrucciones del `dockerfile` y la información de un entorno, que para nosotros va a ser un directorio (aunque también podemos gestionar la información de un repositorio `git`).

A la hora de crear una imagen, tenemos que tener en cuenta que cada vez que se ejecuta una instrucción se genera una imagen intermedia. Algunas imágenes intermedias se guardan en caché, otras se borran. Por lo tanto, si ejecutamos en una línea el comando `cd scripts/` y en otra línea ejecutamos `./install.sh`, no va a funcionar, ya que se ha lanzado otra imágen intermedia. Teniendo esto en cuenta, la manera correcta de ejecutar esto sería:
~~~
cd scripts/;./install.sh
~~~

Al generar las imágenes con `dockerfile`, como hemos dicho anteriormente, las imágenes se guardan temporalmente en caché, esto quiere decir que si en el proceso de creación de la imagen ha fallado algún paso, al corregirlo y volver a intentarlo, los pasos que han salido bien no se vuelven a repetir, ya que esas imágenes intermedias están almacenadas en la caché.

### Ejemplo de Dockerfile

Vamos a crear un directorio (el cual va a ser nuestro entorno de creación de la imagen) donde vamos a crear un `dockerfile` y un fichero `index.html`.
~~~
mkdir pruebas_docker
cd pruebas_docker/

echo "<h1>Esto es una prueba de Dockerfile</h1>" > index.html

nano Dockerfile

FROM debian 
MAINTAINER Juan Antonio Reifs Ramirez "initiategnat9@gmail.com"
RUN apt update  && apt install -y  apache2 
COPY index.html /var/www/html/index.html
ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]

ls
Dockerfile  index.html
~~~

Cuando tenemos creado y escritas las instrucciones en nuestro fichero `Dockerfile` y nuestro `index.html` creado vamos a generar la imagen con `docker build` indicando el nombre de la nueva imagen con la opción `-t` e indicando el directorio de contexto.
~~~
docker build -t juanan219/prueba_dockerfile .
~~~

Cuando haya terminado el proceso de generación de nuestra primera imagen, podemos verla en nuestro repositorio local
~~~
docker images
REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
juanan219/prueba_dockerfile   latest              67196e6920a2        53 seconds ago      243MB
[...]
~~~

Después de realizar esto, ya podemos usar la imágen como otra cualquier, a parte de poder distribuirla.

> Si usamos la opción `--no-cache` en el comando `docker-build` haríamos la construcción de la imagen sin usar las capas cacheadas.

### Buenas prácticas al crear un Dockerfile

* **Los contenedores deben ser efímeros:** esto quiere decir que los contenedores que se creen con nuestra imagen deben tener una mímina configuración.

* **Uso de ficheros `.dockerignore`:** Como hemos dicho anteriormente, todos los ficheros del contexto se envían al `docker engine`, por ello es recomendable usar un directorio/repositorio vacío en el cual vamos creando los fichero que vamos a ir necesitando. Además, para aumentar el rendimiento y evitar enviar ficheros innecesarios al daemon podemos usar un fichero `.dockerignore` para excluir ficheros y directorios.

* **No instalar paquetes innecesarios:** Para reducir la complejidad, dependencias, tiempo de creación y tamaño de la imagen resultante, se debe evitar instalar pequetes extras o innecesarios. Si necesitamos algún paquete durante la creación de la imagen, lomejor es desinstalarlo durante el proceso.

* **Minimizar el número de capas:** Debemos encontrar el balance entre la legibilidad del `Dockerfile` y minimizar el número de capas que utiliza.

* **Indicar las instrucciones a ejecutar múltiples tareas:** Hay que organizar los argumentos de las instrucciones que contengan múltiples línes para facilitar futuros cambios. Esto evitará la duplicación de paquetes y hará que el archivo sea más fácil de leer. Por ejemplo:
~~~
RUN apt-get update && apt-get install -y \
git \
wget \
apache2 \
php5
~~~
