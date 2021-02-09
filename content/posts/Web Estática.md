---
author:
  name: "Juan Antonio Reifs"
date: 2021-02-04
linktitle: Sitio Web Estático
type:
- post
- posts
title: Generar Sitios Web estáticos con HUGO y GitHub Pages
weight: 10
series:
- Hugo 101
images:

tags:
  - ASIR
  - Implementación de aplicaciones Web
  - Linux
---

En esta práctica vamos a seleccionar una combinación para realizar el depliegue de una web estática y añadir contenido a ella, en mi caso, voy a seleccionar la combinación de HUGO y GitHub Pages.

Para comenzar, vamos a instalar la herramientas necesarias para realizar esta práctica, así que instalaremos git y hugo
```
sudo apt-get update

sudo apt-get install git hugo
```

Cuando tengamos los paquetes descargados, vamos a comenzar a montar nuestro sitio y como vamos a subirlo a github, creamos un nuevo repositorio vacío y lo clonamos a nuestro directorio de trabajo, para más tarde comenzar a crear nuestro sitio
```
git clone git@github.com:Juanan219/JuananBlog.git

hugo new site --force JuananBlog/
```

Si queremos, ya podemos hacer el primer commit en github y comenzar a subir los archivos
```
git add .

git commit -am "Primer commit"

git push
```

Ahora vamos a añadir un tema de los [temas de hugo](https://themes.gohugo.io/), para ello vamos a clonar el repositorio de uno de ellos en el directorio themes
```
git clone git@github.com:rhazdon/hugo-theme-hello-friend-ng.git
```

En esta práctica no me voy a parar a adaptar el tema entero, así que cogeré el tema de ejemplo que viene en el directorio que hemos clonado y vamos a adaptarlo para que funcione
```
cd ..

cp -r themes/hugo-theme-hello-friend-ng/exampleSite/* .
```

Cuando tengamos todos los archivos de ejemplo copiados al directorio principal de nuestro sitio, vamos a editar el config.toml para poner nuestros enlaces y nuestro nombre junto a la fecha actual
```
nano config.toml
baseURL = "https://juanan219.github.io"
title   = "JuananBlog"
[...]
[author]
  name = "Juan antonio Reifs"
[...]
[params]
  dateform        = "Feb 4, 2021"
  dateformShort   = "Feb 4"
  dateformNum     = "2021-02-04"
  dateformNumTime = "2021-02-04 11:35"
[...]
description = "Blog de Informática"
[...]
homeSubtitle = "Blog de Informática"
[...]
[[params.social]]
    name = "twitter"
    url  = "https://twitter.com/juanan219"

  [[params.social]]
    name = "email"
    url  = "mailto:initiategnat9@gmail.com"

  [[params.social]]
    name = "github"
    url  = "https://github.com/juanan219"

  [[params.social]]
    name = "linkedin"
    url  = "https://www.linkedin.com/in/juan-antonio-reifs-ram%C3%ADrez-b78b40162/"

#  [[params.social]]
#    name = "stackoverflow"
#    url  = "https://www.stackoverflow.com/"
```

Ahora vamos a eliminar los posts de ejemplo y vamos a crear uno, pero al ejecutar el comando para crear un nuevo usuario me salía el siguiente error `Error: module "hello-friend-ng" not found;...` y para solucionarlo simplemente tuve que cambiar el nombre del tema y ya pude agregar un nuevo post.
```
mv themes/hugo-theme-hello-friend-ng/ themes/hello-friend-ng

hugo new posts/Bienvenida.md

cd content/posts/

rm creating-a-new-theme.md  goisforlovers.fr.md  goisforlovers.md  hugoisforlovers.fr.md  migrate-from-jekyll.fr.md
```

Creamos un archivo `gitignore` para no subir la carpeta public que vamos a generar con el contenido html
```
nano .gitignore

public/
```

Ahora que tenemos todo listo, vamos a crear un repositorio de github para github pages llamado juanan219.github.io y vamos a clonar dicho repositorio en nuestra máquina y vamos a generar dentro de él los archivos estáticos de hugo
```
git clone git@github.com:Juanan219/juanan219.github.io.git

cd JuananBlog/

hugo -d ../juanan219.github.io/
```

Cuando hayamos generado todos los archivos vamos a subirlos al nuevo repositorio
```
cd ../juanan219.github.io/

git add --all

git commit -am "Archivos estáticos HUGO"

git push
```

Por último, si nos dirigimos a la configuración de nuestro nuevo repositorio de GitHub, si bajamos, podremos ver un apartado llamado GitHub Pages, en el cual, si todo ha salido bien, nos dirá que nuestra página está subida a [la url que le hemos configurado](https://juanan219.github.io/)

![Captura 1](/web_estatica/1.PNG)
