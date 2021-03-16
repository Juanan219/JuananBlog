---
author:
  name: "Juan Antonio Reifs"
date: 2021-03-16
linktitle: Practica VPN
type:
- post
- posts
title: Practica VPN
weight: 10
series:
- Hugo 101
images:
tags:
  - Practica
  - VPN
  - EasyRSA
  - OpenVPN
  - OpenSSL
---

## Tarea1: VPN de acceso remoto con OpenVNP y certificados x509

En esta tarea vamos a montar una `VPN` con `OpenVPN` con certificados x509 generados usando la herramienta `easy-rsa`, para ello vamos a hacer el uso de 3 máquinas:

1. Mi máquina personal (Cliente)
2. Servidor (Servidor VPN)
3. Máquina de la red interna (Máquina a la que nos vamos a conectar)

### Instalación de las herramientas

Para realizar esta tarea vamos a necesitar instalar `OpenVPN` tanto en mi máquina como en el servidor
~~~
juanan@juananpc:~$ sudo apt-get install openvpn

debian@vpn-server:~$ sudo apt-get install openvpn
~~~

También necesitaremos descargar la herramienta `easy-rsa` de su [repositorio oficial de github](https://github.com/OpenVPN/easy-rsa) para ello necesitaremos el paquete `git`
~~~
debian@vpn-server:~$ sudo apt-get install git
debian@vpn-server:~$ git clone https://github.com/OpenVPN/easy-rsa.git

juanan@juananpc:~$ sudo apt-get install git
juanan@juananpc:~/GitHub$ git clone https://github.com/OpenVPN/easy-rsa.git
~~~

Ahora que tenemos todo listo para comenzar, vamos a generar las claves tanto del servidor como del cliente.

### Generación de claves

Vamos a necesitar las siguientes claves:

* **Servidor:**

	* Parámetros `Diffie-Hellman`
	* Clave privada de la CA
	* Certificado de la CA
	* Clave privada del servidor VPN
	* Certificado del servidor VPN

* **Cliente:**

	* Certificado de la CA
	* Clave privada del cliente
	* Certificado del cliente frimado por la CA

#### Servidor

Comenzaremos generando las claves del servidor, así que para comenzar a generarlas deberemos inicializar nuestra herramienta `easy-rsa` de la siguiente manera
~~~
debian@vpn-server:~ cd easy-rsa/easyrsa3
debian@vpn-server:~/easy-rsa/easyrsa3$ ./easyrsa init-pki
~~~

Con esta opción se nos habŕa creado un directorio llamado `pki` en el cual se van a ir añadiendo todas las claves, certificados y peticiones de estos que vayamos generando.

Definimos las variables, para ello copiamos el fichero `vars.example` y lo llamamos `vars` para más tarde editarlo, descomentar las siguientes líneas y lo editamos a nuestra conveniencia.
~~~
debian@vpn-server:~/easy-rsa/easyrsa3$ cp vars.example vars

nano vars
[...]
set_var EASYRSA_REQ_COUNTRY     "ES"
set_var EASYRSA_REQ_PROVINCE    "Sevilla"
set_var EASYRSA_REQ_CITY        "Dos Hermanas"
set_var EASYRSA_REQ_ORG         "IESGN"
set_var EASYRSA_REQ_EMAIL       "initiategnat9@gmail.com"
set_var EASYRSA_REQ_OU          "Informatica"
[...]
~~~

Generamos el parámetro `Diffie-Hellman`, el cual se almacena en `~/easy-rsa/easyrsa3/pki/dh.pem`
~~~
debian@vpn-server:~/easy-rsa/easyrsa3$ ./easyrsa gen-dh
~~~

Generamos la clave y el cerficado de la CA, el certificado `ca.crt` se almacena en  `~/easy-rsa/easyrsa3/pki/ca.crt` y la clave privada `ca.key` se almacena en `~/easy-rsa/easyrsa3/pki/private/ca.key`
~~~
debian@vpn-server:~/easy-rsa/easyrsa3$ ./easyrsa build-ca nopass
~~~

Generamos la clave y la petición del certificado del servidor, la petición del certificado `servidor.req` se almacena en `~/easy-rsa/easyrsa3/pki/reqs/servidor.req` y la clave privada `servidor.key` se almacena en `~/easy-rsa/easyrsa3/pki/private/servidor.key`
~~~
debian@vpn-server:~/easy-rsa/easyrsa3$ ./easyrsa gen-req servidor nopass
~~~

Ahora vamos a generar el certificado firmando la petición del certificado, el certificado `servidor.crt` se almacena en `~/easy-rsa/easyrsa3/pki/issued/servidor.crt`
~~~
debian@vpn-server:~/easy-rsa/easyrsa3$ ./easyrsa sign-req server servidor
~~~

#### Cliente

Ahora pasamos a la generación de claves del cliente, las uales las vamos a generar de la misma forma, pero con la diferencia de que la petición del certificado se lo tendremos que hacer llegar de alguna forma a la CA.

Inicializamos la herramienta
~~~
juanan@juananpc:~/GitHub/easy-rsa/easyrsa3$ ./easyrsa init-pki
~~~

Generamos la clave privada y la petición del certificado
~~~
juanan@juananpc:~/GitHub/easy-rsa/easyrsa3$ ./easyrsa gen-req cliente nopass
~~~

Pasamos la petición del certificado al servidor, lo generamos y se lo devolvemos al cliente
~~~
juanan@juananpc:~/GitHub/easy-rsa/easyrsa3$ scp pki/reqs/cliente.req debian@172.22.201.68:/home/debian/easy-rsa/easyrsa3/pki/reqs

debian@vpn-server:~/easy-rsa/easyrsa3$ ./easyrsa sign-req client cliente

debian@vpn-server:~$ scp easy-rsa/easyrsa3/pki/issued/cliente.crt juanan@172.22.4.124:/home/juanan/GitHub/easy-rsa/easyrsa3/pki
~~~

### Configuración de las máquinas

Ahora vamos a copiar las claves del servidor al directorio `/etc/openvpn/keys`
~~~
debian@vpn-server:~$ sudo mkdir /etc/openvpn/keys
debian@vpn-server:~/easy-rsa/easyrsa3$ sudo cp pki/ca.crt /etc/openvpn/keys/
debian@vpn-server:~/easy-rsa/easyrsa3$ sudo cp pki/private/ca.key /etc/openvpn/keys/
debian@vpn-server:~/easy-rsa/easyrsa3$ sudo cp pki/issued/servidor.crt /etc/openvpn/keys/
debian@vpn-server:~/easy-rsa/easyrsa3$ sudo cp pki/private/servidor.key /etc/openvpn/keys/
debian@vpn-server:~/easy-rsa/easyrsa3$ sudo cp pki/dh.pem /etc/openvpn/keys/
~~~

Pasamos las claves necesarias del servidor al cliente y realizamos el mismo proceso de copiarlas al directorio `/etc/openvpn/keys`
~~~
debian@vpn-server:~/easy-rsa/easyrsa3$ scp pki/ca.crt  juanan@172.22.4.124:/home/juanan/GitHub/easy-rsa/easyrsa3/pki
juanan@juananpc:~/GitHub/easy-rsa/easyrsa3$ sudo mkdir /etc/openvpn/keys
juanan@juananpc:~/GitHub/easy-rsa/easyrsa3$ sudo cp pki/ca.crt /etc/openvpn/keys/
juanan@juananpc:~/GitHub/easy-rsa/easyrsa3$ sudo cp pki/cliente.crt /etc/openvpn/keys/
juanan@juananpc:~/GitHub/easy-rsa/easyrsa3$ sudo cp pki/private/cliente.key /etc/openvpn/keys/
~~~

#### Configuración del servidor

Para configurar `OpenVPN`, deberemos crear un fichero `.conf` en el directorio `/etc/openvpn`, el cual va a contener la configuración de nuestro servidor
~~~
debian@vpn-server:~$ sudo nano /etc/openvpn/servidor.conf

#Dispositivo de túnel
dev tun

#Direcciones IP virtuales

server 10.99.99.0 255.255.255.0

#subred local
push “route 192.168.100.0 255.255.255.0”

# Rol de servidor
tls-server

#Parámetros Diffie-Hellman
dh /etc/openvpn/keys/dh.pem

#Certificado de la CA
ca /etc/openvpn/keys/ca.crt

#Certificado local
cert /etc/openvpn/keys/server.crt

#Clave privada local
key /etc/openvpn/keys/server.key

#Activar la compresión LZO
comp-lzo

#Detectar caídas de la conexión
keepalive 10 60

#Archivo de log
log /var/log/office.log

#Nivel de información
verb 3
~~~

Podemos comprobar que ha salido bien si al arrancar el servicio de `openvpn` con la configuración actual, se nos añade una tarjeta de red `tun0`
~~~
debian@vpn-server:~$ sudo openvpn /etc/openvpn/servidor.conf

debian@vpn-server:~$ ip a
[...]
4: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/none 
    inet 10.99.99.1 peer 10.99.99.2/32 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::b69e:f447:a995:44f3/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
~~~

#### Configuración del cliente

Creamos otro fichero de configyración llamado `.conf` en el directorio `/etc/openvpn` con nuestra configuración
~~~
juanan@juananpc:~/GitHub/easy-rsa/easyrsa3$ sudo nano /etc/openvpn/cliente.conf

#Dispositivo de túnel
dev tun

#Direcciones remota
remote 172.22.201.68

#Aceptar directivas del extremo remoto
pull

# Rol de cliente
tls-client

#Certificado de la CA
ca /etc/openvpn/ca.crt

#Certificado local
cert /etc/openvpn/client1.crt

#Clave privada local
key /etc/openvpn/client1.key

#Activar la compresión LZO
comp-lzo

#Detectar caídas de la conexión
keepalive 10 60

#Nivel de información
verb 3
~~~

Comprobamos que tenemos conexión a nuestro cliente de la red `lan`, para ello deberemos encender los dos procesos de `openvpn`, tanto el del cliente como el del servidor
~~~
debian@vpn-server:~$ sudo openvpn /etc/openvpn/servidor.conf

juanan@juananpc:~/GitHub/easy-rsa$ sudo openvpn /etc/openvpn/cliente.conf

juanan@juananpc:~/GitHub/easy-rsa$ ping 192.168.100.10
PING 192.168.100.10 (192.168.100.10) 56(84) bytes of data.
64 bytes from 192.168.100.10: icmp_seq=6 ttl=63 time=4.91 ms
[...]
--- 192.168.100.10 ping statistics ---
9 packets transmitted, 4 received, 55.5556% packet loss, time 81ms
rtt min/avg/max/mdev = 3.601/4.045/4.912/0.509 ms
~~~

Ahora que sabemos que tenemos conexión, vamos a conectarnos por `ssh` a dicha máquina:
~~~
juanan@juananpc:~$ ssh debian@192.168.100.10
Linux lan 4.19.0-11-cloud-amd64 #1 SMP Debian 4.19.146-1 (2020-09-17) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Tue Mar  9 11:37:21 2021 from 10.99.99.2
debian@lan:~$
~~~

> El parámetro `Diffie-Hellman` usado anteriormente es una forma de hacer que las dos partes involucradas en una transacción SSL acuerden un secreto compartido en un canal inseguro.

## Tarea 2: VPN de sitio a sitio con OpenVPN y certificados x509

Configura una conexión sitio a sitio entre dos equipos del cloud:

* Cada equipo estará conectado a dos redes, una de ellas en común

* Para la autenticación de los extremos se usarán obligatoriamente certificados digitales, que se generarán utilizando openssl y se almacenarán en el directorio /etc/openvpn, junto con con los parámetros Diffie-Helman y el certificado de la propia Autoridad de Certificación.

* Se utilizarán direcciones de la red 10.99.99.0/24 para las direcciones virtuales de la VPN.

* Tras el establecimiento de la VPN, una máquina de cada red detrás de cada servidor VPN debe ser capaz de acceder a una máquina del otro extremo.

Ahora vamos a realizar una conexión sitio a sitio con `OpenVPN`, con lo cual vamos a tener 2 redes y 4 máquinas:

* Red 1:
	* Server VPN 1 (conectado a red externa y red VPN 1)
	* Cliente VPN 1 (conectado a la red VPN 1)

* Red 2:
	* Server VPN 2 (conectado a red externa y red VPN 2)
	* Cliente VPN 2 (conectado a la red VPN 2)

En esta configuración vamos a poner el `Servidor VPN 1` como servidor y el `Servidor VPN 2` como cliente de esta conexión.

### Servidor VPN 1

* Instalamos `git` y `OpenVPN` y clonamos el [repositorio de `easy-rsa`](https://github.com/OpenVPN/easy-rsa.git)
~~~
debian@vpn1:~$ sudo apt-get update

debian@vpn1:~$ sudo apt-get install git openvpn

debian@vpn1:~$ git clone https://github.com/OpenVPN/easy-rsa.git
~~~

* Configuramos las variables de entorno
~~~
debian@vpn1:~$ cd easy-rsa/easyrsa3/

debian@vpn1:~/easy-rsa/easyrsa3$ cp vars.example vars

debian@vpn1:~/easy-rsa/easyrsa3$ nano vars
[...]
set_var EASYRSA_REQ_COUNTRY     "ES"
set_var EASYRSA_REQ_PROVINCE    "Sevilla"
set_var EASYRSA_REQ_CITY        "Dos Hermanas"
set_var EASYRSA_REQ_ORG         "Informatica"
set_var EASYRSA_REQ_EMAIL       "initiategnat9@gmail.com"
set_var EASYRSA_REQ_OU          "servervpn1"
[...]
~~~


* Generamos las claves necesarias
~~~
debian@vpn1:~/easy-rsa/easyrsa3$ ./easyrsa init-pki

debian@vpn1:~/easy-rsa/easyrsa3$ ./easyrsa build-ca nopass

debian@vpn1:~/easy-rsa/easyrsa3$ ./easyrsa gen-req server nopass

debian@vpn1:~/easy-rsa/easyrsa3$ ./easyrsa sign-req server server

debian@vpn1:~/easy-rsa/easyrsa3$ ./easyrsa gen-dh
~~~

* Creamos el directorio `/etc/openvpn/keys` y copiamos todas las claves generadas anteriormente a ese directorio para simplificar la configuración que vamos a realizar posteriormente.
~~~
debian@vpn1:~/easy-rsa/easyrsa3$ sudo mkdir /etc/openvpn/keys
debian@vpn1:~/easy-rsa/easyrsa3$ sudo cp pki/ca.crt /etc/openvpn/keys/
debian@vpn1:~/easy-rsa/easyrsa3$ sudo cp pki/private/server.key /etc/openvpn/keys/
debian@vpn1:~/easy-rsa/easyrsa3$ sudo cp pki/dh.pem /etc/openvpn/keys/
debian@vpn1:~/easy-rsa/easyrsa3$ sudo cp pki/issued/server.crt /etc/openvpn/keys/

debian@vpn1:~/easy-rsa/easyrsa3$ ls /etc/openvpn/keys/
ca.crt  dh.pem  server.crt  server.key
~~~

* Creamos el fichero `/etc/openvpn/server.conf` y configuramos nuestra conexión VPN de punto a punto.
~~~
debian@vpn1:~/easy-rsa/easyrsa3$ sudo nano /etc/openvpn/server.conf

# nombre de la interfaz
dev tun

# Direcciones IP virtuales
ifconfig 10.99.99.1 10.99.99.2

# Subred eth1 de la maquina destino
route 192.168.101.0 255.255.255.0

# Rol de Servidor
tls-server

# Parámetros Diffie-Hellman
dh /etc/openvpn/keys/dh.pem

# #Certificado de la CA
ca /etc/openvpn/keys/ca.crt

# Certificado Servidor
cert /etc/openvpn/keys/server.crt

# Clave privada servidor
key /etc/openvpn/keys/server.key

# Compresión LZO
comp-lzo

# Tiempo de vida
keepalive 10 60

# Fichero de log
log /var/log/servidor.log

# Nivel de Depuración
verb 6
~~~

Ahora solo queda completar la configuración para que las máquinas de la red `VPN1` puedan acceder al exterior
~~~
debian@vpn1:~/easy-rsa/easyrsa3$ sudo su -

root@vpn1:~# echo 1 > /proc/sys/net/ipv4/ip_forward

root@vpn1:~# iptables -t nat -A POSTROUTING -o eth0 -s 192.168.100.0/24 -j MASQUERADE
~~~

### Servidor VPN 2

Ahora vamos a pasar a la configuración del servidor vpn 2, el cual actuará como cliente.

* Realizamos la configuración necesaria para las máquinas de nuestra red se conecten con el exterior
~~~
debian@vpn2:~$ sudo su -

root@vpn2:~# echo 1 > /proc/sys/net/ipv4/ip_forward

root@vpn2:~# iptables -t nat -A POSTROUTING -o eth0 -s 192.168.101.0/24 -j MASQUERADE
~~~

* Generamos las claves necesarias
~~~
debian@vpn2:~/easy-rsa/easyrsa3$ ./easyrsa init-pki

debian@vpn2:~/easy-rsa/easyrsa3$ ./easyrsa gen-req cliente nopass
~~~

* Pasamos la petición de certificado a nuestro servidor vpn `vpn1` para generar el certificado
~~~
debian@vpn2:~/easy-rsa/easyrsa3$ scp pki/reqs/cliente.req debian@192.168.1.62:/home/debian/easy-rsa/easyrsa3/pki/reqs/

debian@vpn1:~/easy-rsa/easyrsa3$ ./easyrsa sign-req client cliente

debian@vpn1:~/easy-rsa/easyrsa3$ scp pki/issued/cliente.crt debian@192.168.1.82:/home/debian/easy-rsa/easyrsa3/pki/cliente.crt
~~~

* Pasamos al cliente `vpn2` el certificado de nuestra CA
~~~
debian@vpn1:~/easy-rsa/easyrsa3$ scp pki/ca.crt debian@192.168.1.82:/home/debian/easy-rsa/easyrsa3/pki
~~~ 

* Copiamos las claves en el directorio `/etc/openvpn/keys`
~~~
debian@vpn2:~/easy-rsa/easyrsa3$ sudo mkdir /etc/openvpn/keys
debian@vpn2:~/easy-rsa/easyrsa3$ sudo cp pki/ca.crt /etc/openvpn/keys/
debian@vpn2:~/easy-rsa/easyrsa3$ sudo cp pki/private/cliente.key /etc/openvpn/keys/
debian@vpn2:~/easy-rsa/easyrsa3$ sudo cp pki/cliente.crt /etc/openvpn/keys/
~~~

* Creamos el fichero de configuración para el cliente
~~~
debian@vpn2:~/easy-rsa/easyrsa3$ nano /etc/openvpn/cliente.conf

# nombre de la interfaz
dev tun

# Direcciones IP virtuales
ifconfig 10.99.99.2 10.99.99.1

#Ip eth0 servidor
remote 192.168.1.62

# Subred eth1 de la maquina destino
route 192.168.100.0 255.255.255.0

# Rol de Servidor
tls-client

# #Certificado de la CA
ca /etc/openvpn/keys/ca.crt

# Certificado Servidor
cert /etc/openvpn/keys/cliente.crt

# Clave privada servidor
key /etc/openvpn/keys/cliente.key

# Compresión LZO
comp-lzo

# Tiempo de vida
keepalive 10 60

# Fichero de log
log /var/log/cliente.log

# Nivel de Depuración
verb 6
~~~

## Tarea 3: Servidor VPN en Dulcinea

Ahora vamos a crear un servidor VPN en nuestra máquina del cloud `Dulcinea`. Para ello vamos a realizar los mismos pasos iniciales que con las anteriores máquinas. Primero descargaremos las herramientas necesarias, después generaremos las claves necesarias tanto del servidor como del cliente y después crearemos los ficheros de configuración. Aquí están los ficheros de congfiguración tanto de dulcinea como de mi máquina cliente.

### Fichero de configuración de Dulcinea
~~~
# nombre de la interfaz
dev tun

# Direcciones IP virtuales
ifconfig 10.99.99.1 10.99.99.2

# Rol de Servidor
tls-server

# Parámetros Diffie-Hellman
dh /etc/openvpn/keys/dh.pem

# Certificado de la CA
ca /etc/openvpn/keys/ca.crt

# Certificado de dulcinea
cert /etc/openvpn/keys/dulcinea.crt

# Clave de dulcinea
key /etc/openvpn/keys/dulcinea.key

# Activar la compresión LZO
comp-lzo

# Detectar caidas de la conexión
keepalive 10 60

# Archivo de log
log /var/log/openvpn/server.log

# Nivel de información
verb 3
~~~

### Fichero de configuración de mi máquina cliente
~~~
# Dispositivo de túnel
dev tun

# Direcciones de IP virtuales
ifconfig 10.99.99.2 10.99.99.1

# Dirección IP del servidor
remote 172.22.200.100

# Red remota
route 10.0.1.0 255.255.255.0
route 10.0.2.0 255.255.255.0

# Rol de cliente
tls-client

# Certificado de la CA
ca /etc/openvpn/keys/ca.crt

# Certificado del cliente
cert /etc/openvpn/keys/cliente.crt

# Clave privada del cliente
key /etc/openvpn/keys/cliente.key

# Activar la compresión LZO
comp-lzo

# Detectar caídas de la conexión
keepalive 10 60

# Archivo de log
log /var/log/openvpn/cliente.log

# Nivel de información
verb 3
~~~

### Pruebas de funcionamiento

Ahora vamos a comprobar que esta configuración funciona, para ello vamos a hacer ping a las dos subredes que hay detrás de `dulcinea`:

* **Ping a la red 10.0.1.0/24**
~~~
juanan@juananpc:~/GitHub/easy-rsa/easyrsa3$ ping 10.0.1.5
PING 10.0.1.5 (10.0.1.5) 56(84) bytes of data.
64 bytes from 10.0.1.5: icmp_seq=1 ttl=63 time=3.76 ms
--- 10.0.1.5 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 3.756/3.756/3.756/0.000 ms
~~~

* **Ping a la red 10.0.2.0/24**
~~~
juanan@juananpc:~/GitHub/easy-rsa/easyrsa3$ ping 10.0.2.2
PING 10.0.2.2 (10.0.2.2) 56(84) bytes of data.
64 bytes from 10.0.2.2: icmp_seq=1 ttl=63 time=3.64 ms
64 bytes from 10.0.2.2: icmp_seq=2 ttl=63 time=3.16 ms
--- 10.0.2.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 3ms
rtt min/avg/max/mdev = 3.161/3.398/3.635/0.237 ms
~~~
