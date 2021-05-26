---
author:
  name: "Juan Antonio Reifs"
date: 2021-05-26
linktitle: bacula
type:
- post
- posts
title: Sistema de copias de seguridad
weight: 10
series:
- Hugo 101
images:
tags:
  - Bacula
  - Copias de seguridad
  - CentOs
  - Debian
  - Ubuntu
---

Voy a integrar un sistema de copias de seguridad en mi escenario de servidores, para ello voy a instalar y configurar `bácula`, así que para empezar vamos a explicar qué es bácula y de qué se compone.

## ¿Qué es bácula?

Bácula es un sistema de copias de seguridad, el cual se compone de 3 servicios diferentes:

* **Bacula director:** Es el servicio que lo controla todo, es decir, el que le dice a cada servicio qué es lo que tiene que hacer.

* **Bacula storage daemon:** Es el servicio que se encarga de decir dónde está el dispositivo de almacenamiento donde vamos a almacenar los datos.

* **Bacula file daemon:** Es el cliente de bácula, es decir, es el que se encarga de darle acceso al director a los archivos de los que vamos a hacer la copia de seguridad.

[^Apunte]: Estos servicios pueden estar en máquinas diferentes, pero en mi caso los voy a instalar todos en la misma máquina.

## Configuración

Vamos a pasar a la configuración del sistema de copias de seguridad. En esta configuración, como he dicho anteriormente, voy a realizar la instalación de todos los servicios en una misma máquina, excepto del demonio `bacula-fd`, el cual tiene que estar en todas las máquinas de las que queremos hacer copias de seguridad.

### Configuración de bacula-fd

Vamos a comenzar desde abajo, así que primero configuraremos el cliente de bácula, para ello instalaremos en todas las máquinas el paquete `bacula-client`
~~~
sudo apt-get update && sudo apt-get install bacula-client
~~~

Cuando lo instalemos vamos a configurar nuestro cliente modificando el fichero `/etc/bacula/bacula-fd.conf`
~~~
# Conexión al director
Director {
  Name = [Nombre del director] #Nombre del director
  Password = "[Contraseña del director]" #Contraseña para iniciar sesión en el director
}

Director {
  Name = [Nombre del mon] #Nombre del director
  Password = "[Contraseña del director]" #Contraseña para iniciar sesión en el director
  Monitor = yes
}

#Configuración del file daemon
FileDaemon {
  Name = [Nombre del file daemon que estamos configurando] #Nombre de este file daemon
  FDport = 9102
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /run/bacula
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib/bacula
  FDAddress = [IP de este file daemon] #Dirección IP de este file daemon
}

# Configuración de los mensajes
Messages {
  Name = Standard
  director = freston-dir = all, !skipped, !restored
}
~~~

Para comprobar que está bien estructurado el fichero vamos a ejecutar el siguiente comando
~~~
sudo bacula-fd /etc/bacula/bacula-fd.conf
~~~

Así quedaría el `bacula-fd` de mis máquinas:

* **Freston:**
~~~
# Conexión al director
Director {
  Name = freston-dir #Nombre del director
  Password = "admin" #Contraseña para iniciar sesión en el director
}

Director {
  Name = freston-mon #Nombre del director
  Password = "admin" #Contraseña para iniciar sesión en el director
  Monitor = yes
}

#Configuración del file daemon
FileDaemon {
  Name = freston-fd #Nombre de este file daemon
  FDport = 9102
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /run/bacula
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib/bacula
  FDAddress = 10.0.1.6 #Dirección IP de este file daemon
}

# Configuración de los mensajes
Messages {
  Name = Standard
  director = freston-dir = all, !skipped, !restored
}
~~~

* **Dulcinea:**
~~~
# Conexión al director
Director {
  Name = freston-dir #Nombre del director
  Password = "admin" #Contraseña para iniciar sesión en el director
}

Director {
  Name = freston-mon #Nombre del director
  Password = "admin" #Contraseña para iniciar sesión en el director
  Monitor = yes
}

#Configuración del file daemon
FileDaemon {
  Name = dulcinea-fd #Nombre de este file daemon
  FDport = 9102
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /run/bacula
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib/bacula
  FDAddress = 10.0.1.7 #Dirección IP de este file daemon
}

# Configuración de los mensajes
Messages {
  Name = Standard
  director = freston-dir = all, !skipped, !restored
}
~~~

* **Quijote:**
~~~
# Conexión al director
Director {
  Name = freston-dir #Nombre del director
  Password = "admin" #Contraseña para iniciar sesión en el director
}

Director {
  Name = freston-mon
  Password = "admin"
  Monitor = yes
}

#Configuración del file daemon
FileDaemon {
  Name = quijote-fd #Nombre de este file daemon
  FDport = 9102
  WorkingDirectory = /var/spool/bacula
  Pid Directory = /var/run
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib64/bacula
  FDAddress = 10.0.2.2 #Dirección IP de este file daemon
}

# Configuración de los mensajes
Messages {
  Name = Standard
  director = bacula-dir = all, !skipped, !restored
}
~~~

Cuando hayamos terminado de configurarlo todo, reinciamos el servicio para que se apliquen los cambios
~~~
sudo systemctl restart bacula-fd
~~~

### Configuración de bacula-sd

Ahora vamos a pasar a configurar bacula-sd en freston (que es la máquina que va a contener todos los servicios), así que para comenzar vamos a instalarlo con el siguiente comando
~~~
sudo apt-get install bacula-sd
~~~

Modificamos el fichero de configuración `/etc/bacula/bacula-sd.conf`
~~~
# Definición del almacenamiento

Storage {
 Name = freston-sd
 SDPort = 9103
 WorkingDirectory = "/var/lib/bacula"
 Pid Directory = "/run/bacula"
 Maximum Concurrent Jobs = 20
 SDAddress = 10.0.1.6
}

# Definición del servidor para las copias

Director {
 Name = freston-dir
 Password = "admin"
}


Director {
 Name = freston-mon
 Password = "admin"
 Monitor = yes
}

# Definición del disco de las copias

Autochanger {
 Name = FileAutochanger1
 Device = DispositivoCopia
 Changer Command = ""
 Changer Device = /dev/null
}

Device {
 Name = DispositivoCopia
 Media Type = File
 Archive Device = /bacula
 LabelMedia = yes;
 Random Access = Yes;
 AutomaticMount = yes;
 RemovableMedia = no;
 AlwaysOpen = no;
 Maximum Concurrent Jobs = 5
}

# Definición de los mensajes

Messages {
  Name = Standard
  director = sancho-dir = all
}
~~~

Cuando lo hayamos configurado vamos a comprobar que está bien modificado el fichero con el siguiente comando
~~~
sudo bacula-sd /etc/bacula/bacula-sd.conf
~~~

Y reiniciamos el servicio
~~~
sudo systemctl restart bacula-dir
~~~

### Configuración de bacula-dir

Por último vamos a configurar el demonio principal y el más largo de configurar, es decir `bacula-dir`. Para instalarlo deberemos hacerlo junto con un servidor de bases de datos, ya que necesita un gestor de bases de datos, para ello instalaremos antes un mariadb
~~~
sudo apt-get install mariadb-server mariadb-client
~~~

Ahora instalamos los paquetes restantes de bacula
~~~
sudo apt-get install bacula bacula-common-mysql bacula-director-mysql bacula-server
~~~

Ahora editamos el fichero `/etc/bacula/bacula-dir.conf`
~~~
# Definimos el director

Director {
  Name = freston-dir
  DIRport = 9101
  QueryFile = "/etc/bacula/scripts/query.sql"
  WorkingDirectory = "/var/lib/bacula"
  PidDirectory = "/run/bacula"
  Maximum Concurrent Jobs = 20
  Password = "admin" # Contraseña
  Messages = Daemon
  DirAddress = 10.0.1.6
}

# Definimos las tareas

	# Tarea diaria

JobDefs {
  Name = "tarea_diaria" #Nombre de la tarea
  Type = Backup #Tipo de tarea
  Level = Incremental #Tipo de copia
  Client = freston-fd #Donde se ejecuta la tarea
  Schedule = "programa_diario" #Programacion de la tarea
  Pool = Daily #Volumen de almacenamiento
  Storage = VolBackup #Nombre del almacenamiento
  Messages = Standard
  SpoolAttributes = yes
  Priority = 10
  Write Bootstrap = "/var/lib/bacula/%c.bsr"
}

	# Tarea Semanal

JobDefs {
  Name = "tarea_semanal" # Nombre de la tarea
  Type = Backup # Tipo de tarea
  Client = freston-fd # Donde se ejecuta la tarea
  Schedule = "programa_semanal" # Programacion de la tarea
  Pool = Weekly # Volumen de almacenamiento
  Storage = VolBackup # Nombre del almacenamiento
  Messages = Standard
  SpoolAttributes = yes
  Priority = 10
  Write Bootstrap = "/var/lib/bacula/%c.bsr"
}

	# Tarea Mensual

JobDefs {
  Name = "tarea_mensual" # Nombre de la tarea
  Type = Backup # Tipo de tarea
  Client = freston-fd # Donde se ejecuta la tarea
  Schedule = "programa_mensual" # Programacion de la tarea
  Pool = Monthly # Volumen de almacenamiento
  Storage = VolBackup # Nombre del almacenamiento
  Messages = Standard
  SpoolAttributes = yes
  Priority = 10
  Write Bootstrap = "/var/lib/bacula/%c.bsr"
}

# Definición de los trabajos

	# Copia diaria Freston

Job {
 Name = "Backup-Diario-Freston"
 JobDefs = "tarea_diaria"
 Client = "freston-fd"
 FileSet= "Copia_Freston"
}

	# Copia diaria Dulcinea

Job {
 Name = "Backup-Diario-Dulcinea"
 JobDefs = "tarea_diaria"
 Client = "dulcinea-fd"
 FileSet= "Copia_Dulcinea"
}

	# Copia diaria Dulcinea

Job {
 Name = "Backup-Diario-Quijote"
 JobDefs = "tarea_diaria"
 Client = "quijote-fd"
 FileSet= "Copia_Quijote"
}

	# Copia semanal Freston

Job {
 Name = "Backup-Semanal-Freston"
 JobDefs = "tarea_semanal"
 Client = "freston-fd"
 FileSet= "Copia_Freston"
}

	# Copia semanal Dulcinea

Job {
 Name = "Backup-Semanal-Dulcinea"
 JobDefs = "tarea_semanal"
 Client = "dulcinea-fd"
 FileSet= "Copia_Dulcinea"
}

	# Copia semanal Dulcinea

Job {
 Name = "Backup-Semanal-Quijote"
 JobDefs = "tarea_semanal"
 Client = "quijote-fd"
 FileSet= "Copia_Quijote"
}

	# Copia mensual Freston

Job {
 Name = "Backup-Mensual-Freston"
 JobDefs = "tarea_mensual"
 Client = "freston-fd"
 FileSet= "Copia_Freston"
}

	# Copia mensual Dulcinea

Job {
 Name = "Backup-Mensual-Dulcinea"
 JobDefs = "tarea_mensual"
 Client = "dulcinea-fd"
 FileSet= "Copia_Dulcinea"
}

	# Copia mensual Dulcinea

Job {
 Name = "Backup-Mensual-Quijote"
 JobDefs = "tarea_mensual"
 Client = "quijote-fd"
 FileSet= "Copia_Quijote"
}

	# Restauración Freston

Job {
 Name = "restauracion_freston"
 Type = Restore
 Client=freston-fd
 FileSet= "Copia_Freston"
 Storage = VolBackup
 Pool = Vol-Backup
 Messages = Standard
}

	# Restauración Dulcinea

Job {
 Name = "restauracion_dulcinea"
 Type = Restore
 Client=dulcinea-fd
 FileSet= "Copia_Dulcinea"
 Storage = VolBackup
 Pool = Vol-Backup
 Messages = Standard
}

	# Restauración Quijote

Job {
 Name = "restauracion_quijote"
 Type = Restore
 Client=quijote-fd
 FileSet= "Copia_Quijote"
 Storage = VolBackup
 Pool = Vol-Backup
 Messages = Standard
}

# Lista de directorios para hacer la copia de seguridad

	# Lista de directorios de freston

FileSet {
 Name = "Copia_Freston"
 Include {
    Options {
        signature = MD5
        compression = GZIP
    }
    File = /home
    File = /etc
    File = /var
    File = /bacula
 }
 Exclude {
    File = /nonexistant/path/to/file/archive/dir
    File = /proc
    File = /var/cache
    File = /var/tmp
    File = /tmp
    File = /sys
    File = /.journal
    File = /.fsck
 }
}

	# Lista de directorios de dulcinea

FileSet {
 Name = "Copia_Dulcinea"
 Include {
    Options {
        signature = MD5
        compression = GZIP
    }
    File = /home
    File = /etc
    File = /var
 }
 Exclude {
    File = /nonexistant/path/to/file/archive/dir
    File = /proc
    File = /var/cache
    File = /var/tmp
    File = /tmp
    File = /sys
    File = /.journal
    File = /.fsck
 }
}

	# Lista de directorios de quijote

FileSet {
 Name = "Copia_Quijote"
 Include {
    Options {
        signature = MD5
        compression = GZIP
    }
    File = /home
    File = /etc
    File = /var
 }
 Exclude {
    File = /nonexistant/path/to/file/archive/dir
    File = /proc
    File = /var/cache
    File = /var/tmp
    File = /tmp
    File = /sys
    File = /.journal
    File = /.fsck
 }
}

# Definición de programas

	# Programa diario

Schedule {
 Name = "programa_diario"
 Run = Level=Incremental Pool=Daily daily at 02:00
}

	# Programa semanal

Schedule {
 Name = "programa_semanal"
 Run = Level=Full Pool=Weekly sat at 03:00
}

	# Programa mensual

Schedule {
 Name = "programa_mensual"
 Run = Level=Full Pool=Monthly 1st sun at 04:00
}

# Definición de clientes

	# Cliente freston

Client {
 Name = freston-fd
 Address = 10.0.1.6
 FDPort = 9102
 Catalog = mysql-bacula
 Password = "admin"
 File Retention = 90 days
 Job Retention = 6 months
 AutoPrune = yes
}

	# Cliente dulcinea

Client {
 Name = dulcinea-fd
 Address = 10.0.1.7
 FDPort = 9102
 Catalog = mysql-bacula
 Password = "admin"
 File Retention = 90 days
 Job Retention = 6 months
 AutoPrune = yes
}

	# Cliente quijote

Client {
 Name = quijote-fd
 Address = 10.0.2.2
 FDPort = 9102
 Catalog = mysql-bacula
 Password = "admin"
 File Retention = 90 days
 Job Retention = 6 months
 AutoPrune = yes
}

# Definición del almacenamiento

Storage {
 Name = VolBackup
 Address = 10.0.1.6
 SDPort = 9103
 Password = "admin"
 Device = FileAutochanger1
 Media Type = File
 Maximum Concurrent Jobs = 10
}

# Definición de los parámetros de la base de datos

Catalog {
 Name = mysql-bacula
 dbname = "bacula"; DB Address = "localhost"; dbuser = "bacula"; dbpassword = "admin"
}

# Definición de los mensajes

Messages {
  Name = Standard

  mailcommand = "/usr/sbin/bsmtp -h localhost -f \"\(Bacula\) \<%r\>\" -s \"Bacula: %t %e of %c %l\" %r"
  operatorcommand = "/usr/sbin/bsmtp -h localhost -f \"\(Bacula\) \<%r\>\" -s \"Bacula: Intervention needed for %j\" %r"
  mail = root = all, !skipped
  operator = root = mount
  console = all, !skipped, !saved
  append = "/var/log/bacula/bacula.log" = all, !skipped
  catalog = all
}


Messages {
  Name = Daemon
  mailcommand = "/usr/sbin/bsmtp -h localhost -f \"\(Bacula\) \<%r\>\" -s \"Bacula daemon message\" %r"
  mail = root = all, !skipped
  console = all, !skipped, !saved
  append = "/var/log/bacula/bacula.log" = all, !skipped
}

# Definición de los tipos de almacenamiento

	# Pool Daily

Pool {
 Name = Daily
 Use Volume Once = yes
 Pool Type = Backup
 AutoPrune = yes
 VolumeRetention = 10d
 Recycle = yes
}

	# Pool Weekly

Pool {
 Name = Weekly
 Use Volume Once = yes
 Pool Type = Backup
 AutoPrune = yes
 VolumeRetention = 30d
 Recycle = yes
}

	# Pool Monthly

Pool {
 Name = Monthly
 Use Volume Once = yes
 Pool Type = Backup
 AutoPrune = yes
 VolumeRetention = 365d
 Recycle = yes
}

	# Pool Vol-Backup

Pool {
 Name = Vol-Backup
 Pool Type = Backup
 Recycle = yes 
 AutoPrune = yes
 Volume Retention = 365 days 
 Maximum Volume Bytes = 50G
 Maximum Volumes = 100
 Label Format = "Remoto"
}
~~~

Antes de reiniciar el servicio comprobamos que está bien descrito el fichero
~~~
sudo bacula-dir -tc /etc/bacula/bacula-dir.conf
~~~

Le damos formato a nuestro disco duro y lo añadimos al fichero de configuración `/etc/fstab` para que se monta automáticamente
~~~
# Le creamos una partición si no la tiene con fdisk
sudo fdisk /dev/vdb

# Le damos formato ext4
sudo mkfs.ext4 /dev/vdb1

# Creamos el directorio bacula en /
sudo mkdir /bacula

# Le cambiamos el propietario y le damos los permisos necesarios
sudo chown -R bacula. /bacula/
sudo chmod -R 755 /bacula/

# Lo añadimos al fichero /etc/fstab
sudo nano /etc/fstab
[...]
UUID=588ae014-8b2d-4f6b-8e53-e5ac6f622e49       /bacula ext4    errors=remount-ro       0       0

# Aplicamos los cambios
sudo mount -a

# Comprobamos que se han aplicado los cambios correctamente
lsblk
[...]
vdb    254:16   0  10G  0 disk 
└─vdb1 254:17   0  10G  0 part /bacula
~~~

Ahora reiniciamos el servicio de `bacula-dir con el siguiente comando`
~~~
sudo systemctl restart bacula-dir
~~~

### Configuración de bconsole
Ahora, si queremos usar la consola de bacula (`bconsole`) deberemos editar el fichero de configuración `/etc/bacula/bconsole.conf`
~~~
# Configuración de bconsole
Director {
  Name = freston-dir
  DIRport = 9101
  address = 10.0.1.6
  Password = "admin"
}
~~~

Entramos a `bconsole`
~~~
sudo bconsole
Connecting to Director 10.0.1.6:9101
1000 OK: 103 freston-dir Version: 9.4.2 (04 February 2019)
Enter a period to cancel a command.
*
~~~

Podemos comprobar que los clientes están conectados mirando los estados de los mismos
~~~
*status
Status available for:
     1: Director
     2: Storage
     3: Client
     4: Scheduled
     5: Network
     6: All
Select daemon type for status (1-6): 3
The defined Client resources are:
     1: freston-fd
     2: dulcinea-fd
     3: quijote-fd
Select Client (File daemon) resource (1-3): 1
Connecting to Client freston-fd at 10.0.1.6:9102

freston-fd Version: 9.4.2 (04 February 2019)  x86_64-pc-linux-gnu debian 10.5
Daemon started 26-May-21 11:38. Jobs: run=0 running=0.
 Heap: heap=114,688 smbytes=22,011 max_bytes=22,028 bufs=68 max_bufs=68
 Sizes: boffset_t=8 size_t=8 debug=0 trace=0 mode=0,0 bwlimit=0kB/s
 Plugin: bpipe-fd.so 

Running Jobs:
Director connected at: 26-May-21 13:48
No Jobs running.
====

Terminated Jobs:
====
~~~

También podemos ver los trabajos que están programados
~~~
*status
Status available for:
     1: Director
     2: Storage
     3: Client
     4: Scheduled
     5: Network
     6: All
Select daemon type for status (1-6): 4

Scheduled Jobs:
Level          Type     Pri  Scheduled          Job Name           Schedule
=====================================================================================
Incremental    Backup    10  Wed 26-May 02:00   Backup-Diario-Dulcinea programa_diario
Incremental    Backup    10  Wed 26-May 02:00   Backup-Diario-Freston programa_diario
Incremental    Backup    10  Wed 26-May 02:00   Backup-Diario-Quijote programa_diario
Incremental    Backup    10  Thu 27-May 02:00   Backup-Diario-Dulcinea programa_diario
Incremental    Backup    10  Thu 27-May 02:00   Backup-Diario-Freston programa_diario
Incremental    Backup    10  Thu 27-May 02:00   Backup-Diario-Quijote programa_diario
Incremental    Backup    10  Fri 28-May 02:00   Backup-Diario-Dulcinea programa_diario
Incremental    Backup    10  Fri 28-May 02:00   Backup-Diario-Freston programa_diario
Incremental    Backup    10  Fri 28-May 02:00   Backup-Diario-Quijote programa_diario
Incremental    Backup    10  Sat 29-May 02:00   Backup-Diario-Dulcinea programa_diario
Incremental    Backup    10  Sat 29-May 02:00   Backup-Diario-Freston programa_diario
Incremental    Backup    10  Sat 29-May 02:00   Backup-Diario-Quijote programa_diario
Incremental    Backup    10  Sun 30-May 02:00   Backup-Diario-Dulcinea programa_diario
Incremental    Backup    10  Sun 30-May 02:00   Backup-Diario-Freston programa_diario
Incremental    Backup    10  Sun 30-May 02:00   Backup-Diario-Quijote programa_diario
Incremental    Backup    10  Mon 31-May 02:00   Backup-Diario-Dulcinea programa_diario
Incremental    Backup    10  Mon 31-May 02:00   Backup-Diario-Freston programa_diario
Incremental    Backup    10  Mon 31-May 02:00   Backup-Diario-Quijote programa_diario
Incremental    Backup    10  Tue 01-Jun 02:00   Backup-Diario-Dulcinea programa_diario
Incremental    Backup    10  Tue 01-Jun 02:00   Backup-Diario-Freston programa_diario
Incremental    Backup    10  Tue 01-Jun 02:00   Backup-Diario-Quijote programa_diario
Incremental    Backup    10  Wed 02-Jun 02:00   Backup-Diario-Dulcinea programa_diario
Incremental    Backup    10  Wed 02-Jun 02:00   Backup-Diario-Freston programa_diario
Incremental    Backup    10  Wed 02-Jun 02:00   Backup-Diario-Quijote programa_diario
Incremental    Backup    10  Thu 03-Jun 02:00   Backup-Diario-Dulcinea programa_diario
Incremental    Backup    10  Thu 03-Jun 02:00   Backup-Diario-Freston programa_diario
Incremental    Backup    10  Thu 03-Jun 02:00   Backup-Diario-Quijote programa_diario
Incremental    Backup    10  Fri 04-Jun 02:00   Backup-Diario-Dulcinea programa_diario
Incremental    Backup    10  Fri 04-Jun 02:00   Backup-Diario-Freston programa_diario
Incremental    Backup    10  Fri 04-Jun 02:00   Backup-Diario-Quijote programa_diario
====
~~~

Y ya solo faltaría esperar a que estos trabajos se realicen.
