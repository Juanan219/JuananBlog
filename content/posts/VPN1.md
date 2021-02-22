---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-22
linktitle: Ejericicio 1 VPN
type:
- post
- posts
title: Configuración de VPN con clave secreta
weight: 10
series:
- Hugo 101
images:
tags:
  - VPN
  - Ejercicio
  - Documentacion
  - Clave
  - Secreto
  - OpenVPN
---

## Configuración de openVPN de acceso remoto con clave estática compartida

Vamos a levantar un escenario en OpenStack con una [receta de heat](https://fp.josedomingo.org/seguridadgs/u04/escenario_vpn.yaml). En este ejercico, vamos a configurar una VPN basada en SSL/TLS usando OpenVPN.

## Configuración

Tenemos dos máquinas debian, una que va a actuar como Router llamada `vpn_server` y la otra como cliente, llamada `lan`. Para comenzar a realizar el ejercicio, vamos a activar el bit de forward para que nuestra máquina `lan` pueda acceder a internet a través de `vpn_server`, para ello cambiamos el valor `0` por el valor `1` del fichero `/proc/sys/net/ipv4/ip_forward` y creamos una regla `NAT` en `iptables`

~~~
sudo nano /proc/sys/net/ipv4/ip_forward

1

sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -j MASQUERADE
~~~

Por último nos conectamos a `lan` y comprobamos que tiene conexión con el exterior
~~~
ssh 192.168.100.10

ping www.google.es
PING www.google.es (216.58.209.67) 56(84) bytes of data.
64 bytes from waw02s06-in-f67.1e100.net (216.58.209.67): icmp_seq=1 ttl=112 time=180 ms
--- www.google.es ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 180.366/180.366/180.366/0.000 ms
~~~

Ahora que tenemos nuestro escenario funcionando, vamos a comenzar a montar nuestra `VPN`, así que para empezar vamos a instalar `OpenVPN` en nuestra máquina como el `vpn_server`
~~~
sudo apt-get install openvpn
~~~

El siguiente paso sería decidir cómo se va a realizar la autenticación de los extremos y el cifrado. En este ejercicio realizaremos la forma más sencilla, que es usar una **clave compartida (pre-shared key)**, aunque el uso de certificados es más seguro.

## Generación de la clave

Generamos la clave
~~~
sudo openvpn --genkey --secret clave.key
~~~

## Configuración del servidor

Movemos la clave generada al directorio `/etc/openvpn` y creamos el archivo `/etc/openvpn/server.conf`
~~~
mv clave.key /etc/openvpn

sudo nano /etc/openvpn/server.conf

dev tun
ifconfig 10.10.10.1 10.10.10.2
secret clave.key
~~~

## Configuración del cliente

Ahora vamos a pasar a la confgiuración del cliente y lo primero que haremos será instalar `openvpn` y copiar en el directorio `/etc/openvpn` del cliente la clave generada anteriormente.
~~~
debian@lan:~$ sudo apt-get install openvpn

debian@vpn-server:~$ scp clave.key debian@192.168.100.10:/home/debian

debian@lan:~$ sudo cp clave.key /etc/openvpn/
~~~

Ahora que tenemos todo preparado, vamos a crear un fichero de configuración en el cliente en la ruta `/etc/openvpn` llamado `client.conf` y le introducimos la siguiente configuración
~~~
sudo nano /etc/openvpn/client.conf

remote 172.22.201.64
dev tun
ifconfig 10.10.10.2 10.10.10.1
route 192.168.100.0 255.255.255.0
secret clave.key
~~~

* **remote:** Aquí introducimos la IP de la interfaz de red que accede a internet del servidor VPN (en mi caso sería la 172.22.201.64).
* **ifconfig:** Introducimos las IP de las interfaces de túnel. No tienen que coincidir con las IP de nuetra red. (En este caso les he puesto la 10.10.10.1 y 10.10.10.2)
* **route:** Añade a la tabla de encaminamiento del cliente una entrada que permita acceder a los recursos de la red local remota (En este ejemplo nuestra red es la `192.168.100.0/24`).

## Establecimiento de la VPN

Para establecer la `VPN` hay que arrancar `OpenVPN` en ambos extremos y configuramos `OpenVPN` para que lea los archivos `*.conf` del directorio `/etc/openvpn`, así que para configurar esto deberemos editar el fichero `/etc/default/openvpn` y descomentamops la línea `AUTOSTART="all"` y reiniciamos los siguientes servicios
~~~
debian@vpn-server:~$ sudo nano /etc/default/openvpn
[...]
AUTOSTART="all"
[...]
debian@vpn-server:~$ sudo systemctl daemon-reload
debian@vpn-server:~$ sudo systemctl start openvpn

debian@lan:~$ sudo nano /etc/default/openvpn
[...]
AUTOSTART="all"
[...]
debian@lan:~$ sudo systemctl daemon-reload
debian@lan:~$ sudo systemctl start openvpn
~~~

Cuando se haya establecido la VPN se habrá creado una interfaz de tipo túnel en ambas máquinas que simulan un enlace PPP. Vamos a compro bar que se han creado las interfaces de red de tipo túnel.
~~~
debian@vpn-server:~$ ip a
[...]
4: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/none 
    inet 10.10.10.1 peer 10.10.10.2/32 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::8894:d8a4:ed6a:37a3/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever

debian@lan:~$ ip a
[...]
3: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/none 
    inet 10.10.10.2 peer 10.10.10.1/32 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::e3cb:45d6:17ab:7fb3/64 scope link stable-privacy 
       valid_lft forever preferred_lft forever
~~~

A parte de las interfaces de red, se han creado también las reglas en la tabla de encaminamiento, que permiten el tráfico con la máquina `10.10.10.1` y con la red remota `192.168.100.0/24`
~~~
debian@vpn-server:~$ sudo ip r
default via 10.0.0.1 dev eth0 
10.0.0.0/24 dev eth0 proto kernel scope link src 10.0.0.7 
10.10.10.2 dev tun0 proto kernel scope link src 10.10.10.1 
169.254.169.254 via 10.0.0.1 dev eth0 
192.168.100.0/24 dev eth1 proto kernel scope link src 192.168.100.2

debian@lan:~$ sudo ip r
default via 192.168.100.2 dev eth0 
10.10.10.1 dev tun0 proto kernel scope link src 10.10.10.2 
169.254.169.254 via 192.168.100.1 dev eth0 
192.168.100.0/24 dev eth0 proto kernel scope link src 192.168.100.10
~~~

A partir de este momento el cliente podría usar todos los recursos de nuestra red local de forma segura, ya que todo el tráfico que pase por ahí irá cifrado a través del túnel.
