---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-09
linktitle: Configuracion LDAP
type:
- post
- posts
title: Instalacion y configuracion inicial de OpenLDAP
weight: 10
series:
- Hugo 101
images:
tags:
  - LDAP
  - OpenLDAP
  - slapd
  - Grupos
  - Usuarios
---

1. Vemos si el FQDN está bien configurado
~~~
debian@freston:~$ hostname -f
freston.juanantonio-reifs.gonzalonazareno.org
~~~

2. Ahora vamos a instalar el paquete `slapd` que es la versión de LDAP más extendida
~~~
sudo apt-get update && sudo apt-get -y install slapd
~~~

3. Configuramos la contraseña de administrador y la confirmamos
~~~
┌─────────────────────────┤ Configuring slapd ├──────────────────────────┐
│ Please enter the password for the admin entry in your LDAP directory.  │ 
│                                                                        │ 
│ Administrator password:                                                │ 
│                                                                        │ 
│ *****_________________________________________________________________ │ 
│                                                                        │ 
│                                 <Ok>                                   │ 
│                                                                        │ 
└────────────────────────────────────────────────────────────────────────┘ 
~~~

Ahora que ha finalizado la instalación de LDAP se nos habrá abierto un socket TCP/IP con el puerto 389 (que es el puerto que usa por defecto LDAP), el cual estará escuchando peticiones por todas las interfaces de la máquina, es decir, por la ip `0.0.0.0`. Si queremos comprobar esto último ejecutaremos el comando `netstat`, el cual, si no lo tenéis instalado en vuestra máquina, se encuentra enel paquete `net-tools`
~~~
debian@freston:~$ sudo netstat -tlnp
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:389             0.0.0.0:*               LISTEN      20141/slapd
[...]               
tcp6       0      0 :::389                  :::*                    LISTEN      20141/slapd
[...]
~~~

El siguiente paso va a ser instalar una herramienta que nos va a permitir interactuar con el servidor LDAP, ya que nos permite ejecutar búsquedas, medificaciones, insercciones de objetos, etc...
~~~
sudo apt-get install ldap-utils
~~~

Para realizar búsquedas usaremos el comando `ldapsearch`.
~~~
debian@freston:~$ ldapsearch -x -b "dc=juanantonio-reifs,dc=gonzalonazareno,dc=org"
# extended LDIF
#
# LDAPv3
# base <dc=juanantonio-reifs,dc=gonzalonazareno,dc=org> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# juanantonio-reifs.gonzalonazareno.org
dn: dc=juanantonio-reifs,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: dcObject
objectClass: organization
o: juanantonio-reifs.gonzalonazareno.org
dc: juanantonio-reifs

# admin, juanantonio-reifs.gonzalonazareno.org
dn: cn=admin,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator

# search result
search: 2
result: 0 Success

# numResponses: 3
# numEntries: 2
~~~

Como podemos observar en la salida del comando anterior, el primer objeto es la base del cual cuelgan todos los demás objetos que vayamos creando
~~~
# juanantonio-reifs.gonzalonazareno.org
dn: dc=juanantonio-reifs,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: dcObject
objectClass: organization
o: juanantonio-reifs.gonzalonazareno.org
dc: juanantonio-reifs
~~~

El segundo objeto corresponde al administrador, el cual se genera automáticamente en la instalación, el cual cuelga del objeto base mencionado anteriormente
~~~
# admin, juanantonio-reifs.gonzalonazareno.org
dn: cn=admin,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator
~~~

En la búsqueda anterior se nos han mostrado las `ObjectClass` a las que pertenecen dichos objetos y algunos atributos como pueden ser el nombre distintivo o `dn`, el cual se usa para identificar dicho objeto de manera única dentro de la jerarquía, pero no se nos han mostrado todos los atributos, ya que hemos realizado una búsqueda anónima, la cual es cómoda a la hora de buscar rápidamente, ya que no es necesario autentificarse, pero tiene el inconveniente de que al ser anónimos, no se nos muestran ciertos atributos por motivos de seguridad, como por ejemplo las contraseñas encriptadas de los usuarios. Si queremos realizar una búsqueda mostrando todos los atributos, tendríamos que hacer uso del usuario `admin`.

Realizaremos una búsqueda con el usuario `admin` de la siguiente manera:
~~~
debian@freston:~$ ldapsearch -x -D "cn=admin,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org" -b "dc=juanantonio-reifs,dc=gonzalonazareno,dc=org" -W
Enter LDAP Password: 
# extended LDIF
#
# LDAPv3
# base <dc=juanantonio-reifs,dc=gonzalonazareno,dc=org> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# juanantonio-reifs.gonzalonazareno.org
dn: dc=juanantonio-reifs,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: dcObject
objectClass: organization
o: juanantonio-reifs.gonzalonazareno.org
dc: juanantonio-reifs

# admin, juanantonio-reifs.gonzalonazareno.org
dn: cn=admin,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator
userPassword:: e1NTSEF9TUQ1d3g1ajlvUSs3Rm9uVjNLMUN6eVUrdHlRN2JoZ1E=

# search result
search: 2
result: 0 Success

# numResponses: 3
# numEntries: 2
~~~

* **Explicación del comando:**

	* **`-D`:** Indicamos el `dn` del usuario con el que queremos realizar la búsqueda. En este caso, como hemos usado el usuario `admin`, el comando sería: `cn=admin,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org`

	* **`-W`:** Le decimos al comando que nos pida la contraseña del usuario que hemos usado de manera oculta, en lugar de introducirla en el propio comando, ya que esta es una opción más segura a la hora de introducir una contraseña.

Como podemos ver en la salida del comando anterior, ahora se nos ha mostrado un atributo llamado `userPassword`, el cual contiene la contraseña encriptada del usuario `admin`.

Como la instalación y configuración de LDAP ha finalizado, vamos a comenzar a crear nuestros primero objetos, los cuales van a ser dos unidades organizativas, ya que si queremos tener un esquema de datos organizado, no deberemos de crear objetos que cuelguen de la base de nuestro árbol, para ello crearemos las unidades organizativas `personas` y `grupos` y para ello vamos a hacer uso de unos ficheros con una extensión `.ldif`
~~~
debian@freston:~/ldap$ nano unidades.ldif

dn: ou=Personas,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org
objectClass: organizationalUnit
ou: Personas

dn: ou=Grupos,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org
objectClass: organizationalUnit
ou: Grupos
~~~

* **Explicación del contenido del fichero:**

	* **`dn`:** En la primera línea hemos indicado el nombre distintivo que tendrá dentro de nuestra jerarquía haciendo uso del único atributo obligatorio `ou` que utiliza la clase en cuestión, teniendo la certeza de que nunca se va a repetir este nombre.

	* **`objectClass`:** En la segunda línea hemos importado la clase `organizationalUnit`, la cual es necesaria para definir una unidad organizativa.

	* **`ou`:** En la tercera línea hemos asignado un valor al atributo obligatorio que usa la clase en cuestión, elcual corresponde con el nombre de la unidad organizativa.

Cuando hayamos terminado de definir nuestro fichero `.ldif` deberemos importarlo usando el comando `ldapadd` y usando el usuario `admin`
~~~
debian@freston:~/ldap$ ldapadd -x -D "cn=admin,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org" -f unidades.ldif -W
Enter LDAP Password: 
adding new entry "ou=Personas,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org"

adding new entry "ou=Grupos,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org"
~~~

* **Explicación del comando:**

	* **`-f`:** Indicamos el fichero en el cual se encuentran definidos los objetos que queremos añadir a nuestro árbol de datos.

Ahora podemos comprobar que se han creado las dos unidades organizativas haciendo uso del primer comando de búsqueda que vimos
~~~
debian@freston:~/ldap$ ldapsearch -x -b "dc=juanantonio-reifs,dc=gonzalonazareno,dc=org"
# extended LDIF
#
# LDAPv3
# base <dc=juanantonio-reifs,dc=gonzalonazareno,dc=org> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# juanantonio-reifs.gonzalonazareno.org
dn: dc=juanantonio-reifs,dc=gonzalonazareno,dc=org
objectClass: top
objectClass: dcObject
objectClass: organization
o: juanantonio-reifs.gonzalonazareno.org
dc: juanantonio-reifs

# admin, juanantonio-reifs.gonzalonazareno.org
dn: cn=admin,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator

# Personas, juanantonio-reifs.gonzalonazareno.org
dn: ou=Personas,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org
objectClass: organizationalUnit
ou:: UGVyc29uYXMg

# Grupos, juanantonio-reifs.gonzalonazareno.org
dn: ou=Grupos,dc=juanantonio-reifs,dc=gonzalonazareno,dc=org
objectClass: organizationalUnit
ou: Grupos

# search result
search: 2
result: 0 Success

# numResponses: 5
# numEntries: 4
~~~
