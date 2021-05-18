---
author:
  name: "Juan Antonio Reifs"
date: 2021-05-18
linktitle: kubernetes
type:
- post
- posts
title: Despliegue de un cluster de Kubernetes
weight: 10
series:
- Hugo 101
images:
tags:
  - Kubernetes
  - k8s
  - k3s
  - letschat
  - containerd
---

Tengo 3 máquinas virtuales (`master`, `nodo1` y `nodo2`), la máquina `master` es el controlador y los dos nodos son los workers.

Este escenario lo he montado en vagrant usando virtualbox, aquí está el `Vagrantfile`
~~~
Vagrant.configure("2") do |config|
  config.vm.define :master do |master|
    master.vm.box = "debian/buster64"
    master.vm.hostname = "master"
    master.vm.network :public_network, :bridge=>"eno1"
  end
  config.vm.define :nodo1 do |nodo1|
    nodo1.vm.box = "debian/buster64"
    nodo1.vm.hostname = "nodo1"
    nodo1.vm.network :public_network, :bridge=>"eno1"
  end
    config.vm.define :nodo2 do |nodo2|
    nodo2.vm.box = "debian/buster64"
    nodo2.vm.hostname = "nodo2"
    nodo2.vm.network :public_network, :bridge=>"eno1"
  end
end
~~~

## Configuración de master

* Como usamos vagrant con virtualbox, vamos a deshabilitar la interfaz de red que nos crea por defecto vagrant, para ello vamos a configurar la ruta por defecto para salir a internet
~~~
vagrant@master:~$ sudo ip r del default
vagrant@master:~$ sudo ip r add default via 192.168.1.1
~~~

* Ahora introducimos nuestra clave pública al fichero `~/.ssh/authorized_keys` para poder acceder a la máquina por una conexión ssh normal
~~~
echo id_rsa.pub >> ~/.ssh/authorized_keys
~~~

* Nos conectamos mediante ssh y apagamos la interfaz de red `eth0`, iniciamos sesión como root, nos dirigimos a la ruta `/usr/local/bin` para descargar desde [su github](https://github.com/rancher/k3s/releases/latest) el binario que nos va a permitir ejecutar `k3s`
~~~
juanan@juananpc:~/vagrant$ ssh vagrant@master
vagrant@master:~$ sudo ifdown eth0
vagrant@master:~$ sudo su -
root@master:~# cd /usr/local/bin/
root@master:/usr/local/bin# wget https://github.com/k3s-io/k3s/releases/download/v1.21.0%2Bk3s1/k3s
~~~

* Cuando lo hayamos descargado, vamos a darle permisos de ejecución y lo ejecutaremos en segundo plano para que se inicie el controlador. Como tenemos varias interfaces de red deberemos de indicarle en el comando qué interfaz de red (o ip en este caso) es la que queremos que use
~~~
root@master:/usr/local/bin# chmod +x k3s
root@master:/usr/local/bin# k3s server --node-ip=192.168.1.49 &
~~~

* Cuando hayan pasado unos segundos/minutos (dependiendo de la velocidad de nuestra máquina), ya tendremos nuestro primer nodo activo
~~~
root@master:/usr/local/bin# k3s kubectl get nodes
NAME     STATUS   ROLES                  AGE     VERSION
master   Ready    control-plane,master   2m56s   v1.21.0+k3s1
~~~

## Configuración de nodo1 y nodo2

* Mientras se termina de arrancar el servicio del controlador, podemos ir configurando los otros dos nodos, para ello vamos a realizar los mismos pasos de configuración para conectarnos por ssh y descargamos el binario, tal y como lo hemos hecho en la máquina `master`.

	* **Configuración en el nodo1:**
~~~
vagrant@nodo1:~$ echo id_rsa.pub >> ~/.ssh/authorized_keys
vagrant@nodo1:~$ sudo su -
root@nodo1:~# ip r del default
root@nodo1:~# ip r add default via 192.168.1.1
root@nodo1:~# cd /usr/local/bin/
root@nodo1:/usr/local/bin# wget https://github.com/k3s-io/k3s/releases/download/v1.21.0%2Bk3s1/k3s
root@nodo1:/usr/local/bin# chmod +x k3s
~~~

	* **Configuración en el nodo2:**
~~~
vagrant@nodo2:~$ echo id_rsa.pub >> ~/.ssh/authorized_keys
vagrant@nodo2:~$ sudo su -
root@nodo2:~# ip r del default
root@nodo2:~# ip r add default via 192.168.1.1
root@nodo2:~# cd /usr/local/bin/
root@nodo2:/usr/local/bin# wget https://github.com/k3s-io/k3s/releases/download/v1.21.0%2Bk3s1/k3s
root@nodo2:/usr/local/bin# chmod +x k3s
~~~

* Cuando tengamos todo configurado, ya podemos comenzar a conectar nuestros dos nuevos nodos al controlador, para ello necesitaremos la ip de nuestro controlador `master` junto con su `token` de autenticación, el cual se encuentra en la ruta `/var/lib/rancher/k3s/server/token`
~~~
vagrant@master:~$ ip a
[...]
inet 192.168.1.49/24 brd 192.168.1.255 scope global dynamic eth1
[...]

vagrant@master:~$ sudo cat /var/lib/rancher/k3s/server/token
K10561cd3779d46c8357182526a0390235b2334c29e5c7dacec9a7390e14039e58c::server:60bbdc995793316982b79ead9929a93c
~~~

* Ahora que tenemos estos datos podemos conectar los dos nodos a nuestro controlador

	* **Conecxión del nodo1:**
~~~
root@nodo1:/usr/local/bin# k3s agent --server https://192.168.1.49:6443 --token K10561cd3779d46c8357182526a0390235b2334c29e5c7dacec9a7390e14039e58c::server:60bbdc995793316982b79ead9929a93c
~~~

	* **Conexión del nodo2:**
~~~
root@nodo2:/usr/local/bin# k3s agent --server https://192.168.1.49:6443 --token K10561cd3779d46c8357182526a0390235b2334c29e5c7dacec9a7390e14039e58c::server:60bbdc995793316982b79ead9929a93c
~~~

* Comprobamos que se han conectado los dos nuevos nodos al controlador
~~~
root@master:/usr/local/bin# k3s kubectl get nodes
NAME     STATUS   ROLES                  AGE     VERSION
master   Ready    control-plane,master   20m     v1.21.0+k3s1
nodo1    Ready    <none>                 3m23s   v1.21.0+k3s1
nodo2    Ready    <none>                 2m36s   v1.21.0+k3s1
~~~

## Configuración de kubectl en mi máquina personal

Ahora que tenemos nuestro clúster configurado con 3 nodos (1 controlador y 2 workers), vamos a descargar e instalar `kubectl` para poder controlar el clúster desde mi máquina personal, para ello seguiremos los pasos de la [página oficial de kubernetes](https://kubernetes.io/es/docs/tasks/tools/install-kubectl/)
~~~
juanan@juananpc:~/vagrant$ sudo apt-get update && sudo apt-get install -y apt-transport-https gnupg2 curl
juanan@juananpc:~/vagrant$ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
juanan@juananpc:~/vagrant$ echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
juanan@juananpc:~/vagrant$ sudo apt-get update
juanan@juananpc:~/vagrant$ sudo apt-get install -y kubectl
~~~

Podemos comprobar que está instalado correctamente si podemos visualizar la versión de `kubectl`
~~~
juanan@juananpc:~/vagrant$ sudo kubectl version
Client Version: version.Info{Major:"1", Minor:"20", GitVersion:"v1.20.2", GitCommit:"faecb196815e248d3ecfb03c680a4507229c2a56", GitTreeState:"clean", BuildDate:"2021-01-13T13:28:09Z", GoVersion:"go1.15.5", Compiler:"gc", Platform:"linux/amd64"}
The connection to the server localhost:8080 was refused - did you specify the right host or port?
~~~

Nos ha aparecido un error en el anterior comando, ya que no tenemos configurado todavía a qué servidor nos queremos conectar, para ello vamos a crear un directorio en nuestra carpeta personal llamada `.kube`, en la cual vamos a ir añadiendo el contenido tanto de configuración como el que vayamos a ir usando para nuestras aplicaciones. Para configurar `kubectl` vamos a copiar el fichero de configuración `/etc/rancher/k3s/k3s.yaml` y lo llamaremos `config` para más tarde introducirlo en una variable de entorno que usa `kubectl` para la configuración.
~~~
juanan@juananpc:~$ mkdir .kube
juanan@juananpc:~$ cd .kube
juanan@juananpc:~/.kube$ scp root@master:/etc/rancher/k3s/k3s.yaml ./config
~~~

Ahora que tenemos nuestro fichero vamos a editar la línea que hace referencia a la conexión y cambiamos el valor de `localhost` por la ip del nodo controlador y lo introducimos en la variable de entorno que hemos comentado anteriormente.
~~~
nano config
[...]
    server: https://192.168.1.49:6443
[...]

juanan@juananpc:~/.kube$ export KUBECONFIG=~/.kube/config
~~~

Ahora hacemos la prueba para ver si podemos visualizar los nodos de k8s
~~~
juanan@juananpc:~/.kube$ kubectl get nodes
NAME     STATUS   ROLES                  AGE   VERSION
master   Ready    control-plane,master   35m   v1.21.0+k3s1
nodo1    Ready    <none>                 18m   v1.21.0+k3s1
nodo2    Ready    <none>                 17m   v1.21.0+k3s1
~~~

Como podemos ver, podemos controlar k8s desde mi máquina personal.

## Despliegue del ejemplo 8

Ahora vamos a realizar el montaje de la aplicación Let'sChat en nuestro clúster que acabamos de montar, para ello vamos a clonar el siguiente [repositorio de GitHub](https://github.com/iesgn/kubernetes-storm) y nos dirigimos al directorio del ejemplo8
~~~
juanan@juananpc:~/.kube$ git clone https://github.com/iesgn/kubernetes-storm.git
juanan@juananpc:~/.kube$ cd kubernetes-storm/unidad3/ejemplos-3.2/ejemplo8/
~~~

Cuando estemos en este directorio, vamos a lanzar el comando `kubectl apply -f .` y se comenzarán a crear los `ReplicaSet`
~~~
juanan@juananpc:~/.kube/kubernetes-storm/unidad3/ejemplos-3.2/ejemplo8$ kubectl apply -f .
Warning: networking.k8s.io/v1beta1 Ingress is deprecated in v1.19+, unavailable in v1.22+; use networking.k8s.io/v1 Ingress
ingress.networking.k8s.io/ingress-letschat created
deployment.apps/letschat created
service/letschat created
deployment.apps/mongo created
service/mongo created
~~~

Por último, solo quedaría introducir las ip dentro de nuestro fichero de configuración `/etc/hosts` para poder acceder a la aplicación que acabamos de lanzar
~~~
juanan@juananpc:~/.kube/kubernetes-storm/unidad3/ejemplos-3.2/ejemplo8$ kubectl get all,ingress
[...]
NAME                                         CLASS    HOSTS              ADDRESS                                  PORTS   AGE
ingress.networking.k8s.io/ingress-letschat   <none>   www.letschat.com   192.168.1.27,192.168.1.49,192.168.1.65   80      76s

juanan@juananpc:~/.kube/kubernetes-storm/unidad3/ejemplos-3.2/ejemplo8$ sudo nano /etc/hosts
192.168.1.27 www.letschat.com
192.168.1.49 www.letschat.com
192.168.1.65 www.letschat.com
~~~

Entramos en la url para comprobar que funciona la página y realizamos un registro e inicio de sesión

![Captura 1](/kubernetes/1.png)

![Captura 2](/kubernetes/2.png)

![Captura 3](/kubernetes/3.png)

![Captura 4](/kubernetes/4.png)

## Escalar la aplicación

Si queremos escalar nuestra aplicación, solo deberemos saber el nombre de los deploy que hemos hecho, para ello ejecutamos el comando `kubectl get deploy`
~~~
juanan@juananpc:~/ASIR2/4.- K8S/vagrant$ kubectl get deploy
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
letschat   1/1     1            1           53m
mongo      1/1     1            1           53m
~~~

Vamos a comprobar cuántos pods de esos deploys tenemos
~~~
juanan@juananpc:~/ASIR2/4.- K8S/vagrant$ kubectl get pod -o wide
NAME                        READY   STATUS    RESTARTS   AGE   IP          NODE    NOMINATED NODE   READINESS GATES
letschat-7c66bd64f5-9dlbw   1/1     Running   0          52m   10.42.1.3   nodo1   <none>           <none>
mongo-5c694c878b-sndcr      1/1     Running   0          52m   10.42.2.3   nodo2   <none>           <none>
~~~

Si los escalamos a 3 por ejemplo, obtenemos esto
~~~
juanan@juananpc:~/ASIR2/4.- K8S/vagrant$ kubectl scale --replicas=2 deploy/letschat
deployment.apps/letschat scaled
juanan@juananpc:~/ASIR2/4.- K8S/vagrant$ kubectl scale --replicas=2 deploy/mongo
deployment.apps/mongo scaled
juanan@juananpc:~/ASIR2/4.- K8S/vagrant$ kubectl get pod -o wide
NAME                        READY   STATUS    RESTARTS   AGE     IP          NODE    NOMINATED NODE   READINESS GATES
letschat-7c66bd64f5-9dlbw   1/1     Running   0          57m     10.42.1.3   nodo1   <none>           <none>
mongo-5c694c878b-sndcr      1/1     Running   0          57m     10.42.2.3   nodo2   <none>           <none>
letschat-7c66bd64f5-zz46j   1/1     Running   0          3m5s    10.42.1.4   nodo1   <none>           <none>
mongo-5c694c878b-pjsdv      1/1     Running   0          2m59s   10.42.2.5   nodo2   <none>           <none>
~~~

Si apagamos un nodo, podemos ver que la aplicación sigue funcionando
~~~
vagrant@nodo2:~$ sudo poweroff
~~~

![Captura 5](/kubernetes/5.png)
