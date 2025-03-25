#!/bin/bash

echo "=== Configuration de Jenkins Agent ==="

# Installation de Java 17
apt-get update
apt-get install -y openjdk-17-jdk

# Création de l'utilisateur jenkins
useradd -m -d /home/jenkins -s /bin/bash jenkins

# Mot de passe pour l'utilisateur jenkins
echo "jenkins:jenkins" | chpasswd

# Création du répertoire de travail
mkdir -p /home/jenkins/agent
chown -R jenkins:jenkins /home/jenkins/agent

# Installation des outils nécessaires
apt-get install -y git maven

echo "=== Agent Jenkins configuré ==="
echo "Vous pourrez connecter cet agent depuis l'interface Jenkins"