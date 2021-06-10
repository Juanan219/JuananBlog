---
author:
  name: "Juan Antonio Reifs"
date: 2021-06-10
linktitle: Gestion del alacenamiento en BBDD
type:
- post
- posts
title: Practica de gestion del almacenamiento en Bases de Datos
weight: 10
series:
- Hugo 101
images:
tags:
  - Almacenamiento
  - Practica
  - BBDD
  - Oracle
  - MySQL
  - PostgreSQL
  - MongoDB
---

Esta práctica se va a dividir en tres partes:

* **Oracle**

* **PostgreSQL**

* **MariaDB**

## Oracle

1. **Muestra los espacios de tablas existentes en tu base de datos y la ruta de los ficheros que los componen. ¿Están las extensiones gestionadas localmente o por diccionario?**

Para poder ver los `tablespaces` de nuestro sistema deberemos ejecutar el siguiente comando
~~~
SQL> col FILE_NAME form A40;
~~~

Después ejecutamos esta consulta
~~~
SQL> select FILE_NAME, TABLESPACE_NAME
from dba_data_files
UNION
select FILE_NAME, TABLESPACE_NAME
from dba_temp_files;

FILE_NAME				 TABLESPACE_NAME
---------------------------------------- ------------------------------
/opt/oracle/oradata/ORCLCDB/sysaux01.dbf SYSAUX
/opt/oracle/oradata/ORCLCDB/system01.dbf SYSTEM
/opt/oracle/oradata/ORCLCDB/temp01.dbf	 TEMP
/opt/oracle/oradata/ORCLCDB/undotbs01.db UNDOTBS1
f

/opt/oracle/oradata/ORCLCDB/users01.dbf  USERS
~~~

2. **Usa la vista del diccionario de datos `v$datafile` para mirar cuando fue la última vez que se ejecutó el proceso `CKPT` en tu base de datos.**
~~~
SQL> select max(CHECKPOINT_TIME) from v$datafile;

MAX(CHEC
--------
10/06/21
~~~

3. **Intenta crear el tablespace TS1 con un fichero de 2M en tu disco que crezca automáticamente cuando sea necesario. ¿Puedes hacer que la gestión de extensiones sea por diccionario? Averigua la razón.**
~~~
SQL> create tablespace TS1
datafile 'TS1.dbf'
size 2M
autoextend on;  2    3    4  

Tablespace creado.
~~~

Si en la instalación se ha especificado la gestión manual del almacenamiento, se puede configurar para que la gestión de las extensiones sea por diccionario, pero en mi caso no es así.

4. **Averigua el tamaño de un bloque de datos en tu base de datos. Cámbialo al doble del valor que tenga.**
~~~
SQL> select distinct bytes/blocks
from user_segments; 

BYTES/BLOCKS
------------
	8192
~~~

Oracle no nos permite modificar el tamaño de bloques de un `tablespace` ya creado, pero sí que podemos modificar un valor del sistema para que a partir de ahora los bloques de los tablespaces tenga el tamaño que nosotros queramos. Esto se haría de la siguiente manera
~~~
SQL> ALTER SYSTEM SET DB_16k_CACHE_SIZE=100M;

Sistema modificado.
~~~

Reiniciamos la base de datos para que se apliquen los cambios
~~~
SQL> shutdown 
Base de datos cerrada.
Base de datos desmontada.
Instancia ORACLE cerrada.
SQL> startup
Instancia ORACLE iniciada.

Total System Global Area 1577055360 bytes
Fixed Size		    9135232 bytes
Variable Size		  939524096 bytes
Database Buffers	  620756992 bytes
Redo Buffers		    7639040 bytes
Base de datos montada.
Base de datos abierta.
~~~

Ahora creamos el tablespace y ejecutamos la consulta para ver los bloques
~~~
SQL> create tablespace prueba
datafile '/home/oracle/prueba.img'
size 1M blocksize 16K;  2    3  

Tablespace creado.

SQL> select tablespace_name, block_size
from dba_tablespaces
where tablespace_name='PRUEBA';  2    3  

TABLESPACE_NAME 	       BLOCK_SIZE
------------------------------ ----------
PRUEBA				    16384
~~~

## PostgreSQL

6. **Averigua si existe el concepto de tablespace en Postgres, en qué consiste y las diferencias con los tablespaces de ORACLE.**

Sí, los *tablespaces* existen en postgres, pero como todo en postgres, tiene ciertas diferencias con respecto a los *tablespaces* de Oracle, ya que estos permiten la segmentación y distribución física de los datos al poder ubicarlos en directorios diferentes. Esta no es la única diferencia, ya que por ejemplo, en Oracle se usan los llamados *datafiles* y en postgres, como hemos dicho anteriormente, usamos directorios. Otra de las diferencias más esenciales entre estos dos gestores de bases de datos es que Oracle nos permite realizar una definición más precisa de estos *tablespaces*, mientras que en postgres no podemos ni definir siquiera un tamaño máximo.

## MySQL

7. **Averigua si pueden establecerse claúsulas de almacenamiento para las tablas o los espacios de tablas en MySQL.**

En MySQL podemos usar una serie de parámetros a la hora de crear tablas para definir aspectos como el número máximo de registros, la ruta donde se ubicará el fichero que contendrá dicha tabla, etc... Si queremos ver todos los parámetros que podemos usar a la hora de crear tablas, podemos ejecutar la siguiente instrucción
~~~
MariaDB [(none)]> create table help;
[...]
table_options:
    table_option [[,] table_option] ...

table_option:
    ENGINE [=] engine_name
  | AUTO_INCREMENT [=] value
  | AVG_ROW_LENGTH [=] value
  | [DEFAULT] CHARACTER SET [=] charset_name
  | CHECKSUM [=] {0 | 1}
  | [DEFAULT] COLLATE [=] collation_name
  | COMMENT [=] 'string'
  | CONNECTION [=] 'connect_string'
  | DATA DIRECTORY [=] 'absolute path to directory'
  | DELAY_KEY_WRITE [=] {0 | 1}
  | INDEX DIRECTORY [=] 'absolute path to directory'
  | INSERT_METHOD [=] { NO | FIRST | LAST }
  | KEY_BLOCK_SIZE [=] value
  | MAX_ROWS [=] value
  | MIN_ROWS [=] value
  | PACK_KEYS [=] {0 | 1 | DEFAULT}
  | PASSWORD [=] 'string'
  | ROW_FORMAT [=] {DEFAULT|DYNAMIC|FIXED|COMPRESSED|REDUNDANT|COMPACT}
  | TABLESPACE tablespace_name [STORAGE {DISK|MEMORY|DEFAULT}]
  | UNION [=] (tbl_name[,tbl_name]...)

partition_options:
    PARTITION BY
        { [LINEAR] HASH(expr)
        | [LINEAR] KEY(column_list)
        | RANGE{(expr) | COLUMNS(column_list)}
        | LIST{(expr) | COLUMNS(column_list)} }
    [PARTITIONS num]
    [SUBPARTITION BY
        { [LINEAR] HASH(expr)
        | [LINEAR] KEY(column_list) }
      [SUBPARTITIONS num]
    ]
    [(partition_definition [, partition_definition] ...)]

partition_definition:
    PARTITION partition_name
        [VALUES 
            {LESS THAN {(expr | value_list) | MAXVALUE} 
            | 
            IN (value_list)}]
        [[STORAGE] ENGINE [=] engine_name]
        [COMMENT [=] 'comment_text' ]
        [DATA DIRECTORY [=] 'data_dir']
        [INDEX DIRECTORY [=] 'index_dir']
        [MAX_ROWS [=] max_number_of_rows]
        [MIN_ROWS [=] min_number_of_rows]
        [TABLESPACE [=] tablespace_name]
        [NODEGROUP [=] node_group_id]
        [(subpartition_definition [, subpartition_definition] ...)]

subpartition_definition:
    SUBPARTITION logical_name
        [[STORAGE] ENGINE [=] engine_name]
        [COMMENT [=] 'comment_text' ]
        [DATA DIRECTORY [=] 'data_dir']
        [INDEX DIRECTORY [=] 'index_dir']
        [MAX_ROWS [=] max_number_of_rows]
        [MIN_ROWS [=] min_number_of_rows]
        [TABLESPACE [=] tablespace_name]
        [NODEGROUP [=] node_group_id]

select_statement:
    [IGNORE | REPLACE] [AS] SELECT ...   (Some valid select statement)

CREATE TABLE creates a table with the given name. You must have the
CREATE privilege for the table.

Rules for permissible table names are given in
https://mariadb.com/kb/en/identifier-names/. By default,
the table is created in the default database, using the InnoDB storage
engine. An error occurs if the table exists, if there is no default
database, or if the database does not exist.

URL: https://mariadb.com/kb/en/create-table/
~~~

En un MySQL normal, no podemos crear *tablespaces*, si queremos disponer de esta funcionalidad, deberemos tener instalada la versión de MySQL de alta disponibilidad, llamada *MySQL NDB*. Si disponemos de esta versión instalada, la sintáxis sería como la que se encuentra en [su documentación oficial](https://dev.mysql.com/doc/refman/5.7/en/create-tablespace.html).

## MongoDB

8. **Averigua si existe el concepto de índice en MongoDB y las diferencias con los índices de ORACLE. Explica los distintos tipos de índice que ofrece MongoDB.**

MongoDB nos ofrece diferentes tipos de índices, dependiendo de la funcionalidad que queramos, es decir, existen índices aplicados sobre un campo o varios, en orden ascendente, descendente, etc... y en Oracle disponemos de un tipo de índice, el cual contiene la mayoría de estas funciones.

* **Simples:** Se aplican a un solo campo y usando los valores `1` o `-1` indicamos si queremos listar de forma ascendente o descendente. Ejemplo:
~~~
db.alumnos.createIndex( { "nombre" : 1 } )
~~~

* **Compound:** Se aplican sobre varios campos y se usan de la misma forma que los *simples*, por lo que en cada campo podemos especificar el orden de la búsqueda. Por ejemplo, si queremos listar los alumnos en orden ascendente pero las notas en orden descendente ejecutaremos la siguiente consulta
~~~
db.alumnos.createIndex( { "nombre" : 1, "nota": -1 } ) 
~~~

* **Multikey:** Normalmente cuando MongoDB recorre un documento, lo hace con *arrays*, recorre cada uno de sus valores, mientras que si usamos este tipo de índices, podemos asegurarnos que soo recorra aquellos *arrays* que contengan los valores que hemos especificado.

* **Unique:** Elimina los campos duplicados, esta función también se encuentra en oracle cuando realizamos una consulta con el parámetro `distinct`.
~~~
db.alumnos.createIndex( { "nota" : 1 }, {"unique":true} )
~~~

9. **Explica en qué consiste el sharding en MongoDB.**

El *sharding* (o fragmentación) es una función de escalado horizontal que nos ofrece MongoDB, ya que si no es posible almacenar la totalidad de los datos en un solo servidor, este nos permite repartir dicha información en varios de estos, de tal forma de que cada servidor tenga una fracción de toda la información de la que disponemos en nuestra base de datos. Al clúster de servidores que están configurados de esta forma se le llama *sharded cluster* (o en español, conjunto fragmentado).

Para asegurar la alta disponibilidad de dicha información se monta cada shard de forma replicada, así incrementamos la tolerancia a fallos de cada servidor por separado.
