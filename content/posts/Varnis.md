---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-19
linktitle: Varnish
type:
- post
- posts
title: Rendimiento de servidor Web con caché Varnish
weight: 10
series:
- Hugo 101
images:
tags:
  - Varnish
  - Ningx
  - Caché
  - Servidor
  - Web
  - Rendimiento
---

Según las pruebas de rendimiento que se han realizado con el comando `ab` a varias configuraciones de servidores webs sirviendo un Wordpress, la mejor configuraciónm para este tipo de escenarios es `PHP-FPM (Socket Unix) + NGINX`.

El comando usado para las pruebas es el siguiente:
~~~
ab -t 10 -c 200 -k http://172.22.x.x/wordpress/index.php
~~~

## Aumento de rendimiento en la ejecución de scripts PHP

* **Tarea 1:**

Vamos a configurar una máquina con la configuración ganadora: `PHP-FPM (Socket Unix) + NGINX`. Para ello vamos a ejecutar una [receta de ansible](https://github.com/josedom24/ansible_nginx_fpm_php) y vamos a terminar la configuración del sitio.

Primero instalamos `ansible` y `git`
~~~
sudo apt-get update
sudo apt-get install ansible
sudo apt-get install git
~~~

Clonamos el repositorio
~~~
mkdir GitHub
cd GitHub/
git clone https://github.com/josedom24/ansible_nginx_fpm_php
~~~

He creado una máquina en `vagrant` con la ip `192.168.1.113` y he modificado el fichero hosts del repositorio que acabo de clonar y he cambiadp la IP que trae configurada, por la ip de mi máquina
~~~
nano hosts

[servidores_web]
nodo1 ansible_ssh_host=172.22.201.58 ansible_python_interpreter=/usr/bin/python3
~~~

También he cambiado el usuario remoto y he añadido la clave de vagrant a `ssh-agent`
~~~
nano ansible.cfg

[defaults]
inventory = hosts
remote_user = vagrant
host_key_checking = False

ssh-add .vagrant/machines/server/virtualbox/private_key
~~~
ab -t 10 -c 200 -k http:/127.0.0.1/wordpress/index.php
Ejecutamos el playbook y esperamos a que termine todo el proceso
~~~
ansible-playbook site.yaml
~~~

Esta es la [configuración de wordpewss](https://www.youtube.com/watch?v=DxB-5gYjDEI)

* **Tarea 2:**

Ahora vamos a realizar las pruebas de rendimiento desde la misma máquina, es decir, vamos a ejecutar instrucciones similares a:
~~~
ab -t 10 -c 200 -k http:/127.0.0.1/wordpress/index.php
~~~

Pero antes de usar ese comando deberemos instalar el paquete en el que se encuentra, en este caso es `apache2-utils`
~~~
sudo apt-get install apache2-utils
~~~

* Vamos a realizar dicha prueba con diferentes valores de concurrencia:

	* **50:**
~~~
ab -t 10 -c 50 -k http:/127.0.0.1/wordpress/index.php
[...]
Requests per second:    115.25 [#/sec] (mean)
[...]
~~~

	* **100:**
~~~
ab -t 10 -c 100 -k http://127.0.0.1/wordpress/index.php
[...]
Requests per second:    127.95 [#/sec] (mean)
[...]
~~~

	* **200:**
~~~
ab -t 10 -c 200 -k http://127.0.0.1/wordpress/index.php
[...]
Requests per second:    9519.44 [#/sec] (mean)
[...]
~~~

	* **250:**
~~~
ab -t 10 -c 250 -k http://127.0.0.1/wordpress/index.php
[...]
Requests per second:    8189.23 [#/sec] (mean)
[...]
~~~

	* **500:**
~~~
ab -t 10 -c 500 -k http://127.0.0.1/wordpress/index.php
[...]
Requests per second:    9385.39 [#/sec] (mean)
[...]
~~~

La media de las respuestas por segundo es de 5444,402.

* **Tarea 3:**

Ahora vamos a configurar la `caché Varnish`, la cual es un proxy inverso que estará escuchando en el puerto 80 y se va a comunicar con el servidor web por el puerto 8080. Para instalar `Varnish` simplemente lo podemos hacer con apt
~~~
sudo apt-get install varnish
~~~

Una vez instalado `varnish` en nuestra máquina, editaremos el fichero `/etc/default/varnish` para configurar el demonio y que escuche desde el puerto 80 por la interfaz pública del servidor.
~~~
sudo nano /etc/default/varnish
[...]
DAEMON_OPTS="-a :80 \
             -T localhost:6082 \
             -f /etc/varnish/default.vcl \
             -S /etc/varnish/secret \
             -s malloc,1G"
[...]
~~~

Ahora modificaremos la unidad de `systemd` para que `varnish` arranque en el puerto 80, para ello vamos a editar el fichero `/lib/systemd/system/varnish.service` y modificamos al siguiente línea:
~~~
ExecStart=/usr/sbin/varnishd -j unix,user=vcache -F -a :80 -T localhost:6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -s malloc,1G
~~~

Por último modificamos el fichero `/etc/varnish/default.vcl` para que este coja el `puerto 8080`, en el cual vamos a poner a escucha a nuestro servidor `nginx`
~~~
sudo nano /etc/varnish/default.vcl
[...]
backend default {
    .host = "127.0.0.1";
    .port = "8080";
}
[...]
~~~

Y reiniciamos tanto `varnish` como `systemd`
~~~
sudo systemctl daemon-reload
sudo systemctl restart varnish
~~~

Ahora vamos a modificar nuestro virtualhost, lo pondremos a escuchar en el `puerto 8080` y recargamos el servicio
~~~
sudo nano /etc/nginx/sites-available/default
server {
        listen 8080 ;
[...]

sudo systemctl restart nginx.service
~~~

Comprobamos que varnish está escuchando en el `puerto 80` y nginx está en el `puerto 8080`
~~~
sudo netstat -putan
[...]
tcp        0      0 0.0.0.0:8080            0.0.0.0:*               LISTEN      700/nginx: master p 
tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN      378/varnishd
[...]
~~~

Ahora que lo tenemos todo funcionando, vamos a volver a realizar las mismas pruebas de concurrencia de antes y vamos a comparar los resultados

* **50:**
~~~
ab -t 10 -c 50 -k http://127.0.0.1/
[...]
Requests per second:    17403.75 [#/sec] (mean)
[...]
~~~

* **100:**
~~~
ab -t 10 -c 100 -k http://127.0.0.1/
[...]
Requests per second:    16256.04 [#/sec] (mean)
[...]
~~~

* **200:**
~~~
ab -t 10 -c 200 -k http://127.0.0.1/
[...]
Requests per second:    14731.21 [#/sec] (mean)
[...]
~~~

* **250:**
~~~
ab -t 10 -c 250 -k http://127.0.0.1/
[...]
Requests per second:    15370.86 [#/sec] (mean)
[...]
~~~

La media de peticiones con `varnish` es de 15940,465 peticiones por segundo, mientras que sin él la media era de 5444,402 peticiones por segundo.

Si comprobamos el fichero `/var/log/nginx/access.log` podemos ver que sólo se registra en el log la primera petición, ya que las siguientes peticiones las gestiona varnish.
~~~
sudo tail /var/log/nginx/access.log
[...]
127.0.0.1 - - [19/Feb/2021:09:39:27 +0000] "GET /wordpress/index.php HTTP/1.1" 301 5 "-" "ApacheBench/2.3"
127.0.0.1 - - [19/Feb/2021:09:39:36 +0000] "GET / HTTP/1.1" 200 3488 "-" "ApacheBench/2.3"
127.0.0.1 - - [19/Feb/2021:09:41:49 +0000] "GET / HTTP/1.1" 200 3488 "-" "ApacheBench/2.3"
127.0.0.1 - - [19/Feb/2021:09:46:56 +0000] "GET / HTTP/1.1" 200 3488 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36"
127.0.0.1 - - [19/Feb/2021:09:47:06 +0000] "GET /favicon.ico HTTP/1.1" 404 199 "http://www.juanan.es/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36"
~~~

Los registros de `varnish` se guardan en el fichero `/var/log/varnish/varnishncsa.log`
~~~
sudo tail /var/log/varnish/varnishncsa.log
127.0.0.1 - - [19/Feb/2021:09:42:55 +0000] "GET http://127.0.0.1/ HTTP/1.0" 200 8667 "-" "ApacheBench/2.3"
127.0.0.1 - - [19/Feb/2021:09:42:55 +0000] "GET http://127.0.0.1/ HTTP/1.0" 200 8667 "-" "ApacheBench/2.3"
127.0.0.1 - - [19/Feb/2021:09:42:55 +0000] "GET http://127.0.0.1/ HTTP/1.0" 200 8667 "-" "ApacheBench/2.3"
127.0.0.1 - - [19/Feb/2021:09:42:55 +0000] "GET http://127.0.0.1/ HTTP/1.0" 200 8667 "-" "ApacheBench/2.3"
127.0.0.1 - - [19/Feb/2021:09:42:55 +0000] "GET http://127.0.0.1/ HTTP/1.0" 200 8667 "-" "ApacheBench/2.3"
127.0.0.1 - - [19/Feb/2021:09:42:55 +0000] "GET http://127.0.0.1/ HTTP/1.0" 200 8667 "-" "ApacheBench/2.3"
127.0.0.1 - - [19/Feb/2021:09:42:55 +0000] "GET http://127.0.0.1/ HTTP/1.0" 200 8667 "-" "ApacheBench/2.3"
172.22.4.124 - - [19/Feb/2021:09:46:56 +0000] "GET http://www.juanan.es/ HTTP/1.1" 200 3476 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36"
172.22.4.124 - - [19/Feb/2021:09:47:06 +0000] "GET http://www.juanan.es/favicon.ico HTTP/1.1" 404 188 "http://www.juanan.es/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36"
172.22.4.124 - - [19/Feb/2021:09:47:40 +0000] "GET http://www.juanan.es/ HTTP/1.1" 200 3476 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.182 Safari/537.36"
~~~
