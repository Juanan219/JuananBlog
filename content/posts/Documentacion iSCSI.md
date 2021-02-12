# Apuntes iSCSI

## Storage Area Network (SAN)

### Redes de almacenamiento

* Es una red de almacenamiento que proporciona dispositivos de bloques a los servidores, esta red es una red infependiente a la red local de nuestra organización.

* Los elementos típicos de una SAN son:

	* Red de alta velocidad (cobre o fibra óptica)

	* Equipos o servidores que proporcionan el almacenamiento

	* Servidores que usan los dispositivos de bloques

* Los protocolos más usados en este tipo de redes son:

	* iSCSI

	* Fibre Channel Protocol (FCP)

#### Esquema de ejemplo de una SAN

![Captura 1](/iSCSI/1.png)

## iSCSI

* Es un protocolo que se usa sobre todo en redes de almacenamiento (aunque para usar iSCSI no es imprescindible tener una SAN, sería lo recomendable, ya que la SAN nos proporciona un mecanismo de aislamiento adecuado para que podamos usar dispositivos de bloques de una forma más segura), pero también se puede usar en una red local.

* Nos proporciona acceso a dispositivos de bloques sobre TCP/IP

* Alternativa económica a FCP

* Usado habitualmente en redes con velocidades de 1 Gbps o 10 Gbps

### Elementos iSCSI

* **Unidad Lógica (LUN):** Es un dispositivo de bloques a compartir por el servidor iSCSI (Por ejemplo 3 discos duros que hay en el servidor iSCSI)

* **Target:** Recurso a compartir desde el servidor. Un target incluye uno o varios LUN. (Explicación: El target contiene los 3 discos duros del servidor para cuando el cliente se conecte, use dicho target, por lo que el cliente tiene 3 discos duros adicionales en su sistema operativo a través de una sola conexión. De forma alternativa, podemos plantear que cada una de las conexiones tenga su dispositivo de forma independiente, por lo que en este caso, el cliente tendría 3 targets con 3 conexiones independientes)

* **Initiator:** Cliente iSCSI

* **Multipath:** Varias rutas entre initiator y servidor para garantizar la disponibilidad de la conexión, es decir, si tenemos varias formas de conectar el cliente con el servidor, se haría uso de esta característica, ya que si no está disponible la conexión por una ruta, se usa la ruta alternativa.

* IQN es el formato más extendido para la descripción de los recursos. Por ejemplo: `iqn.2020-01.es.tinaja:sdb4` (iqn.[fecha significativa].[nombre a la inversa del dominio o servidor]:[LUN])

* **iSNS:** Protocolo que permite gestionar recursos de iSCSI como si fuera FCP 

### Implementaciones de iSCSI

* iSCSI tiene soporte en la mayoría de sistemas operativos

* En Linux usamos `open-iscsi` como initiator

* Existen algunas opciones en Linux para el servidor iSCSI:

	* Linux-IO (LIO) (Versión implementada en el kérnel de Linux)

	* tgt (Es la más usada)

	* scst

	* istgt

## Demo iSCSI

* Instalamos `tgt`
```
sudo apt-get install tgt
```

* Hay dos formas de usar este software:

	* Podemos dirigirnos al directorio `/etc/tgt/` y definir ahí la configuración modificando los ficheros que sean oportunos. De esta manera la configuración es permanente, es decir, se guardan los cambios.

	* Desde la línea de comandos, por lo que al no estar definida la configuración en ningún sitio, sino hecha "en caliente", no se guardan los cambios a la hora de reiniciar la máquina. (Esta es la forma que usaremos en esta demo)

* Definimos un target:

	* **--lld:** El controlador, en este caso sera `iscsi` (`--lld iscsi`)
	* **--op:** La operación que deseamos hacer, en este caso será crear un nuevo target, por lo que el valor será `new` (`--op new`)
	* **--mode:** Lo que queremos crear, en este caso es un target, por lo que el valor es `target` (`--mode target`)
	* **--tid:** El ID de nuestro nuevo target, en este caso le vamos a asignar el id `1` (`--tid 1`)
	* **-T:** El nombre del target que vamos a definir, en este caso será `iqn."año-mes de creación.dominio:nombre_target"` (`--T iqn.2021-02.es.juanan:target1`)
```
sudo tgtadm --lld iscsi --op new --mode target --tid 1 -T iqn.2021-02.es.juanan:target1
```

	* Si queremos eliminar un target, simplemente ejecutamos el siguiente comando
```
sudo tgtadm --lld iscsi --op delete --mode target --tid 1
```

* Le añadimos un dispositivo de bloques:

	* **--mode logicalunit:** Le decimos que queremos añadir una unidad lógica
	* **--lun 1:** El ID de la unidad lógica que vamos a añadir
	* **-b /dev/sdb:** Ruta hacia el dispositivo de bloques que vamos a añadir 
```
sudo tgtadm --lld iscsi --op new --mode logicalunit --tid 1 --lun 1 -b /dev/sdb
``` 

* Le añadimos un segundo y tercer dispositivo de bloques
```
sudo tgtadm --lld iscsi --op new --mode logicalunit --tid 1 --lun 2 -b /dev/sdc
sudo tgtadm --lld iscsi --op new --mode logicalunit --tid 1 --lun 3 -b /dev/sdd
```

	* Si queremos eliminar alguna de las unidades lógicas que hemos añadido, ejecutamos el siguiente comando:
```
sudo tgtadm --lld iscsi --op delete --mode logicalunit --tid 1 --lun 2
```

* Comprobamos que el target está bien definido
```
sudo tgtadm --lld iscsi --op show --mode target
```

	* Salida del comando anterior
```
sudo tgtadm --lld iscsi --op show --mode target
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
        LUN: 2
            Type: disk
            SCSI ID: IET     00010002
            SCSI SN: beaf12
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
        LUN: 3
            Type: disk
            SCSI ID: IET     00010003
            SCSI SN: beaf13
            Size: 1074 MB, Block size: 512
            Online: Yes
            Removable media: No
            Prevent removal: No
            Readonly: No
            SWP: No
            Thin-provisioning: No
            Backing store type: rdwr
            Backing store path: /dev/sdd
            Backing store flags: 
    Account information:
    ACL information:
```

* Explicación:

	* **Información sobre el target:** Podemos ver que nos muestra el `Target 1` y su nombre `iqn.2021-02.es.juanan:target1`. Está en modo `ready` (`State: ready`) y tiene un controlador `iscsi` (`Driver: iscsi`)
```
Target 1: iqn.2021-02.es.juanan:target1
    System information:
        Driver: iscsi
        State: ready
    I_T nexus information:
```

	* **Información de las LUN:** En este apartado (que es el más extenso), podemos ver que tenemos definidas 4 LUNs (`LUN 0, LUN 1, LUN 2 y LUN 3`), pero nosotros solo hemos definido 3 LUNs, esto se debe a que la `LUN 0` es una LUN de control, esto quiere decir que en esta LUN solo se guarda las características de las LUNs y siempre se define cuando se define un target. En las demás LUNs podemos ver información como el tipo de LUN que es (`Type: disk`), si es un dispositivo extraíble (`Removable media: No`), si esta en modo sólo lectura (`Readonly: No`), si tiene aprovisionamiento ligero (`Thin-provisioning: No`), el dispositivo de bloques que tiene asociado (`Backing store path: /dev/sdb`), el modo en el que se encuentra (`Backing store type: rdwr`), etc...
```
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
```

	* **Información adicional:** Este comando también nos muestra información sobre la cuenta de acceso y sobre las ACL si las tuvieramos
```
Account information:
ACL information:
```

* Podemos hacer accesible al target creado desde todas las interfaces de red o desde interfaces de red específicas de nuestra máquina. En este caso la haremos accesible a través de todas las interfaces de red de las que disponga nuestra máquina:

	* **--op bind:** Operación que nos permite especificar por cuáles interfaces de red queremos hacer accesible un objeto
	* **--I ALL:** Le indicamos las interfaces de red por las que queremos hacer accesible este target, en este caso, le hemos puesto el valor `ALL` para que este target sea accesible por todas las interfaces de red.
```
sudo tgtadm --lld iscsi --op bind --mode target --tid 1 -I ALL
```

* Cuando tengamos el target configurado y las interfaces de red por las que es accesible definidas, vamos a pasar a la configuración del cliente, ya que, dicho target, debería ser visible desde el cliente. Para conectar el target al cliente, debemos irnos al cliente e instalar el siguiente paquete
```
sudo apt-get install open-iscsi
```
	* Al instalar el paquete, se nos asignará un nombre predeterminado, el cual se puede ver en el fichero `/etc/iscsi/initiatorname.iscsi` (Este fichero no se debe editar, a parte, no es necesario editarlo a no ser que lo necesites)
```
sudo tail /etc/iscsi/initiatorname.iscsi

InitiatorName=iqn.1993-08.org.debian:01:7eb51324d021
```

* Ahora que lo tenemos instalado, podemos ver la información:

```
sudo iscsiadm --mode discovery --type sendtargets --portal server

192.168.1.48:3260,1 iqn.2021-02.es.juanan:target1
```

* También nos podemos conectar al target:
```
sudo iscsiadm --mode node -T iqn.2021-02.es.juanan:target1 --portal server --login
```

	* Estas son las entradas del log del kernel (`journalctl -f -k`) que podemos ver cuando nos conectamos. Si nos damos cuenta, es como si le conectásemos 3 nuevos discos
```
Feb 12 20:51:16 initiator kernel: Loading iSCSI transport class v2.0-870.
Feb 12 20:51:16 initiator kernel: iscsi: registered transport (tcp)
Feb 12 20:51:16 initiator kernel: iscsi: registered transport (iser)
Feb 12 22:23:15 initiator kernel: scsi host1: iSCSI Initiator over TCP/IP
Feb 12 22:23:15 initiator kernel: scsi 1:0:0:0: RAID              IET      Controller       0001 PQ: 0 ANSI: 5
Feb 12 22:23:15 initiator kernel: scsi 1:0:0:0: Attached scsi generic sg1 type 12
Feb 12 22:23:15 initiator kernel: scsi 1:0:0:1: Direct-Access     IET      VIRTUAL-DISK     0001 PQ: 0 ANSI: 5
Feb 12 22:23:15 initiator kernel: sd 1:0:0:1: Attached scsi generic sg2 type 0
Feb 12 22:23:15 initiator kernel: sd 1:0:0:1: Power-on or device reset occurred
Feb 12 22:23:15 initiator kernel: scsi 1:0:0:2: Direct-Access     IET      VIRTUAL-DISK     0001 PQ: 0 ANSI: 5
Feb 12 22:23:15 initiator kernel: sd 1:0:0:1: [sdb] 2097152 512-byte logical blocks: (1.07 GB/1.00 GiB)
Feb 12 22:23:15 initiator kernel: sd 1:0:0:2: Attached scsi generic sg3 type 0
Feb 12 22:23:15 initiator kernel: sd 1:0:0:2: Power-on or device reset occurred
Feb 12 22:23:15 initiator kernel: sd 1:0:0:1: [sdb] Write Protect is off
Feb 12 22:23:15 initiator kernel: sd 1:0:0:1: [sdb] Mode Sense: 69 00 10 08
Feb 12 22:23:15 initiator kernel: scsi 1:0:0:3: Direct-Access     IET      VIRTUAL-DISK     0001 PQ: 0 ANSI: 5
Feb 12 22:23:15 initiator kernel: sd 1:0:0:3: Attached scsi generic sg4 type 0
Feb 12 22:23:15 initiator kernel: sd 1:0:0:1: [sdb] Write cache: enabled, read cache: enabled, supports DPO and FUA
Feb 12 22:23:15 initiator kernel: sd 1:0:0:3: Power-on or device reset occurred
Feb 12 22:23:15 initiator kernel: sd 1:0:0:2: [sdc] 2097152 512-byte logical blocks: (1.07 GB/1.00 GiB)
Feb 12 22:23:15 initiator kernel: sd 1:0:0:2: [sdc] Write Protect is off
Feb 12 22:23:15 initiator kernel: sd 1:0:0:2: [sdc] Mode Sense: 69 00 10 08
Feb 12 22:23:15 initiator kernel: sd 1:0:0:2: [sdc] Write cache: enabled, read cache: enabled, supports DPO and FUA
Feb 12 22:23:15 initiator kernel: sd 1:0:0:3: [sdd] 2097152 512-byte logical blocks: (1.07 GB/1.00 GiB)
Feb 12 22:23:15 initiator kernel: sd 1:0:0:3: [sdd] Write Protect is off
Feb 12 22:23:15 initiator kernel: sd 1:0:0:3: [sdd] Mode Sense: 69 00 10 08
Feb 12 22:23:15 initiator kernel: sd 1:0:0:3: [sdd] Write cache: enabled, read cache: enabled, supports DPO and FUA
Feb 12 22:23:15 initiator kernel: sd 1:0:0:2: [sdc] Attached SCSI disk
Feb 12 22:23:15 initiator kernel: sd 1:0:0:1: [sdb] Attached SCSI disk
Feb 12 22:23:15 initiator kernel: sd 1:0:0:3: [sdd] Attached SCSI disk
```

	* Esta es la salida del comando `lsblk` antes de conectarnos
```
lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0 19.8G  0 disk 
├─sda1   8:1    0 18.8G  0 part /
├─sda2   8:2    0    1K  0 part 
└─sda5   8:5    0 1021M  0 part [SWAP]
```

	* Esta es la salida del comando `lsblk` después de conectarnos
```
lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0 19.8G  0 disk 
├─sda1   8:1    0 18.8G  0 part /
├─sda2   8:2    0    1K  0 part 
└─sda5   8:5    0 1021M  0 part [SWAP]
sdb      8:16   0    1G  0 disk 
sdc      8:32   0    1G  0 disk 
sdd      8:48   0    1G  0 disk
```

* Ahora que los tenemos conectados remotamente a nuestra máquina, podemos operar sobre ellos, por ejemplo, si queremos montar uno de los dispositivos (`/dev/sdb`) de bloques le podemos dar formato `ext4` y montarlo en `/mnt`
```
sudo mkfs.ext4 /dev/sdb

sudo mount /dev/sdb /mnt

lsblk -f

sdb    ext4         86b14bd0-6953-4996-a1da-f82f5d248b51  906.2M     0% /mnt
```