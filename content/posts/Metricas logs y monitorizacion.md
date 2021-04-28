# Metricas, logs y monitorización

## Descripción del escenario

En esta entrada vamos a montar el servicio de recolección de métricas para poder monitorizar nuestros servidores en una infraestructura de red. En esta infraestructura tenemos 4 servidores y 2 redes:

* **Red 1 (10.0.1.0/24):**

En esta red tenemos a:

  * **Dulcinea (Debian):** Hace la función de router y cortafuegos.

  * **Sancho (Ubuntu):** Es un servidor que solo tiene instalados gestores de bases de datos.

  * **Freston (Debian):** Es el Servidor DNS (bind9)

* **Red 2 (10.0.2.0/24):**

En esta red tenemos a:

  * **Dulcinea (Debian):** La anteriormente comentada, une las dos redes. 

  * **Quijote (CentOS):** Servidor web con apache.

## Descripción del servicio de monitorización

El sistema de monitorización y recolección de métricas que vamos a montar va a componerse de 3 partes:

* **InfluxDB:** Es el gestor de bases de datos que vamos a usar para guardar toda la información de las métricas

* **Telegraf:** Es la herramienta de recolección de métricas, las cuales va a guardar en el gestor de bases de datos anteriormente mencionado.

* **Grafana:** Es el gestor de Dashboards, el cual nos va a permitir hacer consultas a la base de datos de InfluxDB y nos va a mostrar los resultados en una gráfica.

## Instalación de InfluxDB en Sancho

Primero vamos a instalar InfluxDB en Sancho, ya que es la máquina que se encarga de los servicios de las bases de datos. Para instalar esta herramienta bastaría con descargarnos los paquetes de los repositorios oficiales de Ubuntu o Debian (está en cualquiera de los dos repositorios)
~~~
sudo apt-get update && sudo apt-get install -y influxdb influxdb-client
~~~

Poemos comprobar que se han instalado tanto el gestor de bases de datos como el cliente
~~~
influx
Connected to http://localhost:8086 version 1.6.4
InfluxDB shell version: 1.6.4
> show databases;
name: databases
name
----
_internal
~~~

Para terminar la configuración de nuestra base de datos, vamos a crear un usuario administrador, para ello nos conectamos a la CLI de influxdb y realizamos lo siguiente
~~~
influx

> create user admin with password 'admin' with all privileges

> show users
user  admin
----  -----
admin true
~~~

Como podemos ver se ha creado un usuario llamado `admin` con la contraseña `admin` y elcual tiene permisos de administrador.

## Instalación y configuración de Telegraf en Sancho

Ahora que tenemos nuestro gestor de bases de datos InfluxDB instalado en sancho, vamos a instalar telegraf (la herramienta de recolección de métricas), como esta no está en los repositorios, nos dirigiremos a la [página oficial de descarga](https://portal.influxdata.com/downloads/) del paquete de instalación y copiamos el comando de descarga del paquete y lo instalamos en Sancho:
~~~
wget https://dl.influxdata.com/telegraf/releases/telegraf_1.18.1-1_amd64.deb
sudo dpkg -i telegraf_1.18.1-1_amd64.deb
rm telegraf_1.18.1-1_amd64.deb
~~~

Cuando lo tengamos instalado, vamos a pasar a la configuración, para ello vamos a modificar el fichero `/etc/telegraf/telegraf.conf`. Este fichero es demasiado extenso, ya que telegraf es una herramienta muy configurable, pero en esta ocasión vamos a dejarle las opciones predeterminadas, ya que esto se trata de un documento educativo y se extendería demasiado la explicación de todas las opciones de configuración y plugins que tiene esta herramienta.

Los cambios que voy a realizar en el fichero son los siguientes:
~~~
[...]
[[outputs.influxdb]]
[...]
    urls = ["http://127.0.0.1:8086"]
[...]
    database = "telegraf"
[...]
    skip_database_creation = true
[...]
    timeout = "5s"
[...]
    username = "admin"
    password = "admin"
[...]
~~~

* **Explicación:**

  * `urls = ["http://127.0.0.1:8086"]`: Descomentamos esta línea dentro del apartado de `[[outputs.influxdb]]`. Esta línea sirve para indicar a qué dirección se tienen que enviar las métricas, en este caso, las métricas se recogen en la misma máquina que tiene instalado InfluxDB, por lo que dejaremos la dirección de `loopback` o `localhost`.

  * `database = "telegraf"`: Descomentamos esta línea, la cual indica el nombre de la base de datos en la que se guardarán las métricas recogidas

  * `skip_database_creation = true`: Saltamos la creación de una base de datos inicial, ya que al instalar telegraf se crea una base de datos llamada `telegraf` en InfluxDB.

  * `timeout = "5s"`: el tiempo de espera para los mensajes de HTTP

  * `username y password`; el nombre de usuario y la contraseña del usuario propietario de la base de datos que vayamos a usar o que hemos indicado anteriormente en la línea de `database`.

Cuando hayamos realizado la configuración guardamos y reiniciamos el servicio de telegraf y una vez que este se haya reiniciado, podemos entrar en la CLI de InfluxDB y podemos ver que se han creado tablas con algunos registros de la máquina `sancho`.
~~~
influx
Connected to http://localhost:8086 version 1.6.4
InfluxDB shell version: 1.6.4

> use telegraf
Using database telegraf

> show measurements
name: measurements
name
----
cpu
disk
diskio
kernel
mem
processes
swap
system

> select * from cpu
name: cpu
time                cpu       host   usage_guest usage_guest_nice usage_idle        usage_iowait        usage_irq usage_nice usage_softirq       usage_steal         usage_system        usage_user
----                ---       ----   ----------- ---------------- ----------        ------------        --------- ---------- -------------       -----------         ------------        ----------
1619452540000000000 cpu-total sancho 0           0                94.64105157383807 4.246713852520839   0         0          0                   0.10111223458372003 0.6066734075023201  0.4044489383348801
1619452540000000000 cpu0      sancho 0           0                94.64105157383807 4.246713852520839   0         0          0                   0.10111223458372003 0.6066734075023201  0.4044489383348801
[...]
~~~

## Instalación y configuración de telegraf en Dulcinea

Ahora que hemos terminado de instalar y configurar todo en Sancho, vamos a pasar a instalar y configurar telegraf en dulcinea, para ello vamos a seguir los mismos pasos que anteriormente:
~~~
wget https://dl.influxdata.com/telegraf/releases/telegraf_1.18.1-1_amd64.deb

sudo dpkg -i telegraf_1.18.1-1_amd64.deb

rm telegraf_1.18.1-1_amd64.deb

sudo nano /etc/telegraf/telegraf.conf
[...]
[[outputs.influxdb]]
[...]
    urls = ["http://sancho.juanantonio-reifs.gonzalonazareno.org:8086"]
[...]
    database = "telegraf"
[...]
    skip_database_creation = true
[...]
    timeout = "5s"
[...]
    username = "admin"
    password = "admin"
[...]

sudo systemctl restart telegraf.service
~~~

Verificamos que se está realizando la recolección de métricas
~~~
influx
Connected to http://localhost:8086 version 1.6.4
InfluxDB shell version: 1.6.4
> use telegraf
Using database telegraf
> select * from cpu
name: cpu
time                cpu       host     usage_guest usage_guest_nice usage_idle        usage_iowait        usage_irq usage_nice usage_softirq       usage_steal         usage_system        usage_user
----                ---       ----     ----------- ---------------- ----------        ------------        --------- ---------- -------------       -----------         ------------        ----------
[...]
1619454490000000000 cpu-total dulcinea 0           0                99.89979960143319 0                   0         0          0                   0                   0.10020040080637438 0
1619454490000000000 cpu0      dulcinea 0           0                99.89979960143319 0                   0         0          0                   0                   0.10020040080637438 0
[...]
~~~

## Instalación y configuración de telegraf en freston

Ahora haremos lo mismo pero en freston
~~~
wget https://dl.influxdata.com/telegraf/releases/telegraf_1.18.1-1_amd64.deb

sudo dpkg -i telegraf_1.18.1-1_amd64.deb

rm telegraf_1.18.1-1_amd64.deb

sudo nano /etc/telegraf/telegraf.conf
[...]
[[outputs.influxdb]]
[...]
    urls = ["http://sancho.juanantonio-reifs.gonzalonazareno.org:8086"]
[...]
    database = "telegraf"
[...]
    skip_database_creation = true
[...]
    timeout = "5s"
[...]
    username = "admin"
    password = "admin"
[...]

sudo systemctl restart telegraf.service
~~~

Comprobamos que se están enviando métricas de freston
~~~
> select * from cpu
name: cpu
time                cpu       host     usage_guest usage_guest_nice usage_idle        usage_iowait        usage_irq usage_nice usage_softirq       usage_steal         usage_system        usage_user
----                ---       ----     ----------- ---------------- ----------        ------------        --------- ---------- -------------       -----------         ------------        ----------
[...]
1619454410000000000 cpu-total freston  0           0                98.09045225722387 1.3065326633389247  0         0          0                   0                   0.30150753768937927 0.30150753767109795
1619454410000000000 cpu0      freston  0           0                98.09045225722387 1.3065326633389247  0         0          0                   0                   0.30150753768937927 0.30150753767109795
[...]
~~~

## Instalación y configuración de telegraf en quijote

Por último, instalamos telegraf en quijote
~~~
wget https://dl.influxdata.com/telegraf/releases/telegraf-1.18.1-1.x86_64.rpm

sudo dnf localinstall telegraf-1.18.1-1.x86_64.rpm

rm telegraf-1.18.1-1.x86_64.rpm

sudo nano /etc/telegraf/telegraf.conf
[...]
[[outputs.influxdb]]
[...]
    urls = ["http://sancho.juanantonio-reifs.gonzalonazareno.org:8086"]
[...]
    database = "telegraf"
[...]
    skip_database_creation = true
[...]
    timeout = "5s"
[...]
    username = "admin"
    password = "admin"
[...]

sudo systemctl restart telegraf.service
~~~

Comprobamos que se están enviando métricas de quijote
~~~
> select * from cpu
name: cpu
time                cpu       host     usage_guest usage_guest_nice usage_idle        usage_iowait        usage_irq usage_nice usage_softirq       usage_steal         usage_system        usage_user
----                ---       ----     ----------- ---------------- ----------        ------------        --------- ---------- -------------       -----------         ------------        ----------
[...]
1619454980000000000 cpu0      quijote  0           0                98.59578736541238 0.30090270813311    0.10030090270381484 0          0.10030090271293715 0                   0.4012036108426263  0.5015045135464411
1619454990000000000 cpu-total quijote  0           0                97.59036144352997 1.1044176706869986  0.2008032128565398  0          0.10040160641913842 0.10040160642598703 0.502008032132218   0.4016064257130796
[...]
~~~

## Instalación de grafana en quijote

Lo último que nos queda por instalar y configurar es grafana en quijote, el cual es el servidor web. Para instalar grafana basta con instalarlo desde los repositorios de CentOs
~~~
sudo dnf install grafana
~~~

Como nuestra máquina tiene instalado un servidor web apache, vamos a realizar un proxy inverso para que podamos acceder a nuestro servicio de grafana desde el exterior, para ello vamos a crear un virtualhost que actúe como proxy inverso
~~~
sudo nano /etc/httpd/sites-available/grafana.conf

<Virtualhost *:80>
        ServerName grafana.juanantonio-reifs.gonzalonazareno.org
        ProxyPreserveHost On
        ProxyPass / http://localhost:3000/
        ProxyPassReverse / http://localhost:3000/
        ErrorLog /var/log/grafana/error_log
        TransferLog /var/log/grafana/error_log
</virtualhost>
~~~

Hacemos un enlace simbólico hacia `sites-enabled` y reiniciamos el servicio
~~~
cd /etc/httpd/sites-enabled

sudo ln -s ../sites-available/grafana.conf .

sudo systemctl restart httpd
~~~

Ahora podremos entrar en la página de login y cambiamos la contraseña de admin, en mi caso el usuario va a ser `admin` y la contraseña va a ser `admin1`

![Captura 1](/metricas/1.png)

![Captura 2](/metricas/2.png)

Cuando hayamos entrado vamos a enlazar la base de datos, para ello nos dirigiremos a `Configuración` > `Data sources` > `Add Data Source`

![Captura 3](/metricas/3.png)

Seleccionamos la base de datos que hayamos instalado, en nuestro caso es `InfluxDB`

![Captura 4](/metricas/4.png)

Ahora pasamos a configurar la base de datos, para ello pondremos el nombre del servidor que está sirviendo nuestra base de datos `InfluxDB` junto con su puerto, en mi caso sería `http://sancho.juanantonio-reifs.gonzalonazareno.org:8086` y abajo del todo pondremos el nombre de la base de datos que se ha creado, en mi caso es `telegraf` y ponemos el usuario y la contraseña de acceso a la base de datos

![Captura 5](/metricas/5.png)

![Captura 6](/metricas/6.png)

Cuando esté todo configurado podemos crear un dashboard haciendo una consulta a la base de datos, de tal manera que quedaría así

![Captura 7](/metricas/7.png)

![Captura 8](/metricas/8.png)