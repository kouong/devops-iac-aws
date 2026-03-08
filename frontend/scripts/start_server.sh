#!/bin/bash

# Changer vers le répertoire de l'application web
cd /home/ec2-user/simple-webapp

# Démarrer l'application web Python en arrière-plan
# nohup: garde le processus en cours d'exécution même après la déconnexion
# > app.log: redirige la sortie standard vers le fichier app.log
# 2>&1: redirige les messages d'erreur vers le même fichier journal
# &: exécute la commande en arrière-plan
nohup python3 app.py > app.log 2>&1 &
