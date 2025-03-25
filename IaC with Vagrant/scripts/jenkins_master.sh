#!/bin/bash

echo "=== Installation de Jenkins Master ==="

# Installation de Java 17
apt-get update
apt-get install -y openjdk-17-jdk

# Ajout de la clé et du dépôt Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "Installing git" 
sudo apt -y install git > /dev/null 2>&1

echo "Installing git-ftp"
sudo apt -y install git-ftp > /dev/null 2>&1


# Installation de Jenkins
apt-get update
echo "Installing Jenkins" 
apt-get install -y jenkins

# Démarrage de Jenkins
systemctl start jenkins
systemctl enable jenkins

sleep 1m

echo "Installing Maven"
sudo apt install maven -y

# Récupération du mot de passe initial
echo "=== Jenkins installé avec succès ==="
echo "Mot de passe initial d'administration : "
cat /var/lib/jenkins/secrets/initialAdminPassword