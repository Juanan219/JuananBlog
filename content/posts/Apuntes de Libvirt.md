---
author:
  name: "Juan Antonio Reifs"
date: 2021-03-18
linktitle: Apuntes de Libvirt
type:
- post
- posts
title: Apuntes de Libvirt
weight: 10
series:
- Hugo 101
images:
tags:
  - Apuntes
  - Documentacion
  - Libvirt
  - virsh
  - virtinst
  - kvm
  - qemu
---

`Libvirt` es una API de virtualizacion que se usa con `KVM` o `Qemu KVM` (el sistema de virtualización nativo de Linux).

## Instalación

Para instalar `libvirt` deberemos instalar los siguientes paquetes
~~~
sudo apt-get install qemu-kvm libvirt-daemon-system 
~~~

Explicación de los paquetes:

* **`qemu-kvm`:** Proporciona la virtualización para `x86`

* **`libvirt-daemon-system`:** Es el demonio de `libvirt`, el cual hace accesible la `API` a través de un `socket UNIX` (aunque se puede configurar para acceder a través de un `socket TCP`).

Una vez que ya hemos realizado la instalación de estos dos paquetes, deberemos añadir a nuestro usuario personal (el usuario sin privilegios) al grupo de `libvirt`.
~~~
sudo adduser usuario libvirt
~~~

Esta configuración se debe a que hay dos formas de usar esta API:

* **`qemu:///session`:** Sería el equivalente a usar el usuario sin privilegios del sistema, con lo cual tendríamos ciertas limitaciones al usar la `API`.

* **`qemu:///system`:** Sería el equivalente a usar el usuario administrador o `root` del sistema.

Por lo que si nuestro usuario no pertenece al grupo `libvirt`, no podríamos usar el comando `qemu:///system` con dicho usuario.

## Definición y creación de redes en virsh

Para crear objetos en `virsh` necesitamos crear ficheros `xml` en los que definimos dicha configuración.

Este es un dichero `xml` de creación de una red de ejemplo:
~~~
<network>
 <name>default</name>
 <forward mode='nat'>
  <nat>
   <port start='1024' end='65535'/>
  </nat>
 </forward>
 <bridge name='virbr0' stp='on' delay='0'/>
 <ip address='192.168.122.1' netmask='255.255.255.0'>
  <dhcp>
   <range start='192.168.122.2' end='192.168.122.254'/>
  </dhcp>
 </ip>
</network>
~~~

* Tenemos un fichero `xml` que crea un objeto de tipo **`network`**
	* El nombre de esta red es **`default`**.
	* Esta red es de tipo **`nat`**, el tipo de red se indica con la etiqueda **`forward`** (Esto nos permite que esta red tenga acceso al exterior, pero si queremos tener una red aislada, deberemos eliminar esta parte)
	* El dispositivo de conexión es de tipo **`bridge`**, el cual tiene un nombre llamado **`virbr0`** con el protocolo **`stp`** habilitado y el cual va a tener una ip asignada que es la **`192.168.122.1/24`**
	* En nuestra subred vamos a ejecutar un servidor **`dhcp`** con **`dnsmasq`** el cual va a tener un rango para repartir IPs desde la **`192.168.122.2`** hasta la **`192.168.122.254`**

Si no estamos seguros de si al fichero xml le falta algún elemento o no está bien estructurado o tiene algún error, podemos usar el comando `virt-xml-validate` para verificar que todo está correcto.
~~~
virt-xml-validate red1.xml
red1.xml validates
~~~

Ahora vamos a crear dicha red a partir de este fichero `xml`
~~~
virsh -c qemu:///system net-create red1.xml
~~~

Si queremos ver la red que acabamos de crear
~~~
virsh -c qemu:///system net-list
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   no          no
~~~

Si queremos ver todas las redes definidas, aunque no esté activas
~~~
virsh -c qemu:///system net-list --all
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   no          no
~~~

La red que hemos creado, como podemos ver en el `net-list`, dice que no es persistente, esto quiere decir que cuando reiniciemos nuestra máquina, dicha red va a desaparecer. Podemos comprobar esto *destruyendo* nuestra red y ejecutando el comando `net-list --all`, para ver que no está definida en ningún sitio.
~~~
virsh -c qemu:///system net-destroy default
Network default destroyed

 virsh -c qemu:///system net-list --all
 Name   State   Autostart   Persistent
----------------------------------------
~~~

Para crear una red que sea persistente deberemos usar el comando `net-define`
~~~
virsh -c qemu:///system net-define red1.xml
Network default defined from red1.xml

virsh -c qemu:///system net-list
 Name   State   Autostart   Persistent
----------------------------------------
~~~

Como podemos ver, si hacemos un `net-define` y después un `net-list` la red no está activa, pero si ejecutamos un `net-list --all`, podremos ver que dicha red está definida pero inactiva
~~~
virsh -c qemu:///system net-list --all
 Name      State      Autostart   Persistent
----------------------------------------------
 default   inactive   no          yes
~~~

Para activar dicha red, deberemos hacer un `net-start`
~~~
virsh -c qemu:///system net-start default
Network default started

 virsh -c qemu:///system net-list
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   no          yes
~~~

Si queremos eliminar una red definida debemos usar el comando `net-undefine`
~~~
virsh -c qemu:///system net-undefine default
~~~

Por otro lado, vamos a comparar el directorio `/etc/libvirt/qemu/networks/` antes y después de la definición de nuestra red, ya que antes de definir nuestra red, o solo creándola, nos damos cuenta de que en dicho directorio solo hay un directorio vacío llamado `autostart`
~~~
tree /etc/libvirt/qemu/networks/
/etc/libvirt/qemu/networks/
└── autostart

1 directory, 0 files
~~~

Mientras que si defnimos una red, dicho directorio se encontraría con nuestro fichero xml en su interior.
~~~
tree /etc/libvirt/qemu/networks/
/etc/libvirt/qemu/networks/
├── autostart
└── default.xml

1 directory, 1 file
~~~

Si queremos que nuestra red, además de ser persistente, se arranque por defecto cada vez que nosotros arranquemos nuestra máquina, deberemos hacer un `net-autostart`, entonces la API crea un enlace simbólico del fichero xml que se ha copiado en `/etc/libvirt/qemu/networks/` hacia el directorio `/etc/libvirt/qemu/networks/autostart` ya mencionado anteriormente.
~~~
virsh -c qemu:///system net-autostart default
Network default marked as autostarted

virsh -c qemu:///system net-list
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   yes         yes

ls -l /etc/libvirt/qemu/networks/autostart/
total 0
lrwxrwxrwx 1 root root 38 mar 10 12:04 default.xml -> /etc/libvirt/qemu/networks/default.xml
~~~

### Algunos comandos de redes interesantes

* Saber el `UUID` de una red a partir de su nombre:
~~~
virsh -c qemu:///system net-uuid default
6e0958c0-12a5-4518-b369-9feeced12d08
~~~

* Saber el nombre de una red a partir de su `UUID`:
~~~
virsh -c qemu:///system net-name 6e0958c0-12a5-4518-b369-9feeced12d08
default
~~~

* Información de la red
~~~
virsh -c qemu:///system net-info default
Name:           default
UUID:           6e0958c0-12a5-4518-b369-9feeced12d08
Active:         yes
Persistent:     yes
Autostart:      yes
Bridge:         virbr0
~~~

## Creación de pool por defecto

`Pool` es el término que usa `libvirt` para referirse a los sistemas de almacenamiento que podemos tener en los sistemas de virtualización.

Para poder definir un pool, necesitamos definir otro objeto con otro fichero xml, como por ejemplo este:
~~~
<pool type='dir'>
 <name>default</name>
 <target>
  <path>/libvirt/pool1</path>
 </target>
</pool>
~~~

* Tenemos un fichero `xml` que crea un objeto de tipo `pool` de tipo `dir` (directorio)
	* El cual se llama `default`
	* Y está ubicado en `/libvirt/pool1`

Para listar los dispositivos de almacenamiento que tenemos tanto activos como inactivos haremos lo mismo que para listar las redes, ya que el modo de empleo es el mismo.

Si queremos crear un `pool` usamos el comando `pool-create`, si lo queremos definir usamos `pool-define`, si lo queremos activar usamos `pool-start` y si lo queremos activar cada vez que arranque el sistema usamos `pool-autostart`.
~~~
virsh -c qemu:///system pool-create pool1.xml
Pool default created from pool1.xml

virsh -c qemu:///system pool-define pool1.xml
Pool default defined from pool1.xml

virsh -c qemu:///system pool-start default
Pool default started

virsh -c qemu:///system pool-autostart default
Pool default marked as autostarted
~~~

Si queremos listar los `pools` de almacenamiento activos usaremos el comando `pool-list` y si queremos listar todos los `pools`, tanto los activos como los inactivos usaremos `pool-list --all`.
~~~
virsh -c qemu:///system pool-list
 Name      State    Autostart
-------------------------------
 default   active   yes

virsh -c qemu:///system pool-list --all
 Name      State    Autostart
-------------------------------
 default   active   yes
~~~
El directorio equivalente a `/etc/libvirt/qemu/networks/` es `/etc/libvirt/storage` en el cual se copia el fichero xml que hemos creado para definir el objeto y en el directorio `/etc/libvirt/storage/autostart` se encuentra el enlace simbólico de autoarranque del pool.
~~~
tree /etc/libvirt/storage/
/etc/libvirt/storage/
├── autostart
│   └── default.xml -> /etc/libvirt/storage/default.xml
└── default.xml

1 directory, 2 files
~~~

Cuando hemos definido un pool, a parte de poder ver el fichero xml que se ha copiado en `/etc/libvirt/storage`, podemos usar el comando `pool-dumpxml` para ver el fichero que se ha generado/copiado en dicho directorio.
~~~
virsh -c qemu:///system pool-dumpxml default
<pool type='dir'>
  <name>default</name>
  <uuid>12554be7-613e-4603-ab87-ffcfbc249b22</uuid>
  <capacity unit='bytes'>107321753600</capacity>
  <allocation unit='bytes'>140763136</allocation>
  <available unit='bytes'>107180990464</available>
  <source>
  </source>
  <target>
    <path>/libvirt/pool1</path>
    <permissions>
      <mode>0755</mode>
      <owner>1000</owner>
      <group>1000</group>
    </permissions>
  </target>
</pool>
~~~

Si queremos eliminar un pool definido, deberemos usar la misma opción que para las redes, el comando `pool-undefine`
~~~
virsh -c qemu:///system pool-undefine default
~~~

### Definiendo un pool con qemu:///session

Ahora vamos a crear un `pool` de almacenamiento con `qemu:///session`. Este es el fichero xml

~~~
<pool type='dir'>
  <name>default</name>
  <target>
    <path>/home/juanan/.config/libvirt/storage</path>
  </target>
</pool>
~~~

* Tenemos un fichero xml que define un objeto `pool` de tipo `dir` (directorio)
	* Se llama `default`
	* Y se almacena en el directorio predeterminado para los `pools` de `qemu:///session`, que se encuentra en un directorio oculto dentro del directorio `/home/usuario` y cuyo directorio tiene la misma estructura que tenemos en el directorio `/etc/libvirt`

La manera de definir los `pools` se almacenamiento de `qemu:///session` es exactamente la misma que cuando los creamos con `qemu:///system`, pero en este caso no es necesario poner `qemu:///session`, por lo que con solo ejecutar `virsh pool-create [fichero_xml]` podemos ejecutar la instrucción.

## Manejo de volúmenes con virsh

Anteriormente hemos creado un pool de almacenamiento en la ruta `/libvirt/pool1`, el cual es un directorio. Ahora, en dicho directorio, vamos a crear un volúmen, el cual es un fichero que no sva a servir como dispositivo de almacenamiento de una máquina virtual, para realizar esto, vamos a volver a definir otros objetos con ficheros xml:
~~~
<volume type='file'>
  <name>vol1</name>
  <key>/libvirt/pool1/vol1.img</key>
  <source>
  </source>
  <allocation>0</allocation>
  <capacity unit="G">10</capacity>
  <target>
    <path>/libvirt/pool1/vol1.img</path>
    <format type='qcow2'/>
  </target>
</volume>
~~~

* En este caso tenemos un fichero xml que define un objeto de tipo `volumen`, el cual es un fichero (tipo `file`)
  * Su nombre es `vol1`
  * Tiene una capacidad de `10G`, aunque le hemos dicho que ocupe lo menos posible en función dle formato que tenga (etiqueta `<allocation>0</allocation>`)
  * Usaremos un tipo de fichero `qcow2`, el cual permite no ocupar los 10G de imagen en nuestro disco duro.
  * La ruta hacia el fichero que se va a crear será `/libvirt/pool1/vol1.img`

Ahora que tenemos el fichero de configuración de nuestro volúmen, vamos a cerarlo, para ello deberemos tener, anteriormente, un pool creado.
~~~
virsh -c qemu:///system vol-create default vol1.xml
Vol vol1 created from vol1.xml
~~~

Como podemos ver, si hacemos este comando con el fichero de configuración previamente creado, se nos creará nuestro columen en el pool indicado, si vemos el contenido del directorio `/libvirt/pool1`, vemos que se nos ha creado un archivo llamado `vol1` y si le preguntamos el tipo con el comando `file` nos dirá que es de tipo `qcow2`
~~~
ls pool1
vol1

sudo file pool1/vol1
pool1/vol1: QEMU QCOW Image (v2), 10737418240 bytes
~~~

`QEMU` tiene un comando para describir ficheros, si lo usamos nos dará información más detallada sobre el volumen creado
~~~
sudo qemu-img info pool1/vol1
image: pool1/vol1
file format: qcow2
virtual size: 10G (10737418240 bytes)
disk size: 196K
cluster_size: 65536
Format specific information:
    compat: 0.10
    refcount bits: 16
~~~

En la información que nos da el resultado del comando `qemu-img info` nos dice que nuestra imagen es `qcow2`, que tiene un tamaño virtual de `10G`, pero que en nuestro disco duro ocupa `196K`, ya que el `allocation` lo hemos dejado a 0. Esto tiene ciertas ventajas y desventajas:

* **Ventaja de dejar `allocation` a 0:** Ocupa menos espacio en el disco, es decir, ocupa solo el tamaño que necesita.

* **Desventaja de dejar `allocation` a 0:** La escritura en dicho volumen es más lenta, ya que tiene que estar aumentando el tamaño cada vez que se va a escribir algo.

* **Ventaja de tener un `allocation` mayor que 0:** La escritura en el volumen es más rápida, ya que si parte de un tamaño inicial, las primeras escrituras no tienen que aumentar el tamaño del volúmen.

* **Desventajas de tener un `allocation` mayor que 0:** Ocupa inicialmente más tamaño en el disco duro estando el volumen totalmente vacío.

Vamos a crear otro volumen, pero esta vez de tipo `raw`, esto es un formato que no admite el `allocation` 0, es decir, que el tamaño del fichero va a ser el tamaño que este tenga
~~~
<volume type='file'>
  <name>vol2</name>
  <key>/libvirt/pool1/vol2.img</key>
  <source>
  </source>
  <allocation>0</allocation>
  <capacity unit="G">5</capacity>
  <target>
    <path>/libvirt/pool1/vol2.img</path>
    <format type='raw'/>
  </target>
</volume>
~~~

~~~
virsh -c qemu:///system vol-create default vol2.xml
Vol vol2 created from vol2.xml

sudo file pool1/vol2
pool1/vol2: data

sudo qemu-img info pool1/vol2
image: pool1/vol2
file format: raw
virtual size: 5.0G (5368709120 bytes)
disk size: 0
~~~

Como podemos ver en los resultados de los comando anteriores, el volumen `vol2` ocupa los 5G que nosotros le hemos asignado aunque le hayamos puesto el `allocation` a 0, pero como hemos dicho antes, el formato `raw` no lo admite así que este lo ignora.

### Redimensionar un volumen

Una vez que hemos creado un volumen, podemos cambiar su tamaño si el dispositivo de almacenamiento no se está usando, para ello usaremos el comando `vol-resize`.
~~~
virsh -c qemu:///system vol-resize vol1 12G --pool default --shrink
Size of volume 'vol1' successfully changed to 12G
~~~

* Sintaxis: `vol-resize [volumen] [tamaño] --pool [pool] --shrink(comprimir el tamaño lo máximo posible)`

Si le hemos aunqmentado el tamaño,m lo podemos comprobar con el comando `qemu-img info`
~~~
sudo qemu-img info pool1/vol1
image: pool1/vol1
file format: qcow2
virtual size: 12G (12884901888 bytes)
disk size: 200K
cluster_size: 65536
Format specific information:
    compat: 0.10
    refcount bits: 16
~~~

Ahora el volumen tiene disponibles `12GB`, pero soo ocupa `200K`

### Comandos interesantes de volúmenes

* **`vol-clone`:** Clonar el dispositivo de almacenamiento de una máquina virtual
* **`vol-download`:** Descargar volúmenes desde el hipervisor
* **`vol-wipe`:** Eliminar información sin dejar rastro de lo que pudiese haber en ese volumen.
* **`vol-list --pool [pool]`:** Listar todos los volúemenes que pertenecen a un pool en concreto.
* **`vol-delete`:** Eliminar un volumen.

## Definición de un dominio con virsh

Ahora vamos a ver la creación de dominios (es como se le llaman a las máquinas virtuales) con `virsh`.

* Listar los dominios:
~~~
virsh -c qemu:///system list
 Id   Name   State
--------------------

virsh -c qemu:///system list --all
 Id   Name   State
--------------------
~~~

Para definir los dominios deberesmo crear otro fichero xml como en los anteriores casos
~~~
<domain type="kvm">
  <name>dominio1</name>
  <memory unit="G">1</memory>
  <vcpu>1</vcpu>
  <os>
    <type arch="x86_64">hvm</type>
  </os>
  <devices>
    <emulator>/usr/bin/kvm</emulator>
    <disk type='file' device='disk'>
      <source file='/libvirt/pool1/vol1'/>
      <target dev='vda'/>
    </disk>
    <interface type="network">
      <source network="default"/>
      <mac address="52:54:00:86:c6:a9"/>
    </interface>
    <console>
      <target type='serial'/>
    </console>
  </devices>
</domain>
~~~

* Tenemos un fichero xml que crea un objeto tipo dominio y que usa la virtualización de `kvm`, este se llama `dominio1`.
  * Tiene `1GB` de memoria RAM.
  * Tiene `1 core virtual`.
  * Se especifica que vamos a usar una arquitectura x86 y especificamos que es una `hvm` (*Hardware Virtual Machine*)
  * El emulador que usaremos como es `kvm`, especificamos la ruta hacia él (`/usr/bin/kvm`)
  * Le indicamos que el almacenamiento de la máquina va a ser un fichero (`file`), pero la máquina lo va a ver como si fuera un disco (`disk`).
  * Le indicamos también la ruta que tiene el archivo que vamos a usar como dispositivo de almacenamiento (el cual va a ser el volumen `vol1` que henmos creado anteriormente y está ubicado en `/libvirt/pool1/vol1`), peor en la máquina aparecerá dicho dispositivo de almacenamiento como un `vda`.
  * Le ponemos una interfaz de red conectada a la red llamada `default`, la cual hemos creado anteriormente y le ponemos una dirección MAC a dicha interfaz (dicha dirección MAC debe tener los 3 primeros octetos de libvirt y los demás aleatorios, es decir, `52:54:00:...`).
  * Le indicamos que tenemos una consola tipo serie.

Ahora creamos el dominio:
~~~
virsh -c qemu:///system define dominio1.xml
Domain dominio1 defined from dominio1.xml
~~~

Cuando hayamos definido el dominio, se creará una copia del xml en `/etc/libvirt/qemu`
~~~
ls /etc/libvirt/qemu
dominio1.xml  networks
~~~

Si hacemos un `list`, el dominio que acabamos de definir no aparecerá, ya que no está activo todavía, pero lo podemos ver si hacemos un `list --all`
~~~
virsh -c qemu:///system list
 Id   Name   State
--------------------

virsh -c qemu:///system list --all
 Id   Name       State
---------------------------
 -    dominio1   shut off
~~~

Para crear imágenes para poder arrancar los dominios que creemos vamos a hacer uso de la herramienta `virtinst`.

## Virtinst

El paquete `virinst` contiene una serie de programas de más alto nivel que `virsh`, los cuales nos pueden ayudar a realizar determinadas tareas. Así que en lugar de interactuar con ficheros xml, vamos a interactuar con la API de `libvirt` a través de un comando en nuestra terminal.

### virt-install

Este programa se usa para la instalación inicial de una máquina virtual. Ejemplo:

* **Queremos una máquina virtual con las siguientes especificaciones:**

  * **1 core virtual**
  * **1024 MiB de RAM**
  * **Que se conecte a la red `default` que anteriormente hemos creado**
  * **Que cree un volumen de 10GiB en el pool `default` que hemos creado anteriormente**
  * **Que use una imagen ISO netinst de debian 10 que hemos descargado**
~~~
virt-install --connect qemu:///system \
--cdrom /libvirt/debian/debian-10.8.0-amd64-netinst.iso \
--disk size=10 \
--network bridge=virbr0 \
--name dominio1 \
--memory 1024 \
--vcpus 1
~~~

Si surge el error `ERROR    internal error: cannot load AppArmor profile 'libvirt-...'` deberemos de editar el fichero `/etc/libvirt/qemu.conf` y descomentamos la línea `416` y cmabiamos su valor a `none` y reiniciamos el servicio de `libvirt`
~~~
sudo nano /etc/libvirt/qemu.conf
[...]
security_driver = "none"
[...]
~~~

* Para ver la pantalla de un dominio
~~~
virt-viewer -c qemu:///system [nombre del dominio]
~~~

## Creación de una red NAT desde fichero XML

Crear redes desde cero en formato xml como hemos hecho anteriormente es un poco complicado de primeras, pero si usamos las herramientas adecuadas, puede ser un poco más fácil la tarea. Para hacer una red de tipo `NAT` con un fichero xml desde cero, vamos a usar las siguientes herramientas para ayudarnos:

* [Documentación de libvirt](https://libvirt.org/format.html)
* Editor de texto `emacs` con el modo xml activo
* [Repositorio de libvirt](https://github.com/libvirt/libvirt.git) con los esquemas para cargarle al editar `emacs`
* `trang` para convertir ficheros

Sabiendo las herramientas que vamos a usar, vamos a comenzar por instalar el editor de texto (si no lo tenemos) y a clonar el repositorio
~~~
sudo apt-get install emacs

git clone https://github.com/libvirt/libvirt.git
~~~

En el interior del repositorio que acabamos de clonar hay una carpeta llamada `docs/schemas/` en la cual se encuentran los esquemas que hay que seguir para realizar los fichero xml de configuración. Estos archivos de esquema están en formato `rng`, pero el editor `emacs` solo admite `rnc` (un formato más comprimido que `rng`), así que convertiremos el archivo `network.rng` en `network.rnc` con la herramienta `trang`
~~~
trang -I rng -O rnc network.rng network.rnc

ls -hrtl
[...]
-rw-r--r-- 1 juanan juanan 5,6K mar 17 17:15 network.rnc
-rw-r--r-- 1 juanan juanan 2,8K mar 17 17:15 networkcommon.rnc
-rw-r--r-- 1 juanan juanan 9,0K mar 17 17:15 basictypes.rnc
~~~

Como podemos ver, se han creado tres ficheros, uno de ellos el fichero `network.rnc` y los otros dos son dependencias que necesita el fichero ya mencionado.

Ahora pasaremos a crear el fichero xml, para ello, como hemos dicho anteriormente, usaremos `emacs`
~~~
emacs red1.xml
~~~

Cuando tengamos nuestro editor arrancado, vamos a cargarle los esquemas necesarios, para ello nos dirigimos a `XML --> Set Schema --> File` y seleccionamos nuestro archivo `network.rnc`

Otro dato es que si queremos generar un `UUID` aleatorio para crear nuestra red, lo podemos hacer de la siguiente manera
~~~
cat /proc/sys/kernel/random/uuid
~~~

Si queremos una dirección MAC aleatoria con los tres primeros octetos del fabricante de libvirt, ejecutamos el siguiente comando
~~~
openssl rand -hex 3 | sed 's/\(..\)\(..\)\(..\)/52:54:00:\1:\2:\3/'
~~~
