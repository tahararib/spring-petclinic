#!/bin/bash

echo "=== Installation de MySQL ==="

# Installation de MySQL
apt-get update
apt-get install -y mysql-server

# Démarrage du service MySQL
systemctl start mysql
systemctl enable mysql

# Sécurisation de l'installation MySQL
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root'; FLUSH PRIVILEGES;"

# Création d'une base de données et d'un utilisateur pour les applications
mysql -u root -proot -e "CREATE DATABASE petclinic;"
mysql -u root -proot -e "CREATE USER 'petclinic'@'%' IDENTIFIED BY 'petclinic';"
mysql -u root -proot -e "GRANT ALL PRIVILEGES ON petclinic.* TO 'petclinic'@'%';"
mysql -u root -proot -e "FLUSH PRIVILEGES;"

# Configuration de MySQL pour accepter les connexions distantes
sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql

echo "=== MySQL installé ==="
echo "Base de données 'petclinic' créée"
echo "Utilisateur: petclinic / Mot de passe: petclinic"
echo "Mot de passe root MySQL: root"