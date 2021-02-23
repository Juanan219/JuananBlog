---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-23
linktitle: Escenarios con docker-compose
type:
- post
- posts
title: Creando escenarios multicontenedor con docker-compose
weight: 10
series:
- Hugo 101
images:
tags:
  - Docker
  - Documentacion
  - Apuntes
  - docker-compose
  - Multicontenedor
  - Wordpress
  - MySQL
  - MariaDB
  - YAML
---

En ocasiones, es necesario disponer de múltiples contenedores, como por ejemplo:

* Cuando necesitamos varios servicios para que la aplicación funcione, como por ejemplo con `Wordpress`, necesitaríamos un contenedor para la propia aplicación web y otro contenedor para el servidor de bases de datos `MySQL`.

* Si tenemos nuestra aplicación construida con microservicios, de los cuales, cada microservicio se ejecutará en un contenedor independiente.

Cuando trabajamos en escenarios en los que necesitamos varios contenedores, podemos usar `docker-compose` para gestionarlos.

Vamos a definir el escenario con un fchero llamado `docker-compose.yml` y vamos a gestionar el tiempo de vida de las aplicaciones y de todos los componentes que necesitamos con la utilidad `docker-compose`.

## Ventajas de usar doker-compose

* Hacer todo de manera declarativa para no tener que repetir el proceso una vez que se construye el escenario.

* Poner en marcha todos los contenedores que necesita mi aplicación de una sola vez y correctamente configurados.

* Garantizar que los contenedores se arrancan en el orden adecuado. Por ejemplo: Si mi aplicación no puede funcionar debidamente hasta que el servidor de bases de datos esté en marcha, configuraré el fichero para que se arranque antes el contenedor de la base de datos que el de la aplicación que depende de ella.

* Asegurarnos de que hay comunicación entre los contenedores que pertenecen a la aplicación.

## Instalación de docker-compose

* Para instalarlo desde repositorios de debian
~~~
sudo apt-get install docker-compose
~~~

* Para instalarlo con `pip` desde un entorno virtual:
~~~
python3 -m venv docker-compose
source docker-compose/bin/activate
(docker-compose) ~# pip install docker-compose
~~~

## El fichero docker-compose.yml

Con el fichero `docker-compose.yml` definimos el escenario. El programa `docker-compose` se tiene que ejecutar en el directorio en el cual esté este fichero. Por ejemplo, para la ejecución de un `wordpress` persistente deberíamos tener un fichero con el siguiente contenido:
~~~
version: '3.1'

services:

	wordpress:
		container_name: docker_wp
		image: wordpress
		restart: always
		environment:
			WORDPRESS_DB_HOST: maria_wp
			WORDPRESS_DB_USER: wordpress_user
			WORDPRESS_DB_PASSWORD: wordpress_passwd
			WORDPRESS_DB_NAME: wp_db
		volumes:
			- /home/juanan/wordpress/wp:/var/www/html

	db:
		container_name: maria_wp
		image: mariadb
		restart: always
		environment:
			MYSQL_DATABASE: wp_db
			MYSQL_USER: wordpress_user
			MYSQL_PASSWORD: wordpress_passwd
			MYSQL_ROOT_PASSWORD: root
		volumes:
			- /home/juanan/wordpress/mariadb:/var/lib/mysql
~~~

Puedes encontrar todos los parámetros que se pueden definir en la [documentación oficial](https://docs.docker.com/compose/compose-file/compose-file-v3/).

Algunos parámetros interesantes:

* **`restart: always`:** Indicamos la política de reinicio del contenedor, ya que si por algún motivo falla, esta se reinicia en lugar de quedarse apagada.

* **`depend: on`:** Indica la dependencia entre contenedores. No va a iniciar un contenedor hasta que otro esté funcionando.

Cuando creamos un escenario con el comando `docker-compose` se crea una nueva red definida por el usuario `docker`, en la cual se conectan los contenedores, por lo que tenemos resolución de nombres por DNS que resuelve tanto por el nombre (por ejemplo `servidor_mysql`) como por el alias (por ejemplo `maria_wp`).

* Para crear un escenario
~~~
docker compose up -d
~~~

* Para listar los contenedores
~~~
docker-compose ps
~~~

* Para parar los contenedores
~~~
docker-compose stop
~~~

* Para borrar los contenedores
~~~
docker-compose rm
~~~

## El comando docker-compose

Una vez que hemos creado el archivo `docker-compose.yml` tenemos que empezar a crear los contenedores que se describen en su contenido. Esto lo haremos ejecutando el comando `docker-compose` en el directorio en el que se encuentra el fichero de configuración.

Los subcomandos más usados son:

* **`docker-compose up`:** Crea los contenedores (servicios) que están definidos en el `docker-compose.yml`

* **`docker-compose up -d`:** Crea en modo `detach` los contenedores (servicios) que están descritos en el `docker-compose.yml`

* **`docker-compose stop`:** Detiene los contenedores que se han lanzado con `docker-compose up`

* **`docker-compose run`:** Inicia los contenedores definidos en el `docker-compose.yml` que estén preparados

* **`docker-compose rm`:** Borra los contenedores preparados del escenario. Con la opción `-f` borra también los que se estén ejecutando

* **`docker-compose pause`:** Pausa los contenedores que se han lanzado con `docker-compose up`

* **`docker-compose unpause`:** Reaunda los contenedores que están pausados

* **`docker-compose restart`:** Reinicia los contenedores. Este comando es ideal para reiniciar servicios con nuevas configuraciones.

* **`docker-compose down`:** Para los contenedores, los borra y con ellos borra las redes que se han creado con `docker-compose up` (en el caso de haberse creado)

* **`docker-compose down -v`:** Para los contenedores, los elimina, elimina sus redes y sus volúmenes.

* **`docker-compose logs servicio1`:** Muestra los logs del servicio llamado `servicio1` que estaba descrito en el `docker-compose.yml`

* **`docker-compose exec servicio1 /bin/bash`:** Ejecuta una orden, en este caso, `/bin/bash` en el contenedor llamado `servicio1` que estaba descrito en el `docker-compose.yml`

* **`docker-compose build`:** Ejecuta, si está indicado, el proceso de construcción de una imagen que va a ser usada en el `docker-compose.yml` a partir de los ficheros `dockerfile` que se indican.

* **`docker-compose top`:** Muestra los procesos que están ejecutándose en cada uno de los contenedores de los servicios.

# Ejercicios

1. **Instala `docker-compose` en tu ordenador. Copia el fichero `docker-compose.yml` de la [documentación](https://hub.docker.com/_/wordpress) de la imagen oficial de `wordpress`**
~~~
sudo apt-get install docker-compose

sudo mkdir docker-compose

cd docker-compose/

nano docker-compose.yml

version: '3.1'

services:

  wordpress:
    image: wordpress
    restart: always
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: exampleuser
      WORDPRESS_DB_PASSWORD: examplepass
      WORDPRESS_DB_NAME: exampledb
    volumes:
      - wordpress:/var/www/html

  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: exampledb
      MYSQL_USER: exampleuser
      MYSQL_PASSWORD: examplepass
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - db:/var/lib/mysql

volumes:
  wordpress:
  db:
~~~

2. **Modifica el `docker-compose.yml` para que use el puerto `8001`**
~~~
services:
	wordpress:
[...]
		ports:
			- 8080:8001
[...]
~~~

3. **Modifica el `docker-compose.yml` para que la base de datos se llame `db_wordpress`**
~~~
services:
	wordpress:
[...]
		environment:
[...]
			WORDPRESS_DB_NAME: db_wordpress
[...]
		db:
[...]
			environment:
				MYSQL_DATABASE: db_wordpress
[...]
~~~

4. **Modifica el `docker-compose.yml` para usar `bind mount` en lugar de volúmenes**
~~~
services:
	wordpress:
[...]
		volumes:
			- /home/juanan/wordpress/wp:/var/www/html
[...]
	db:
[...]
		volumes:
			- /home/juanan/wordpress/mariadb:/var/lib/mysql
~~~

5. **Levanta el escenario con `docker-compose`**
~~~
docker-compose up -d
~~~

6. **Muestra los contenedores con `docker-compose`**
~~~
docker-compose ps
       Name                     Command               State               Ports             
--------------------------------------------------------------------------------------------
juanan_db_1          docker-entrypoint.sh mysqld      Up      3306/tcp, 33060/tcp           
juanan_wordpress_1   docker-entrypoint.sh apach ...   Up      80/tcp, 0.0.0.0:8080->8001/tcp
~~~

7. **Accede a la aplicación y comprueba que funciona**

![Captura 17](/Docker/Documentacion/17.png)

8. **Comprueba el almacenamiento que has definido y que se ha creado una red de tipo `bridge`**
~~~
docker network ls
[...]
NETWORK ID          NAME                DRIVER              SCOPE
64f74f4b8685        juanan_default      bridge              local
[...]
~~~

9. **Borra el escenario con `docker-compose`**
~~~
docker-compose down
Stopping juanan_wordpress_1 ... done
Stopping juanan_db_1        ... done
Removing juanan_wordpress_1 ... done
Removing juanan_db_1        ... done
Removing network juanan_default
~~~
