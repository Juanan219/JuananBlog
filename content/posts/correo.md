---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-11
linktitle: Servidor de correos
type:
- post
- posts
title: Servidor de correos
weight: 10
series:
- Hugo 101
images:
tags:
  - Servicios
  - Configuracion
  - Correo
  - Postfix
  - Dovecot
  - IMTPS
  - SMTPS
---

En esta entrada vamos a configurar un servidor de correos en un VPS, para ello primero deberemos configurar el nombre del servidor de correos, el cual será `mail.iesgn16.es`, cuyo nombre aparecerá en el registro MX de nuestro DNS.

Para configurar el mail en nuestro servidor, vamos a instalar postfix
```
sudo apt-get update

sudo apt-get install postfix
```

Durante la instalación se nos pedirá que configuremos el *mailname*, es decir, el nombre del servidor de correo. Cuando lo tengamos configurado, lo podremos ver con el comando
```
cat /etc/mailname

iesgn16.es
```

Creamos el registro MX y SPF en nuestro DNS

![Captura 1](/correo/1.png)

## Gestión de correos desde el servidor

* **Tarea 1**

Vamos a descargarnos la herramienta que nos permita enviar/leer correos que recibamos en nuestro servidor postfix, dicha herramienta se llama `mailutils` y se instala de la siguiente manera
```
sudo apt-get install mailutils
```

Ahora que tenemos `mailutils`, vamos a enviar un correo de prueba
```
mail -s "Prueba" initiategnat9@gmail.com
Cc: 
Hola, esto es una prueba
```

Cuando enviamos el correo, podemos verlo en el registro de log de postfix
```
Feb  9 12:24:58 fenix postfix/qmgr[30796]: 9C31561C11: removed
Feb  9 12:31:19 fenix postfix/pickup[30795]: 5285E61C11: uid=1000 from=<debian@fenix.iesgn16.es>
Feb  9 12:31:19 fenix postfix/cleanup[31354]: 5285E61C11: message-id=<20210209123119.5285E61C11@fenix.iesgn16.es>
Feb  9 12:31:19 fenix postfix/qmgr[30796]: 5285E61C11: from=<debian@fenix.iesgn16.es>, size=369, nrcpt=1 (queue active)
Feb  9 12:31:19 fenix postfix/smtp[31356]: 5285E61C11: to=<initiategnat9@gmail.com>, relay=gmail-smtp-in.l.google.com[74.125.140.26]:25, delay=0.54, delays=0.02/0.01/0.31/0.21, dsn=2.0.0, status=sent (250 2.0.0 OK  1612873879 q194si1500502wme.142 - gsmtp)
Feb  9 12:31:19 fenix postfix/qmgr[30796]: 5285E61C11: removed
```

Este es el correo que he recibido en mi gmail

![Captura 2](/correo/2.png)

Este es el registro SPF que he tenido que añadir a mi servidor DNS

![Captura 3](/correo/3.png)

* **Tarea 2**

	* **a)** Documenta una prueba de funcionamiento, en la que envíes un correo desde el exterior (gmail, hotmail, etc...) a tu servidor local.

Vamos a comprobar que podemos recibir correos desde el exterior hacia nuestros servidor, para ello, primero deberemos tener configurado nuestro nombre de dominio en el fichero `/etc/mailname`, en mi caso, el nopmbre de dominio sería `iesgn16.es`. Ahora revisamos la configuración del DNS para que el registro MX `mail.iesgn16.es` apunte a `fenix.iesgn16.es` (Que es la máquina en la que tengo el servidor de correo).

Cuando todo esté correcto, hacemos una prueba y enviamos un correo a nuestro usuario del servidor

![Captura 4](/correo/4.png)


Lo abrimos desde nuestro servidor con el comando `mail`
```
mail
"/var/mail/debian": 1 message 1 new
>N   1 juanan veintidieci Tue Feb  9 13:00 101/4632  RE: Prueba
? 1
Return-Path: <initiategnat9@gmail.com>
X-Original-To: debian@fenix.iesgn16.es
Delivered-To: debian@fenix.iesgn16.es
[...]
Content-Type: text/plain; charset="UTF-8"
Content-Transfer-Encoding: quoted-printable

Correcto, prueba de correo recibida

--=20
*Fdo: Juan Antonio Reifs Ram=C3=ADrez*
```

Podemos ver el log en el cual se ve que hemos recibido el correo
```
Feb  9 13:00:19 fenix postfix/smtpd[31853]: connect from mail-ej1-f49.google.com[209.85.218.49]
Feb  9 13:00:19 fenix postfix/smtpd[31853]: CF3EB61A7B: client=mail-ej1-f49.google.com[209.85.218.49]
Feb  9 13:00:19 fenix postfix/cleanup[31858]: CF3EB61A7B: message-id=<CAFPV5c77w-0rLEWJGaBfgPXzxtJJ=DZvC9ZjyfCTyaeHGWfeYA@mail.gmail.com>
Feb  9 13:00:19 fenix postfix/qmgr[30796]: CF3EB61A7B: from=<initiategnat9@gmail.com>, size=4614, nrcpt=1 (queue active)
Feb  9 13:00:19 fenix postfix/local[31859]: CF3EB61A7B: to=<debian@fenix.iesgn16.es>, relay=local, delay=0.02, delays=0.01/0.01/0/0, dsn=2.0.0, status=sent (delivered to mailbox)
```

## Uso de alias y redirecciones

* **Tarea 3:**

Los procesos del sistema pueden mandar correos para informar sobre su estado. Por ejemplo, cuando se ejecuta una tarea de cron, podemos enviar un correo informando del resultado de la misma. Normalmente estos correos se mandan al usuario root, para hacer esto haremos lo siguiente:
```
crontab -e

MAILTO = root
```

Podemos poner una tarea en el cron para ver cómo se manda el correo.
```
debian@fenix:~$ crontab -e

MAILTO = root

8 * * * * sudo apt-get update

sudo su

root@fenix:/home/debian# mail
"/var/mail/root": 1 message 1 new
>N   1 Cron Daemon        Tue Feb  9 19:08  24/894   Cron <debian@fenix> sudo apt-get update
? 1
Return-Path: <debian@iesgn16.es>
X-Original-To: root
Delivered-To: root@iesgn16.es
Received: by fenix.iesgn16.es (Postfix, from userid 1000)
        id 9E7D561A81; Tue,  9 Feb 2021 19:08:02 +0000 (UTC)
From: root@iesgn16.es (Cron Daemon)
To: root@iesgn16.es
Subject: Cron <debian@fenix> sudo apt-get update
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: 8bit
X-Cron-Env: <MAILTO=root>
X-Cron-Env: <SHELL=/bin/sh>
X-Cron-Env: <HOME=/home/debian>
X-Cron-Env: <PATH=/usr/bin:/bin>
X-Cron-Env: <LOGNAME=debian>
Message-Id: <20210209190802.9E7D561A81@fenix.iesgn16.es>
Date: Tue,  9 Feb 2021 19:08:02 +0000 (UTC)

Hit:1 http://security.debian.org/debian-security buster/updates InRelease
Hit:2 http://deb.debian.org/debian buster InRelease
Get:3 http://deb.debian.org/debian buster-updates InRelease [51.9 kB]
Fetched 51.9 kB in 0s (149 kB/s)
Reading package lists...
? q
Saved 1 message in /root/mbox
Held 0 messages in /var/mail/root
```

Posteriormente, usando alias y redirecciones podemos hacer llegar esos correos a nuestro correo personal.
```
sudo su -

nano .forward

initiategnat9@gmail.com

exit
```

![Captura 5](/correo/5.png)

Crea un nuevo alias para que los correos se manden a un usuario sin privilegios y comprueba que llegan a ese usuario.
```
sudo nano /etc/aliases

postmaster:    root
usuario: debian

sudo newaliases

mail

>N   1 Mail Delivery Syst Tue Feb  9 19:42  80/2679  Undelivered Mail Returned to Sender
```

## Gestión de correos desde un cliente

* **Tarea 8:**

Ahora vamos a configurar el buzón de correos de cada usuario siendo de tipo `Maildir`, para ello vamos a modificar el fichero `/etc/postfix/main.cf` y comprobamos, mandando un correo, que se nos guardan en ese directorio.

```
sudo nano /etc/postfix/main.cf

[...]
home_mailbox = Maildir/
mailbox_command =

sudo systemctl restart postfix

debian@fenix:~$ ls
Maildir

debian@fenix:~$ ls Maildir/
cur  new  tmp

debian@fenix:~$ ls Maildir/new/
1612941963.V801I20b38M9703.fenix
```

![Captura 6](/correo/6.png)

Para abrir los correos de tipo maildir desde la terminal, no podemos hacer con mail, asó que instalaremos la herramienta mutt y editamos el fichero `~/.muttrc`

```
sudo apt-get install muttrc

debian@fenix:~$ nano ~/.muttrc

set mbox_type=Maildir
set folder="~/Maildir"
set mask="!^\\.[^.]"
set mbox="~/Maildir"
set record="+.Sent"
set postponed="+.Drafts"
set spoolfile="~/Maildir"
mailboxes `echo -n "+ "; find ~/Maildir -maxdepth 1 -type d -name ".*" -printf "+'%f' "`
macro index c "<change-folder>?<toggle-mailboxes>" "open a different folder"
macro pager c "<change-folder>?<toggle-mailboxes>" "open a different folder"
macro index C "<copy-message>?<toggle-mailboxes>" "copy a message to a mailbox"
macro index M "<save-message>?<toggle-mailboxes>" "move a message to a mailbox"

macro compose A "<attach-message>?<toggle-mailboxes>" "attach message(s) to this message"
```

Ahora abrimos el mensaje

```
mutt

1     Feb 10 juanan veintidi (2.2K) Prueba Maildir

Date: Wed, 10 Feb 2021 08:54:08 +0100
From: juanan veintidiecinueve <initiategnat9@gmail.com>
To: debian@fenix.iesgn16.es
Subject: Prueba Maildir

Este es un correo que se guardará en Maildir

--
*Fdo: Juan Antonio Reifs Ramírez*

[image: Mailtrack]
<https://mailtrack.io?utm_source=gmail&utm_medium=signature&utm_campaign=signaturevirality5&>
Remitente
notificado con
Mailtrack
<https://mailtrack.io?utm_source=gmail&utm_medium=signature&utm_campaign=signaturevirality5&>
10/02/21
08:49:05
```

* **Tarea 9:**

Ahora vamos a instalar dovecot para poder ofrecer el protocolo IMAP y lo configuraremos para ofrecer autentificación y cifrado.

```
sudo apt-get install dovecot-imapd
```

Para poder realizar el cifrado de la comunicación, vamos a crear un certificado de LetsEncrypt para el dominio `mail.iesgn.es`. Para realizarlo instalaremos `certbot` así que seguimos los siguientes pasos

```
sudo apt install snapd

sudo snap install core

sudo snap install core; sudo snap refresh core

sudo snap install --classic certbot

sudo ln -s /snap/bin/certbot /usr/bin/certbot
```
Cuando tengamos `certbot`instalado, generamos nuestro certificado
```
sudo certbot certonly --standalone
```

Cuando se genere, se guardará en el directorio `/etc/letsencrypt/live/mail.iesgn16.es`. Ahora que lo tenemos todo listo, vamos a pasar a la configuración de dovecot:

1. Editamos el fichero `/etc/dovecot/conf.d/10-auth.conf` para habilitar el mecanismo de autentificación
```
sudo nano /etc/dovecot/conf.d/10-auth.conf

disable_plaintext_auth = yes
[...]
auth_mechanisms = plain login
```

2. Configuramos el directorio Maildir y comentamos la configuración mbox que viene predeterminada en dovecot
```
sudo nano /etc/dovecot/conf.d/10-mail.conf

mail_location = maildir:~/Maildir
[...]
#mail_location = mbox:~/mail:INBOX=/var/mail/%u
```

3. Descomentamos las siguientes líneas para habilitar el imaps
```
sudo nano /etc/dovecot/conf.d/10-master.conf

service imap-login {
  inet_listener imap {
    port = 143
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
[...]
unix_listener /var/spool/postfix/private/auth {
    mode = 0666
    user = postfix
    group = postfix
}
```

4. Por último configuramos nuestros certificados y reiniciamos dovecot
```
sudo nano /etc/dovecot/conf.d/10-ssl.conf

ssl = required
[...]
ssl_cert = </etc/letsencrypt/live/mail.iesgn16.es/cert.pem
ssl_key = </etc/letsencrypt/live/mail.iesgn16.es/privkey.pem

sudo systemctl restart dovecot
```

Podemos verificar la configuración de nuestro dovecot con el comando `dovecot -n`

Ahora vamos a hacer una prueba, para verificar que recibimos mensajes en nuestro Mailbox, para ello vamos a enviar un correo de prueba desde gmail

![Captura 7](/correo/7.png)

```
ls Maildir/new/
1613034771.V801I2154fM907367.fenix

mutt
1 N + Feb 11 juanan veintidi (2.2K) Prueba Maildir

Date: Thu, 11 Feb 2021 10:12:40 +0100
From: juanan veintidiecinueve <initiategnat9@gmail.com>
To: debian@iesgn16.es
Subject: Prueba Maildir

Este mensaje tiene que llegar a tu Maildir

--
*Fdo: Juan Antonio Reifs Ramírez*

[image: Mailtrack]
<https://mailtrack.io?utm_source=gmail&utm_medium=signature&utm_campaign=signaturevirality5&>
Remitente
notificado con
Mailtrack
<https://mailtrack.io?utm_source=gmail&utm_medium=signature&utm_campaign=signaturevirality5&>
11/02/21
10:12:20
```

Por último, vamos a configurar un cliente de correo, en este caso será Thunderbird:

1. Iniciamos sesión

![Captura 8](/correo/8.png)

2. Configuramos manualmente

![Captura 9](/correo/9.png)

Como podemos ver, hemos recibido el mensaje que hemos enviado anteriormente

![Captura 10](/correo/10.png)

* **Tarea 11:**

Vamos a configurar postfix para que podamos enviar correos desde los clientes remotos. La conexión entre el cliente y el servidor debe de estar autentificada con SASL y usando dovecot y, además, debede estar cifrada. Para realizar este cifrado usaremos `SMTPS`, el cual usa el puerto 465.

Primero habilitamos SMTP-AUTH para permitir que los clientes se identifiquen a través del mecanismo de autentificación SASL. También se debe usar TLS para cifrar el proceso de autenticación, para ello ejecutamos las siguientes instrucciones para editar el fichero de configuración de postfix.

```
sudo postconf -e 'smtpd_sasl_type = dovecot'
sudo postconf -e 'smtpd_sasl_path = private/auth'
sudo postconf -e 'smtpd_sasl_local_domain ='
sudo postconf -e 'smtpd_sasl_security_options = noanonymous'
sudo postconf -e 'broken_sasl_auth_clients = yes'
sudo postconf -e 'smtpd_sasl_auth_enable = yes'
sudo postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'
sudo postconf -e 'smtp_tls_security_level = may'
sudo postconf -e 'smtpd_tls_security_level = may'
sudo postconf -e 'smtp_tls_note_starttls_offer = yes'
sudo postconf -e 'smtpd_tls_loglevel = 1'
sudo postconf -e 'smtpd_tls_received_header = yes'
```

Ahora editamos el fichero `/etc/postfix/master.cf` y descomentamos las siguientes líneas
```
sudo nano /etc/postfix/master.cf
[...]
smtps     inet  n       -       y       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_reject_unlisted_recipient=no
  -o smtpd_client_restrictions=$mua_client_restrictions
  -o smtpd_helo_restrictions=$mua_helo_restrictions
  -o smtpd_sender_restrictions=$mua_sender_restrictions
  -o smtpd_recipient_restrictions=
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING
[...]
```

Por último añadimos nuestro certificado y nuestra clave privada al fichero `/etc/postfix/main.cf` y reiniciamos postfix
```
sudo nano /etc/postfix/main.cf
[...]
smtpd_tls_cert_file=/etc/letsencrypt/live/mail.iesgn16.es/cert.pem
smtpd_tls_key_file=/etc/letsencrypt/live/mail.iesgn16.es/privkey.pem
[...]

sudo systemctl restart postfix
```

Ahora nos dirigimos a Thunderbird y modificamos los valores de SMTP
![Captura 11](/correo/11.png)

Para comprobar que funciona, vamos a enviar un correo desde Thunderbird hacia mi gmail personal
![Captura 12](/correo/12.png)

![Captura 13](/correo/13.png)
