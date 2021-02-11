#!/bin/bash

read -p "Texto de commit: " COMMIT
git add .
git commit -am $COMMIT
git push
hugo -d ../juanan219.github.io
../juanan219.github.io/./.actualizar_blog.sh
