---
author:
  name: "Juan Antonio Reifs"
date: 2021-06-10
linktitle: Auditorias BBDD
type:
- post
- posts
title: Practica de Auditoria de Bases de Datos
weight: 10
series:
- Hugo 101
images:
tags:
  - Bases de datos
  - Auditorias
  - Oracle
  - 19c
  - Postgres
  - MySQL
  - MariaDB
  - MongoDB
---

1. **Activa desde SQLPlus la auditoría de los intentos de acceso fallidos al sistema. Comprueba su funcionamiento.**

Oracle, por defecto, tiene las auditorías activadas, así que configuraremos que registre los accesos no válidos ejecutamos la siguiente instrucción
~~~
SQL> audit create session whenever not successful;

Auditoria terminada correctamente.
~~~

Realizamos la prueba primero saliendo de la sesión del usuario `system` y accediendo con una cuenta con la contraseña incorrecta
~~~
SQL> disconnect

SQL> connect c##juanan1/prueba
ERROR:
ORA-01017: nombre de usuario/contrase?a no validos; conexion denegada
~~~

Volvemos a iniciar con el usuario `system` y comprobamos el log que ha registrado la auditoría
~~~
SQL> select os_username, username, timestamp, returncode
from dba_audit_session;  2  

OS_USERNAME
--------------------------------------------------------------------------------
USERNAME
--------------------------------------------------------------------------------
TIMESTAM RETURNCODE
-------- ----------
oracle
C##JUANAN1
09/06/21       1017
~~~

2. **Realiza un procedimiento en PL/SQL que te muestre los accesos fallidos junto con el motivo de los mismos, transformando el código de error almacenado en un mensaje de texto comprensible.**
~~~
# Iniciamos sesión como sysdba, ya que como system nos dará error

SQL> connect / as sysdba;

# Creamos una función que convierta los códigos numéricos en texto

create or replace function cod_texto (p_codigo NUMBER)
return varchar2
is
	v_texto varchar2(30);
begin
	if p_codigo = 28000
	then
		v_texto := 'Cuenta Bloqueada';
	elsif p_codigo = 1017
	then
		v_texto := 'Contraseña incorrecta';
	else
		v_texto := 'Error desconocido';
	end if;
	return v_texto;
end;
/

# Creamos el procedimiento que convierte los códigos de error en texto

create or replace procedure logins_erroneos
is
	cursor c_registro
	is
	select returncode, os_username, username, timestamp
	from dba_audit_session
	where action_name = 'LOGON'
	and returncode != 0
	order by timestamp;

	v_texto varchar2(30);
begin
	for v_registro in c_registro loop
		v_texto := cod_texto(v_registro.returncode);
		dbms_output.put_line('- Usuario del sistema: '||v_registro.os_username|| '. Usuario de error: '||v_registro.username|| '. Hora: '||v_registro.timestamp|| '. Error: '||v_texto||'. Cod: '||v_registro.returncode);
	end loop;
end;
/
~~~

3. **Activa la auditoría de las operaciones DML realizadas por SCOTT. Comprueba su funcionamiento.**

Activamos la auditoría en el usuario scot para todas las operaciones DML
~~~
SQL> audit insert table, update table, delete table by scott;

Auditoria terminada correctamente.
~~~

Ahora nos conectamos como scott y en mi caso, para no tocar el esquema que tenemos voy a crear una tabla de prueba
~~~
SQL> connect scott/TIGER
Conectado.

SQL> create table prueba
(Columna1 varchar2(10),
 Columna2 varchar2(10),
 constraint pk_columna1 primary key (Columna1));  2    3    4  

Tabla creada.
~~~

Vamos a realizar todas las acciones que debe registrar la auditoría
~~~
# Insertar datos en la tabla

SQL> insert into prueba
	values('Texto 1', 'Texto 2');  2  

1 fila creada.

# Modificar la tabla

SQL> alter table prueba
add Columna3 varchar2(10);  2  

Tabla modificada.

# Eliminar un registro de la tabla

SQL> delete from prueba
	where Columna1 = 'Texto 1';  2  

1 fila suprimida.
~~~

Nos conectamos como `sysdba` y comprobamos la auditoría de `SCOTT`
~~~
SQL> connect / as sysdba
Conectado.

SQL> select os_username, username, action_name, timestamp
from dba_audit_object
where username='SCOTT';  2    3  

OS_USERNAME
--------------------------------------------------------------------------------
USERNAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAM
---------------------------- --------
oracle
SCOTT
INSERT			     09/06/21

oracle
SCOTT
DELETE			     09/06/21

OS_USERNAME
--------------------------------------------------------------------------------
USERNAME
--------------------------------------------------------------------------------
ACTION_NAME		     TIMESTAM
---------------------------- --------
~~~

4. **Realiza una auditoría de grano fino para almacenar información sobre la inserción de empleados del departamento 10 en la tabla emp de scott.**

Creamos un procedimiento para controlar la insercción de empleados del departamento 10.
~~~
SQL> begin
	DBMS_FGA.ADD_POLICY (
		object_schema      =>  'SCOTT',
		object_name        =>  'EMP',
		policy_name        =>  'InsertEmp1',
		audit_condition    =>  'DEPTNO = 10',
		statement_types    =>  'INSERT');
end;
/  2    3    4    5    6    7    8    9  

Procedimiento PL/SQL terminado correctamente.
~~~

Para comprobar su funcionamiento, vamos a conectarnos como `SCOTT` y me voy a insertar como empleado
~~~
SQL> connect scott/TIGER
Conectado.
SQL> insert into emp
	values(115, 'JUANAN', 'TIC', NULL,TO_DATE('21-07-1998','DD-MM-YYYY'), 90000, NULL, 10);  2  

1 fila creada.
~~~

Ahora volvemos a iniciar sesióln como `sysdba` y comprobamos los registros
~~~
SQL> select db_user, object_name, policy_name, sql_text
from dba_fga_audit_trail;  2  

DB_USER
--------------------------------------------------------------------------------
OBJECT_NAME
--------------------------------------------------------------------------------
POLICY_NAME
--------------------------------------------------------------------------------
SQL_TEXT
--------------------------------------------------------------------------------
SCOTT
EMP
INSERTEMP1
insert into emp
	values(115, 'JUANAN', 'TIC', NULL,TO_DATE('21-07-1998','DD-MM-YYYY'), 90000, NULL, 10)
~~~

5. **Explica la diferencia entre auditar una operación by access o by session.**

La principal diferencia es que si auditamos `by access`, la auditoría guarda esa operación tantas veces como nosotros la repitamos, mientras que si auditamos `by session`, por muchas veces que nosotros repitamos una misma operación, esta solo se almacenará una sola vez.

6. **Documenta las diferencias entre los valores db y db, extended del parámetro audit_trail de ORACLE. Demuéstralas poniendo un ejemplo de la información sobre una operación concreta recopilada con cada uno de ellos.**

* **Valor `db`:** Este activa la auditoría y los datos se almacenarán en la taba `SYS.AUD$`.

* **Valor `db, extended`:** A parte de almacenar los datos en la misma tabla que el anterior valor (en `SYS.AUD$`) también escribirá los datos en las columnas `SQLBIND` y `SQLTEXT` de dicha tabla.

Vamos a ver el estado que tiene nuestro `audit_trail`
~~~
SQL> show parameter audit;

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
[...]
audit_trail			     string	 DB
[...]
~~~

Como podemos ver, tiene el valor `DB`. Si queremos activar el valor `DB, EXTENDED`, deberemos ejecutar la siguiente instrucción
~~~
SQL> alter system set audit_trail=db,extended scope=spfile;

Sistema modificado.
~~~

Para que se apliquen los cambios deberemos reinciar la base de datos, para ello haremos uso del comando `shutdown` y volveremos a iniciarla con `startup`, para más tarde volver a mostrar los parámetros de `audit`
~~~
# Apagamos la base de datos

SQL> shutdown
Base de datos cerrada.
Base de datos desmontada.
Instancia ORACLE cerrada.

# Volvemos a encenderla

SQL> startup
Instancia ORACLE iniciada.

Total System Global Area 1577055360 bytes
Fixed Size		    9135232 bytes
Variable Size		  939524096 bytes
Database Buffers	  620756992 bytes
Redo Buffers		    7639040 bytes
Base de datos montada.
Base de datos abierta.

# Mostramos los parámetros

SQL> show parameter audit;

NAME				     TYPE	 VALUE
------------------------------------ ----------- ------------------------------
[...]
audit_trail			     string	 DB, EXTENDED
[...]
~~~

Como podemos ver, se ha cambiado del valor `DB` a `DB,EXTENDED`ç

7. **Localiza en Enterprise Manager las posibilidades para realizar una auditoría e intenta repetir con dicha herramienta los apartados 1, 3 y 4.**

8. **Averigua si en Postgres se pueden realizar los apartados 1, 3 y 4. Si es así, documenta el proceso adecuadamente.**

Para realizar la auditoría en Postgres realizamos los siguientes pasos:

* Creamos la tabla de auditoría
~~~
CREATE schema audit;
REVOKE CREATE ON schema audit FROM public;
 
CREATE TABLE audit.logged_actions (
    schema_name text NOT NULL,
    TABLE_NAME text NOT NULL,
    user_name text,
    action_tstamp TIMESTAMP WITH TIME zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    action TEXT NOT NULL CHECK (action IN ('I','D','U')),
    original_data text,
    new_data text,
    query text
) WITH (fillfactor=100);
 
REVOKE ALL ON audit.logged_actions FROM public; 
~~~

* Modificamos los permisos en la tabla que acabamos de crear
~~~
CREATE INDEX logged_actions_schema_table_idx 
ON audit.logged_actions(((schema_name||'.'||TABLE_NAME)::TEXT));
 
CREATE INDEX logged_actions_action_tstamp_idx 
ON audit.logged_actions(action_tstamp);
 
CREATE INDEX logged_actions_action_idx 
ON audit.logged_actions(action);
~~~

* Creamos la función de auditoría
~~~
CREATE OR REPLACE FUNCTION audit.if_modified_func() RETURNS TRIGGER AS $body$
DECLARE
    v_old_data TEXT;
    v_new_data TEXT;
BEGIN
 
    IF (TG_OP = 'UPDATE') THEN
        v_old_data := ROW(OLD.*);
        v_new_data := ROW(NEW.*);
        INSERT INTO audit.logged_actions (schema_name,table_name,user_name,action,original_data,new_data,query) 
        VALUES (TG_TABLE_SCHEMA::TEXT,TG_TABLE_NAME::TEXT,session_user::TEXT,substring(TG_OP,1,1),v_old_data,v_new_data, current_query());
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        v_old_data := ROW(OLD.*);
        INSERT INTO audit.logged_actions (schema_name,table_name,user_name,action,original_data,query)
        VALUES (TG_TABLE_SCHEMA::TEXT,TG_TABLE_NAME::TEXT,session_user::TEXT,substring(TG_OP,1,1),v_old_data, current_query());
        RETURN OLD;
    ELSIF (TG_OP = 'INSERT') THEN
        v_new_data := ROW(NEW.*);
        INSERT INTO audit.logged_actions (schema_name,table_name,user_name,action,new_data,query)
        VALUES (TG_TABLE_SCHEMA::TEXT,TG_TABLE_NAME::TEXT,session_user::TEXT,substring(TG_OP,1,1),v_new_data, current_query());
        RETURN NEW;
    ELSE
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - Other action occurred: %, at %',TG_OP,now();
        RETURN NULL;
    END IF;
 
EXCEPTION
    WHEN data_exception THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [DATA EXCEPTION] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
    WHEN unique_violation THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [UNIQUE] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE WARNING '[AUDIT.IF_MODIFIED_FUNC] - UDF ERROR [OTHER] - SQLSTATE: %, SQLERRM: %',SQLSTATE,SQLERRM;
        RETURN NULL;
END;
$body$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, audit;
~~~

* Creamos una tabla de prueba
~~~
CREATE TABLE categories (
    category_id smallint NOT NULL,
    category_name character varying(15) NOT NULL,
    description text,
    picture bytea
);
~~~

* Creamos el trigger de auditoría
~~~
CREATE TRIGGER t_if_modified_trg 
 AFTER INSERT OR UPDATE OR DELETE ON categories
 FOR EACH ROW EXECUTE PROCEDURE audit.if_modified_func();
~~~

* Insertamos los datos de prueba en la tabla que acabamos de crear
~~~
INSERT INTO categories VALUES (1, 'Beverages', 'Soft drinks, coffees, teas, beers, and ales', '\x');
INSERT INTO categories VALUES (2, 'Condiments', 'Sweet and savory sauces, relishes, spreads, and seasonings', '\x');
~~~

* Vemos los resultados
~~~
SELECT *
FROM audit.logged_actions;

schema_name | table_name | user_name |         action_tstamp         | action | original_data |                                     new_data                                      |                                                        query                                                         
-------------+------------+-----------+-------------------------------+--------+---------------+-----------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------
 public      | categories | postgres  | 2021-06-10 11:57:08.248772+02 | I      |               | (1,Beverages,"Soft drinks, coffees, teas, beers, and ales","\\x")                 | INSERT INTO categories VALUES (1, 'Beverages', 'Soft drinks, coffees, teas, beers, and ales', '\x');
 public      | categories | postgres  | 2021-06-10 11:57:09.151275+02 | I      |               | (2,Condiments,"Sweet and savory sauces, relishes, spreads, and seasonings","\\x") | INSERT INTO categories VALUES (2, 'Condiments', 'Sweet and savory sauces, relishes, spreads, and seasonings', '\x');
(2 filas)
~~~

9. **Averigua si en MySQL se pueden realizar los apartados 1, 3 y 4. Si es así, documenta el proceso adecuadamente.**

Creamos una base de datos y una tabla dentro de ella
~~~
MariaDB [(none)]> create database personas;
Query OK, 1 row affected (0.001 sec)

MariaDB [(none)]> use personas
Database changed

MariaDB [personas]> create table usuarios
    -> (ID numeric,
    ->  Nombre varchar(30),
    ->  Apellidos varchar(50),
    ->  Ciudad varchar(50),
    ->  constraint pk_id primary key (ID));
Query OK, 0 rows affected, 1 warning (0.063 sec)
~~~

Creamos la base de datos para las auditorías y dentro de ella creamos una tabla para almacenar los logs que nos mande el trigger que vamos a crear más adelante
~~~
MariaDB [personas]> create database auditorias;
Query OK, 1 row affected (0.001 sec)

MariaDB [personas]> use auditorias;
Database changed

MariaDB [auditorias]> CREATE TABLE accesos
    ->  (
    ->    codigo int(11) NOT NULL AUTO_INCREMENT,
    ->    usuario varchar(100),
    ->    fecha datetime,
    ->    PRIMARY KEY (`codigo`)
    ->  )
    ->  ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;
Query OK, 0 rows affected (0.011 sec)
~~~

Creamos el trigger que nos dará los logs
~~~
MariaDB [auditorias]> delimiter $$
MariaDB [auditorias]> CREATE TRIGGER personas.usuarios
    -> BEFORE INSERT ON personas.usuarios
    -> FOR EACH ROW
    -> BEGIN
    -> INSERT INTO auditorias.accesos (usuario, fecha)
    -> values (CURRENT_USER(), NOW());
    -> END$$
Query OK, 0 rows affected (0.019 sec)
~~~

Ahora que tenemos hecho el trigger, vamos a dirigirnos a la tabla `usuarios` que hemos creado y vamos a insertar algunos datos de prueba
~~~
MariaDB [auditorias]> use personas
Database changed

MariaDB [personas]> insert into usuarios
    -> values('00', 'Juan Antonio', 'Reifs Ramírez', 'Dos Hermanas');
Query OK, 1 row affected (0.011 sec)
~~~

Por último, vamos a dirigirnos a la base de datos `auditorias` y vamos a revisar el contenido de la tabla de `accesos`
~~~
MariaDB [personas]> use auditorias
Database changed

MariaDB [auditorias]> select * from accesos;
+--------+----------------+---------------------+
| codigo | usuario        | fecha               |
+--------+----------------+---------------------+
|      1 | root@localhost | 2021-06-10 12:13:28 |
+--------+----------------+---------------------+
1 row in set (0.001 sec)
~~~

Como podemos comprobar, se ha registrado el log que hemos hecho. Las auditorías tanto en PostgreSQL y MariaDB no existen como en Oracle, pero si que podemos tener algo parecido si las programamos con ciertos Triggers que nos den esa funcionalidad.

10. **Averigua las posibilidades que ofrece MongoDB para auditar los cambios que va sufriendo un documento.**

MongoDB sí que nos pemite realizar una auditoría de ciertas tareas
~~~
--auditFilter
~~~

Podemos auditar auditar la creación y eliminación de colecciones con el siguiente comando
~~~
{ atype: { $in: [ "createCollection", "dropCollection" ] } }
~~~

Con la siguiente instrucción auditamos la creación o eliminación de colecciones indicando como salida un fichero `.bson`
~~~
mongod --dbpath data/db --auditDestination file --auditFilter '{ atype: { $in: [ “createCollection”, “dropCollection” ] } }' --auditFormat BSON --auditPath data/db/auditLog.bson
~~~

11. **Averigua si en MongoDB se pueden auditar los accesos al sistema.**

Auditamos los accesos al sistema con la instrucción 
~~~
{ atype: "authenticate", "param.db": "test" }
~~~

Con la siguiente instrucción, al igual que en el anterior ejercicio, podemos extraer la información en un fichero `.bson`
~~~
mongod --dbpath data/db --auth --auditDestination file --auditFilter '{ atype: "authenticate", "param.db": "test" }' --auditFormat BSON --auditPath data/db/auditLog.bson
~~~
