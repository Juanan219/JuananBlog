---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-15
linktitle: Practica iSCSI
type:
- post
- posts
title: Practica iSCSI
weight: 10
series:
- Hugo 101
images:
tags:
  - iSCSI
  - targets
  - initiator
  - Linux
  - Windows
  - Practica
---

## Creación de targets en Linux

Primero vamos a crear un target con una LUN, para ello primero vamos a instalar el paquete `tgt` en el servidor
~~~
sudo apt-get install tgt
~~~
Ahora vamos a definir dos targets, uno para un cliente Linux y otro para un cliente Windows. Para definirlos de forma persistente, deberemos editar el fichero `/etc/tgt/targets.conf` y reiniciamos el servicio `tgt`
~~~
sudo nano etc/tgt/targets.conf
[...]
<target iqn.2021-02.es.juanan:target1>
        backing-store /dev/sdb
</target>
<target iqn.2021-02.es.juanan:target2>
        backing-store /dev/sdc
</target>

sudo systemctl restart tgt
~~~

Podemos ver los targets con el siguiente comando
~~~
sudo tgtadm --lld iscsi --op show  --mode target

Target 1: iqn.2021-02.es.juanan:target1
    System information:
        Driver: iscsi
        State: ready
    I_T nexus information:
    LUN information:
        LUN: 0
            Type: controller
            SCSI ID: IET     00010000
            SCSI SN: beaf10
            Size: 0 MB, Block size: 1
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: null
            Backing store path: None
            Backing store flags: 
        LUN: 1
            Type: disk
            SCSI ID: IET     00010001
            SCSI SN: beaf11
            Size: 1074 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/sdb
            Backing store flags: 
    Account information:
    ACL information:
        ALL
Target 2: iqn.2021-02.es.juanan:target2
    System information:
        Driver: iscsi
        State: ready
    I_T nexus information:
    LUN information:
        LUN: 0
            Type: controller
            SCSI ID: IET     00020000
            SCSI SN: beaf20
            Size: 0 MB, Block size: 1
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: null
            Backing store path: None
            Backing store flags: 
        LUN: 1
            Type: disk
            SCSI ID: IET     00020001
            SCSI SN: beaf21
            Size: 1074 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/sdc
            Backing store flags: 
    Account information:
    ACL information:
        ALL
~~~

Ahora nos vamos a conectar al cliente Linux e instalaremos la herramienta `open-iscsi`
~~~
sudo apt-get install open-iscsi
~~~

Como podemos ver, esta máquina tiene solo 1 disco duro
~~~
lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                     
├─sda1 ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2                                                                  
└─sda5 swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
~~~

Vamos a buscar los targets disponibles
~~~
sudo iscsiadm --mode discovery --type sendtargets --portal server
192.168.1.113:3260,1 iqn.2021-02.es.juanan:target1
192.168.1.113:3260,1 iqn.2021-02.es.juanan:target2
~~~

Cuando sepamos los targets que tiene el servidor `server` disponibles, podemos conectarnos, ya que no tienen autenticación, de momento
~~~
sudo iscsiadm --mode node -T iqn.2021-02.es.juanan:target1 --portal server --login
~~~

Después del comando anterior, esta es la nueva salida de `lsblk -f`
~~~
lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                     
├─sda1 ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2                                                                  
└─sda5 swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
sdb
~~~

Le damos formato y lo montamos
~~~
sudo mkfs.ext4 /dev/sdb
mke2fs 1.44.5 (15-Dec-2018)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: 97ec7dd7-1a01-4ab9-8572-4607066b6f2b
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done

sudo mount /dev/sdb /mnt

lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                     
├─sda1 ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2                                                                  
└─sda5 swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
sdb    ext4         97ec7dd7-1a01-4ab9-8572-4607066b6f2b  906.2M     0% /mnt
~~~

## Montar targets de forma autmática con systemd mount

Para montar los discos duros de iSCSI de forma permanente en unestro cliente Linux vamos a usar `systemd mount`, para ello modificaremos el fichero `/etc/iscsi/iscsid.conf`, comentamos la línea 43 y descomentamos la 40
~~~
sudo nano /etc/iscsi/iscsid.conf
[...]
node.startup = automatic
[...]
# node.startup = manual
[...]

sudo systemctl restart iscsi
~~~

Ahora creamos la unidad en `systemctl`, para ello creamos un fichero en la ruta `/etc/systemd/system`
~~~
sudo nano discored1.mount

[Unit]
Description= Se monta el target1 de iscsi

[Mount]
What=/dev/sdb
Where=/discored1
Type=ext4
Options=_netdev

[Install]
WantedBy=multi-user.target
~~~

Ahora reiniciamos los servicios, montamos el disco y creamos un enlace simbólico para que se monte automáticamente en el arranque, para realizar todo esto, el disco que queremos tiene que estar montado
~~~
sudo systemctl daemon-reload
sudo iscsiadm --mode node -T iqn.2021-02.es.juanan:target1 --portal server --login
sudo systemctl start discored1.mount
sudo systemctl enable discored1.mount
~~~

Comprobamos si se han realizado los cambios
~~~
lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                     
├─sda1 ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2                                                                  
└─sda5 swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
sdb    ext4         97ec7dd7-1a01-4ab9-8572-4607066b6f2b  906.2M     0% /discored1
~~~

Ahora reiniciamos y volveremos a comprobar
~~~
sudo reboot

lsblk -f
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
sda                                                                     
├─sda1 ext4         983742b1-65a8-49d1-a148-a3865ea09e24   16.1G     7% /
├─sda2                                                                  
└─sda5 swap         04559374-06db-46f1-aa31-e7a4e6ec3286                [SWAP]
sdb    ext4         97ec7dd7-1a01-4ab9-8572-4607066b6f2b  906.2M     0% /discored1
sdc
~~~

## Montar target en Windows con autenticación CHAP
Primero vamos a modificar de nuevo el fichero `/etc/tgt/targets.conf` en el server de iSCSI para introducir el usuario y la contraseña del target. Cuando hagamos las modificaciones, reiniciamos el servicio
~~~
sudo nano /etc/tgt/targets.conf
[...]
<target iqn.2021-02.es.juanan:target2>
        backing-store /dev/sdc
        incominguser juanan juanan_usuario
</target>

sudo systemctl restart tgt.service 
~~~

Ahora vamos a montar el disco `sdc` en windows, para ello nos abrimos el `Panel de control` > `Sistema y Seguridad` > `Herramientas Administrativas` > `Iniciador iSCSI`. Cuando estemos en este punto, Windows nos preguntará si queremos iniciar el servicio `iSCSI` y le tendremos que decir que sí.

![Captura 2](/iSCSI/2.png)

Ahora simplemente en la sección `Destinos` escribimos el nombre de nuestro server en el cuadro llamado `Destino` y le damos al botón llamado `Conexión Rápida...`

![Captura 3](/iSCSI/3.png)

Ahora que nuestro Window ha detectado a nuestro servidor, vamos a conectar el disco duro sdc, para ello seleccionamos el target al que nos queremos conectar y le damos al botón `Conectar`. Si nos intentamos conectar, sin más, nos va a aparecer un error de autenticación

![Captura 4](/iSCSI/4.png)

Para iniciar sesión con los parámetros que le hemos configurado anteriormente en el server, nos intentamos conectar igual que antes, pero con la diferencia de que deberemos pulsar el botón de `Opciones Avanzadas...` > `Habilitar inicio de sesión CHAP` y escribimos las credenciales correctas.

![Captura 5](/iSCSI/5.png)

Como podemos ver, ha cambiado el estado del `target2`, el cual ha pasado de estar `Inactivo` a estar `Conectado`

![Captura 6](/iSCSI/6.png)

Ahora vamos a comprobar que tenemos ese disco duro montado, para ello nos dirigimos a `Crear y  formatear particiones del disco duro` y lo primero que nos aparecerá es una ventana avisándonos de que tenemos un disco duro nuevo, pero que no tiene ninguna partición ni formato

![Captura 7](/iSCSI/7.png)

Para cpmprobar que podemos hacer cambios en el disco, he creado una partición

![Captura 8](/iSCSI/8.png)
