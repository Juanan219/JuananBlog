---
author:
  name: "Juan Antonio Reifs"
date: 2021-03-07
linktitle: Aplicaciones en Docker
type:
- post
- posts
title: Implantación de aplicaciones web PHP en Docker
weight: 10
series:
- Hugo 101
images:
tags:
  - Practica
  - Docker
  - PHP
  - CMS
  - Bookmedik
---

## Tarea 1

* Crea un script con docker-compose que levante el escenario con los dos contenedores.(Usuario: admin, contraseña: admin).

Para levantar la aplicación web [bookmedik](https://github.com/evilnapsis/bookmedik) necesitaremos un contenedor con la imagen de `mariadb` en el cual vamos a crear un usuario llamado `book_user` con una contraseña `book_passwd`, una base de datos llamada `bookmedik` y le vamos a volcar el contenido del fichero `schema.sql` del repositorio de GitHub de `bookmedik`, del cual, vamos a eliminar la primera línea para que no nos de conflicto a la hora de ejecutar el script. Al contenedor de `mariadb` vamos a crearle un volumen para que pueda guardar la base de datos.
~~~
docker network create red1--subnet
docker run --name book_sql -v mysql:/var/lib/mysql --network bookmedik -e MYSQL_ROOT_PASSWORD=root -e MYSQL_USER=book_user -e MYSQL_PASSWORD=book_passwd -e MYSQL_DATABASE=bookmedik -d mariadb

docker cp GitHub/bookmedik/schema.sql book_sql:/tmp

docker exec book_sql bash -c 'mysql -u$MYSQL_USER -p$MYSQL_PASSWORD < /tmp/schema.sql'
~~~

Ahora vamos a crear un `Dockerfile` para crear una imagen que nos sirva la aplicación `Bookmedik`, para ello tendremos que crear un script que cambie las variables de entorno por las nuestras y cree la imagen.

* Este es el script:
~~~
mkdir bookmedik
cd bookmedik

nano variables.sh

#!/bin/bash
sed -i "s/$this->user=\"root\";/$this->user=\"$MYSQL_USER\";/g" /var/www/html/core/controller/Database.php
sed -i "s/$this->pass=\"\";/$this->pass=\"$MYSQL_PASSWORD\";/g" /var/www/html/core/controller/Database.php
sed -i "s/$this->host=\"localhost\";/$this->host=\"$DATABASE_SERVER\";/g" /var/www/html/core/controller/Database.php
sed -i "s/$this->ddbb=\"bookmedik\";/$this->ddbb=\"$MYSQL_DATABASE\";/g" /var/www/html/core/controller/Database.php
apache2ctl -D FOREGROUND

chmod +x variables.sh
~~~

* Este es el `Dokerfile`:
~~~
FROM debian
MAINTAINER Juan Antonio Reifs Ramirez "initiategnat9@gmail.com"

RUN apt-get update && apt-get install -y apache2 php php-mysql git && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN rm -r /var/www/html/* && git clone https://github.com/evilnapsis/bookmedik /var/www/html

ADD variables.sh /usr/local/bin

EXPOSE 80

ENV DATABASE_SERVER=book_sql MYSQL_ROOT_PASSWORD=root MYSQL_USER=book_user MYSQL_PASSWORD=book_passwd MYSQL_DATABASE=bookmedik

CMD ["variables.sh"]
~~~

* Explicación del `Dockerfile`:

	* **`FROM debian`:** Le decimos que la imagen base va a ser `debian:latest`
	* **`MANTEINER Juan Antonio Reifs Ramirez "initiategnat9@gmail.com"`:** Metadatos para saber quién ha creado la imagen
	* **`RUN apt-get update && apt-get install -y apache2 php php-mysql git && apt-get clean && rm -rf /var/lib/apt/lists/*`:** Este primer `RUN` actualiza la lista de paquetes de la imagen para posteriormente descargar los paquetes `apache2`, `php`, `php-mysql` y `git` y limpia los residuos que dejan las instalaciones.
	* **`RUN rm -r /var/www/html/* && git clone https://github.com/evilnapsis/bookmedik /var/www/html`:** Con este segundo `RUN` eliminamos todo el contenido del directorio `/var/www/html` (que es donde van a ir los archivos de `Bookmedik`) para más tarde clonar el [repositorio de Bookmedik](https://github.com/evilnapsis/bookmedik)
	* **`ADD variables.sh /usr/local/bin`:** Añadimos el script que hemos creado anteriormente a nuestra imagen en una ubicación que se encuentre en el `$PATH`, ya que después, al ejecutarla, no tendremos que poner ninguna ruta.
	* **`EXPOSE 80`:** Apartado informativo para especificar que esta imagen está escuchando en el puerto `80` de forma predeterminada.
	* **`ENV DATABASE_SERVER=book_sql MYSQL_ROOT_PASSWORD=root MYSQL_USER=book_user MYSQL_PASSWORD=book_passwd MYSQL_DATABASE=bookmedik`:** Variables de entorno predeterminadas para conectar con la base de datos.
	* **`CMD ["variables.sh"]`:** Le indicamos que tiene que ejecutar el script para cambiar las variables prdeterminadas de `Bookmedik`

Cuando lo tengamos todo listo, solo queda crear la imagen con el comando `docker build`
~~~
docker build -t juanan219/book_debian .

docker images
REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
juanan219/book_debian         latest              a7a19bca4040        17 minutes ago      297MB
[...]
~~~

Ahora que tenemos nuestro contenedor con la imagen de `mariadb` arrancado y nuestra imagen de `Bookmedik` creada, vamos a crear un contenedor con dicha imagen. Este contenedor va a tener un volumen que guarde los logs de `apache2` y va a estar en la misma red llamada `bookmedik` que nuestro contenedor `book_sql`
~~~
docker run --name book_debian -v apache_logs:/var/log/apache2 --network bookmedik -p 80:80 -d juanan219/book_debian
~~~

Como podemos ver, después de configurarlo todo, ya tenemos nuestro Bookmedik funcionando

![Captura 1](/Docker/Practica/1.png)

Ahora vamos a realizar la misma operación de creación de los contenedores, pero mediante un script de `docker-compose`. Este es el procemiento que he seguido:
~~~
nano docker-compose.yml

version: '3.1'

services:
  mariadb2:
    image: mariadb
    container_name: book_sql
    restart: always
    environment:
      [MYSQL_ROOT_PASSWORD=root,MYSQL_USER=book_user,MYSQL_PASSWORD=book_passwd,MYSQL_DATABASE=bookmedik]
    volumes:
      - ./mysql:/var/lib/mysql
  bookmedik:
    image: juanan219/book_debian
    container_name: book_debian
    restart: always
    ports:
      - 80:80
    volumes:
      - ./logs:/var/log/apache2

docker-compose run -d

cat schema.sql | docker exec -i book_sql /usr/bin/mysql -u book_user --password=book_passwd bookmedik
~~~

Ahora si nos metemos en la dirección de `loopback` (`127.0.0.1`) de nuestra máquina a través de un navegador nos aparecerá la aplicación de `Bookmedik`

![Captura 1](/Docker/Practica/1.png)

> [Repositorio de GitHub](https://github.com/Juanan219/)

## Tarea 2

Ahora vamos a lanzar la aplicación de Bookmedik con una imagen docker de `PHP`, más concretamente, lo lanzaré con la imagen `php:7.4-apache`. Vamos a partir del ejercicio anterior, pero haciendo las modificaciones oportunas, las cuales ire enumerando mediante las hago:

1. No usaremos el script `variables.sh`, ya que en la imagen docker de `php:7.4-apache` no podemos ejecutar ningún comando con `CMD`, por lo que eliminaremos el script del directorio `build_bookmedik` y modificaremos el fichero `Dockerfile`
~~~
rm variables.sh

nano Dockerfile 

FROM php:7.4-apache
MAINTAINER Juan Antonio Reifs Ramirez "initiategnat9@gmail.com"

RUN apt-get update && apt-get install -y git && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/evilnapsis/bookmedik /var/www/html

EXPOSE 80

ENV DATABASE_SERVER=book_sql MYSQL_ROOT_PASSWORD=root MYSQL_USER=book_user MYSQL_PASSWORD=book_passwd MYSQL_DATABASE=bookmedik
~~~

2. Vamos a realizar otra modificación en el fichero `Dockerfile` para poder instalar el paquete `mysqli`, el cual nos va a hacer falta para usar la base de datos `mariadb` que esta aplicación necesita. Con esta imagen, las extensiones php se instalan de una forma un tanto especial, por lo que añadiremos la siguiente línea al dockerfile
~~~
nano Dockerfile
[...]
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli
[...]
~~~

3. Como ya no usamos el script para cambiar las variables, deberemos copiar el fichero `Database.php` del [repositorio de `bookmedik`](https://github.com/evilnapsis/bookmedik) y lo modificaremos para que php pueda reconocer las variables de entorno que nosotros definimos en el `Dockerfile`
~~~
cp bookmedik/core/controller/Database.php Bookmedik-Tarea2/build_bookmedik/
nano Bookmedik-Tarea2/build_bookmedik/Database.php
[...]
$this->user=getenv("MYSQL_USER");$this->pass=getenv("MYSQL_PASSWORD");$this->host=getenv("DATABASE_SERVER");$this->ddbb=getenv("MYSQL_DATABASE");
[...]
~~~

4. Después de modificar el fichero `Database.php` vamos a modificar de nuevo el fichero `Dockerfile` para poder añadir un parámetro para poder agregar a nuestra imagen el fichero `Database.php` modificado y se sustituya por el original
~~~
nano Dockerfile
[...]
ADD Database.php /var/www/html/core/controller
[...]
~~~

El fichero `Dockerfile` deberá quedar de esta forma
~~~
FROM php:7.4-apache
MAINTAINER Juan Antonio Reifs Ramirez "initiategnat9@gmail.com"

RUN apt-get update && apt-get install -y git && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/evilnapsis/bookmedik /var/www/html
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

ADD Database.php /var/www/html/core/controller 

EXPOSE 80

ENV DATABASE_SERVER=book_sql MYSQL_ROOT_PASSWORD=root MYSQL_USER=book_user MYSQL_PASSWORD=book_passwd MYSQL_DATABASE=bookmedik
~~~

El fichero `Database.php` deberá quedar de esta forma
~~~
<?php
class Database {
        public static $db;
        public static $con;
        function Database(){
                $this->user=getenv("MYSQL_USER");$this->pass=getenv("MYSQL_PASSWORD");$this->host=getenv("DATABASE_SERVER");$this->ddbb=getenv("MYSQL_DATABASE");
        }

        function connect(){
                $con = new mysqli($this->host,$this->user,$this->pass,$this->ddbb);
                $con->query("set sql_mode=''");
                return $con;
        }

        public static function getCon(){
                if(self::$con==null && self::$db==null){
                        self::$db = new Database();
                        self::$con = self::$db->connect();
                }
                return self::$con;
        }

}
?>
~~~

Ahora procederemos a crear la imagen
~~~
docker build -t juanan219/bookmedik .

docker images
REPOSITORY            TAG                 IMAGE ID            CREATED             SIZE
juanan219/bookmedik   latest              f9bd125bde93        12 seconds ago      457MB
[...]
~~~

Por último modificaremos el fichero `docker-compose.yml` para que lance tanto el contenedor de la imagen `mariadb` como el de la imagen que acabamos de crear
~~~
version: '3.1'

services:
  mariadb:
    image: mariadb
    container_name: book_sql
    restart: always
    environment:
      [MYSQL_ROOT_PASSWORD=root,MYSQL_USER=book_user,MYSQL_PASSWORD=book_passwd,MYSQL_DATABASE=bookmedik]
    volumes:
      - ./mysql:/var/lib/mysql
  bookmedik:
    image: juanan219/bookmedik
    container_name: book_php   
    restart: always
    ports:
      - 80:80
    volumes:
      - ./logs:/var/log/apache2
~~~

Lanzamos el `docker-compose` y comprobamos si funciona nuestra aplicación
~~~
docker-compose up -d
Creating network "bookmedik-tarea2_default" with the default driver
Creating book_php ... done
Creating book_sql ... done
~~~

Como podemos ver, si accedemos desde nuestra máquina anfitriona a la dirección de `loopback` (`127.0.0.1`) e introducimos el usuario y la contraseña `admin/admin` podemos acceder a nuestro `bookmedik` sobre una imagen docker `php:7.4-apache`

![Captura 2](/Docker/Practica/2.png)

> [Repositorio de GitHub](https://github.com/Juanan219/Bookmedik-Tarea2)

### Tarea 3

Ahora vamos a usar tres contenedores diferentes para separar servicios:

* El primero va a tener una imagen `nginx`, el cual va a servir el contenido estático.

* El segundo va a tener una imagen `php:7.4-fpm`, el cual se va a encargar de gestionar todo el contenido php

* El tercero va a tener una imagen `mariadb`, el cual se va a encargar de almacenar la base de datos de nuestro `bookmedik`

1. Vamos a crear nuestra imagen de `php:7.4-fpm` con el módulo de `mysqli` activado, ya que sino no podemos acceder a la base de datos. Para crear esta imagen he creado un directorio que contiene el siguiente fichero `Dockerfile`:
~~~
mkdir build_php
nano build_php/Dockerfile

FROM php:7.4-fpm

MAINTAINER Juan Antonio Reifs Ramirez "initiategnat9@gmail.com"

RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

ENV DATABASE_SERVER=book_sql MYSQL_ROOT_PASSWORD=root MYSQL_USER=book_user MYSQL_PASSWORD=book_passwd MYSQL_DATABASE=bookmedik
~~~

2. Creamos la imagen
~~~
docker build -t juanan219/php_mysqli

docker images
REPOSITORY             TAG                 IMAGE ID            CREATED             SIZE
juanan219/php_mysqli   latest              2725316da685        18 minutes ago      405MB
~~~

3. Creamos un fichero llamado `default.conf` que va a servir para que `nginx` sirva nuestra aplicación
~~~
nano default.conf

server {
    index index.html;
    server_name bookmedik.local;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /bookmedik;

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass book_php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
~~~

4. Copiamos un directorio de `bookmedik` con el archivo `bookmedik/core/controller/Database.php` editado (como vimos en la práctica anterior) y generamos el siguiente docker-compose.yml
~~~
nano docker-compose.yml

version: '3.1'

services:
  nginx:
    image: nginx
    container_name: book_nginx
    volumes:
      - ./logs:/var/log/nginx
      - ./bookmedik:/bookmedik
      - ./default.conf:/etc/nginx/conf.d/default.conf
    ports:
      - 80:80
    restart: always
    environment:
      - DATABASE_SERVER=book_sql
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_USER=book_user
      - MYSQL_PASSWORD=book_passwd
      - MYSQL_DATABASE=bookmedik

  php-fpm:
    image: juanan219/php_mysqli
    container_name: book_php
    volumes:
      - ./bookmedik:/bookmedik
    restart: always

  mysql:
    image: mariadb
    container_name: book_sql
    volumes:
      - ./mysql:/var/lib/mysql
      - ./bookmedik/schema.sql:/opt/schema.sql
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_USER=book_user
      - MYSQL_PASSWORD=book_passwd
      - MYSQL_DATABASE=bookmedik
    restart: always
~~~

5. Iniciamos el script y comprobamos que podemos entrar
~~~
docker-compose up -d
~~~

![Captura 3](/Docker/Practica/3.png)

> [Repositorio de GitHub](https://github.com/Juanan219/Bookmedik-Tarea3)

#### Tarea 5

Por último vamos a instalar un CMS de PHP con una imagen en DockerHub creando los contenedores necesarios para instalarla. En mi caso he escogido `joomla`. He hecho un script de `docker-compose` para ejecutar los dos contenedores que necesita joomla, uno de ellos es una imagen `mariadb` y la otra es una imagen `joomla`
~~~
nano docker-compose.yml

version: '3.1'

services:
  mariadb:
    image: mariadb
    container_name: joomla_sql
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=root
      - MYSQL_USER=joomla_user
      - MYSQL_PASSWORD=joomla_passwd
      - MYSQL_DATABASE=joomla_db
  joomla:
    image: joomla
    container_name: joomla
    restart: always
    ports:
      - 80:80
    environment:
      - JOOMLA_DB_HOST=joomla_sql
      - JOOMLA_DB_USER=joomla_user
      - JOOMLA_DB_PASSWORD=joomla_passwd
      - JOOMLA_DB_NAME=joomla_db
~~~

Ahora simplemente hacemos un `docker-compose up -d` y se crean los dos contenedores
~~~
docker-compose up -d
Creating network "cms-php-tarea5_default" with the default driver
Creating joomla     ... done
Creating joomla_sql ... done
~~~

Comprobamos que podemos entrar

![Captura 4](/Docker/Practica/4.png)

Una vez que hayamos terminado la configuración del sitio nos podemos meter en la página de administración (iniciando sesión con el usuario que hemos configurado)

![Captura 5](/Docker/Practica/5.png)

Esta es la página de ejemplo de Joomla

![Captura 6](/Docker/Practica/6.png)

> [Repositorio de GitHub](https://github.com/Juanan219/CMS-PHP-Tarea5)
