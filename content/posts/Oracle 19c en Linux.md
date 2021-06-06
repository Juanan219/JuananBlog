---
author:
  name: "Juan Antonio Reifs"
date: 2021-06-06
linktitle: Oracle 19c en CentOs
type:
- post
- posts
title: Instalacion y Configuracion de Oracle 19c en CentOs 8
weight: 10
series:
- Hugo 101
images:
tags:
  - Oracle 19c
  - BBDD
  - Instalacion
  - Configuracion
  - Interconexion
  - Listener
---

En este post voy a explicar como instalar oracle 19c en Linux, concretamente en Centos 8.

## Descarga del paquete

Nos dirigimos a la [página de descarga Oracle](https://www.oracle.com/es/database/technologies/oracle-database-software-downloads.html#19c) y nos descargamos la versión del paquete Linux x86-64 RPM. Esta acción deberemos realizarla desde un entorno gráfico ya que la descarga de la página de Oracle requiere una autentificación con una cuenta de Oracle, por lo que no se va a poder descargar con `wget`.

En mi caso he desargado el paquete `.rpm` desde mi máquina anfitriona y la he pasado a la máquina virtual por `scp`. Una vez que tenemos el paquete en nuestra máquina comenzamos con los pasos de la instalación.

## Preparando el escenario para la instalación

Antes de instalar directamente el paquete que nos hemos descargado vamos a instalar el paquete de la preinstalación que tiene Oracle, el cual nos prepara nuestro sistema para la instalación de Oracle.
~~~
sudo dnf install https://yum.oracle.com/repo/OracleLinux/OL8/baseos/latest/x86_64/getPackage/oracle-database-preinstall-19c-1.0-1.el8.x86_64.rpm
~~~

## Instalación y configuración de Oracle

Ya que tenemos todo nuestro sistema bien configurado para la instalación de oracle, lo vamos a instalar directamente con el comando `rpm`
~~~
sudo rpm -Uhv  oracle-database-ee-19c-1.0-1.x86_64.rpm
~~~

Este comando tarda unos escasos minutos, ya que es el que instala todo el gestor de base de datos y cuando finaliza nos dice que si queremos una base de datos de ejemplo en Oracle, ejecutemos el comando que se nos muestra, así que vamos a ejecutarlo para que cree la base de datos de ejemplo, ya que esa base de datos nos es muy útil en algunas ocasiones si estamos aprendiendo a usar Oracle.
~~~
sudo /etc/init.d/oracledb_ORCLCDB-19c configure
~~~

Cuando la base de datos se haya terminado de configurar ya podremos usar oracle desde `sqlplus` accediendo a la ruta `/opt/oracle/product/19c/dbhome_1/bin/`, pero para que nos sea más sencillo de usar el comando vamos a editar el fichero `.bash_profile` del usuario `oracle` y vamos a añadir las siguientes líneas, de tal forma que el fichero `~/.bash_profile` quedaría tal que así
~~~
[oracle@oracle1 ~]$ nano .bash_profile

# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

umask 022
export ORACLE_SID=ORCLCDB
export ORACLE_BASE=/opt/oracle/oradata
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export PATH=$PATH:$ORACLE_HOME/bin

# User specific environment and startup programs
~~~

Guardamos el fichero y aplicamos los cambios haciendo que el sistema vuelva a leer dicho fichero (ya que este fichero se lee en cada inicio de sesión)
~~~
source ~/.bash_profile
~~~

Una vez que hayamos configurado esto ya podremos acceder a `sqlplus` como `sysdba` de esta forma
~~~
[oracle@oracle1 ~]$ sqlplus / as sysdba

SQL*Plus: Release 19.0.0.0.0 - Production on Sat Jun 5 12:56:55 2021
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Connected to an idle instance.

SQL>
~~~

Para comprobar que está todo correctamente ejecutaremos una consulta para mostrar el nombre de la instancia de oracle, el hostname de nuestra máquina y la versión de oracle
~~~
SQL> SELECT instance_name, host_name, version FROM v$instance;
SELECT instance_name, host_name, version FROM v$instance
*
ERROR at line 1:
ORA-01034: ORACLE not available
Process ID: 0
Session ID: 0 Serial number: 0
~~~

Pero como podemos ver, nos aparece que ORACLE no está disponible, esto se debe a que aunque tengamos instalado el gestor de bases de datos, la instancia no está iniciada, lo cual se resuelve escribiendo el comando `startup` dentro de `sqlplus` y volveremos a ejecutar el mismo comando para comprobar, que efectivamente, está todo en orden y listo para usarse
~~~
SQL> startup

SQL> SELECT instance_name, host_name, version FROM v$instance;

INSTANCE_NAME
----------------
HOST_NAME
----------------------------------------------------------------
VERSION
-----------------
ORCLCDB
oracle1
19.0.0.0.0
~~~

## Creación de mi usuario

En Oracle 19c tiene una novedad con respecto a las versiones anteriores de Oracle y es que en esta versión se diferencian dos tipos de bases de datos:

* **Container Database (CDB)**

* **Pluggabe Database (PDB)**

Por eso también se diferencian dos tipos de usuarios:

* **Common User:** Pertenecen tanto a las *CDB* como a las *PDB* y se crean con la sintáxis que conocemos de otras versiones de Oracle `create user c##[nombre] indentified by [contraseña]`.

* **Local user:** Estos usuarios pertenecen solo a las *PDB*, es decir, únicamente se les pueden añadir permisos a las *PDB* que existen. Estos usuarios se crean estableciendo la *PDB* como variable de sesión (`alter session set container = [Nombre PDB]`) y después creándolo con la sitáxis de un usuario normal.

Una vez hemos explicado esto, vamos a proceder a crear un *Common User* para poder usarlo en la *CDB* como en futuras *PDB*.
~~~
SQL> create user c##juanan identified by juanan;

Usuario creado.
~~~

Ahora le asignaremos todos los privilegios para poder trbaajar con este usuario sin problemas ni restricciones
~~~
SQL> grant all privileges to c##juanan;

Concesion terminada correctamente.
~~~

Por último, nos vamos a conectar a nuestro nuevo usuario para comprobar que se ha creado correctamente
~~~
[oracle@oracle1 ~]$ sqlplus c##juanan/juanan

SQL*Plus: Release 19.0.0.0.0 - Production on Sat Jun 5 13:21:56 2021
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Hora de Ultima Conexion Correcta: Sab Jun 05 2021 13:21:29 -04:00

Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL>
~~~

## Configuración de Oracle para el uso remoto

Vamos a configurar el `listener` de Oracle, para ello necesitaremos la ip de nuestra máquina
~~~
[oracle@oracle1 ~]$ ip a
[...]
    inet 192.168.1.14/24 brd 192.168.1.255 scope global dynamic noprefixroute enp0s3
[...]
~~~

El ya mencionado `listener` de Oracle usa el puerto `1521`, pero si miramos los puertos que tenemos funcionando en nuestra máquina, ninguno se corresponde con este
~~~
[oracle@oracle1 ~]$ netstat -tln
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State      
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN     
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN     
tcp6       0      0 :::21975                :::*                    LISTEN     
tcp6       0      0 :::111                  :::*                    LISTEN     
tcp6       0      0 :::22                   :::*                    LISTEN 
~~~

Esto se debe a que todavía nuestro `listener` está parado y sin configurar así que vamos a pasar a la configuración:

1. Comprobar que tenemos bien el FQDN de nuestra máquina, para comprobarlo usamos el comando `hostname -f`
~~~
[oracle@oracle1 ~]$ hostname -f
oracle1.home
~~~

En mi caso no lo tengo bien configurado, ya que esta máquina la acabo de crear. Mi dominio (ficticio) es `juanan.es` por lo que deberé de añadirlo en el fichero `/etc/hosts`
~~~
[oracle@oracle1 ~]$ sudo nano /etc/hosts

[...]
192.168.1.49   oracle1.juanan.es   oracle
[...]
~~~

Guardamos el fichero y miramos si el hostname lo tenemos correctamente configurado usando el comando `hostname`
~~~
[oracle@oracle1 ~]$ hostname
oracle1
~~~

Yo lo tengo bien configurado, pero en el caso de que no lo tengamos, simplemente editamos el fichero `/etc/hostname` y le cambiamos el nombre por el que queramos.

Por último reiniciamos la máquina y ya tendríamos nuestro hostname y FQDN listo
~~~
[oracle@oracle1 ~]$ hostname -f
oracle1.juanan.es
[oracle@oracle1 ~]$ hostname
oracle1
~~~

2. Vamos a modificar el fichero `listerner.ora`, el cual está ubicado en `$ORACLE_HOME/network/admin/listener.ora`. Cuando lo abramos nos encontraremos con el siguiente contenido
~~~
# listener.ora Network Configuration File: /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
# Generated by Oracle configuration tools.

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = oracle1.home)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
~~~

En este caso tenemos de manera predeterminada escuchando por el FQDN predeterminado de mi máquina (el cual cambién por mi IP y el FQDN de mi dominio ficticio) y en el puerto 1521 (el puerto predeterminado del listener), el cual dejaremos así, por lo que solo cambiaremos el FQDN por el que hemos puesto en el fichero `/etc/hosts` de tal manera que el fichero quedaría así
~~~
# listener.ora Network Configuration File: /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
# Generated by Oracle configuration tools.

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = oracle1.juanan.es)(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )
~~~

Cuando hayamos guardado los cambios vamos a ejecutar el comando para iniciar el listener
~~~
[oracle@oracle1 ~]$ lsnrctl start

LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 05-JUN-2021 14:14:05

Copyright (c) 1991, 2019, Oracle.  All rights reserved.

Starting /opt/oracle/product/19c/dbhome_1/bin/tnslsnr: please wait...

TNSLSNR for Linux: Version 19.0.0.0.0 - Production
System parameter file is /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
Log messages written to /opt/oracle/diag/tnslsnr/oracle1/listener/alert/log.xml
Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=oracle1.juanan.es)(PORT=1521)))
Listening on: (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=oracle1.juanan.es)(PORT=1521)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 19.0.0.0.0 - Production
Start Date                05-JUN-2021 14:14:06
Uptime                    0 days 0 hr. 0 min. 0 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Listener Parameter File   /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
Listener Log File         /opt/oracle/diag/tnslsnr/oracle1/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=oracle1.juanan.es)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))
The listener supports no services
The command completed successfully
~~~

Como podemos ver en los mensajes que nos muestra por pantalla el comando, este se ha completado satisfactoriamente (`The command completed successfully`), pero nos avisa de que no está soportando ningún servicio (`The listener supports no services`), esto se debe a que hemos arrancado el listener después que la base de datos, por lo que la base de datos no le ha notificado tpdavía que está activa, para ello deberemos esperar alrededor de uno dos minutos. Cuando pase este tiempo y ejecutemos el comando `lstnrctl status` podremos ver de que ya se encuentra activo
~~~
[oracle@oracle1 ~]$ lsnrctl status

LSNRCTL for Linux: Version 19.0.0.0.0 - Production on 05-JUN-2021 14:20:13

Copyright (c) 1991, 2019, Oracle.  All rights reserved.

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=oracle1.juanan.es)(PORT=1521)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 19.0.0.0.0 - Production
Start Date                05-JUN-2021 14:19:33
Uptime                    0 days 0 hr. 0 min. 39 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Listener Parameter File   /opt/oracle/product/19c/dbhome_1/network/admin/listener.ora
Listener Log File         /opt/oracle/diag/tnslsnr/oracle1/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=oracle1.juanan.es)(PORT=1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcps)(HOST=oracle1.juanan.es)(PORT=5500))(Security=(my_wallet_directory=/opt/oracle/oradata/admin/ORCLCDB/xdb_wallet))(Presentation=HTTP)(Session=RAW))
Services Summary...
Service "ORCLCDB" has 1 instance(s).
  Instance "ORCLCDB", status READY, has 1 handler(s) for this service...
Service "ORCLCDBXDB" has 1 instance(s).
  Instance "ORCLCDB", status READY, has 1 handler(s) for this service...
Service "c40852d66a8384dbe0550a0027b5e54f" has 1 instance(s).
  Instance "ORCLCDB", status READY, has 1 handler(s) for this service...
Service "orclpdb1" has 1 instance(s).
  Instance "ORCLCDB", status READY, has 1 handler(s) for this service...
The command completed successfully
~~~

Por último vamos a configurar una regla en el cortafuegos de nuestro sistema, para ello ejecutaremos la siguiente regla
~~~
[oracle@oracle1 ~]$ sudo firewall-cmd --permanent --add-port=1521/tcp
~~~

Recargamos el cortafuegos
~~~
[oracle@oracle1 ~]$ sudo firewall-cmd --reload
~~~

Si listamos todas las reglas del cortafuegos podremos ver que se ha añadido correctamente
~~~
[oracle@oracle1 ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3
  sources: 
  services: cockpit dhcpv6-client ssh
  ports: 1521/tcp
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules:
~~~

## Prueba de funcionamiento

Ahora que tenemos todo listo, vamos a comprobar que todo funciona correctamente, para ello vamos a crear una tabla de prueba en la máquina `oracle1`
~~~
// Creamos la tabla de prueba

create table prueba
(Campo1 varchar2(10),
 Campo2 varchar2(10),
 Campo3 varchar2(10),
 constraint pk_campo1 primary key (Campo1));

// Insertamos los datos de prueba

insert into prueba
values('Texto 1', 'Texto 2', 'Texto 3');

insert into prueba
values('Texto 4', 'Texto 5', 'Texto 6');

insert into prueba
values('Texto 7', 'Texto 8', 'Texto 9');

insert into prueba
values('Texto 10', 'Texto 11', 'Texto 12');
~~~

Esta sería la consulta desde la máquina `oracle1`
~~~
SQL> select * from prueba;

CAMPO1	   CAMPO2     CAMPO3
---------- ---------- ----------
Texto 1    Texto 2    Texto 3
Texto 4    Texto 5    Texto 6
Texto 7    Texto 8    Texto 9
Texto 10   Texto 11   Texto 12
~~~

Para comprobar la conectividad, vamos a realizar una prueba de ping con una herramienta que trae Oracle, esta herramienta es `tnsping`, la cual sirva para comprobar la conectividad con el listener.
~~~
[oracle@oracle2 ~]$ tnsping oracle1

TNS Ping Utility for Linux: Version 19.0.0.0.0 - Production on 06-JUN-2021 12:37:11

Copyright (c) 1997, 2019, Oracle.  All rights reserved.

Used parameter files:
/opt/oracle/product/19c/dbhome_1/network/admin/sqlnet.ora

Used HOSTNAME adapter to resolve the alias
Attempting to contact (DESCRIPTION=(CONNECT_DATA=(SERVICE_NAME=))(ADDRESS=(PROTOCOL=tcp)(HOST=192.168.1.49)(PORT=1521)))
OK (0 msec)
~~~

Como podemos comprobar, hemos comprobado la conectividad desde la máquina `oracle2` a la máquina `oracle1`. Ahora vamos a conectarnos a nuestro usuario `juanan` de manera remota, es decir, de `oracle2` a `oracle1` y haremos un listado de todas las tablas que tenemos en dicho usuario y veremos el contenido de la tabla que hemos creado anteriormente
~~~
[oracle@oracle2 ~]$ sqlplus c##juanan/juanan@oracle1/ORCLCDB

SQL*Plus: Release 19.0.0.0.0 - Production on Sun Jun 6 12:52:41 2021
Version 19.3.0.0.0

Copyright (c) 1982, 2019, Oracle.  All rights reserved.

Hora de Ultima Conexion Correcta: Dom Jun 06 2021 12:25:32 -04:00

Conectado a:
Oracle Database 19c Enterprise Edition Release 19.0.0.0.0 - Production
Version 19.3.0.0.0

SQL> select * from cat;

TABLE_NAME
--------------------------------------------------------------------------------
TABLE_TYPE
-----------
PRUEBA
TABLE

SQL> select * from prueba;

CAMPO1	   CAMPO2     CAMPO3
---------- ---------- ----------
Texto 1    Texto 2    Texto 3
Texto 4    Texto 5    Texto 6
Texto 7    Texto 8    Texto 9
Texto 10   Texto 11   Texto 12
~~~

Como podemos comprobar en las salidas de los comandos anteriores, nos hemos conectado a la máquina `oracle1` desde `oracle2`, hemos listado las tablas disponibles en el usuario `juanan` y hemos listado el contenido de la tabla `prueba`.
