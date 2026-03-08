#!/bin/bash
# Ce script installe les dépendances nécessaires pour une application web Flask

# Installer Python 3 et le gestionnaire de paquets pip en utilisant yum (pour Amazon Linux/RHEL/CentOS)
yum install -y python3-pip

# Installer le framework web Flask en utilisant pip3
pip3 install flask
