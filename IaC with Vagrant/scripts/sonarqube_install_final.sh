#!/bin/bash
# Script d'installation et de configuration amélioré pour SonarQube

set -e  # Arrêt en cas d'erreur

echo "=== Installation de SonarQube avec configuration automatique ==="

# Configuration du DNS pour éviter les problèmes de résolution
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf > /dev/null

# Mise à jour du système
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk wget unzip curl

# Configuration système pour Elasticsearch
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

# Téléchargement et installation de SonarQube
cd /tmp
wget -q https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.0.65466.zip
unzip -q sonarqube-9.9.0.65466.zip
sudo rm -rf /opt/sonarqube
sudo mv sonarqube-9.9.0.65466 /opt/sonarqube

# Configuration des permissions pour l'utilisateur vagrant
sudo chown -R vagrant:vagrant /opt/sonarqube
sudo chmod -R 755 /opt/sonarqube

# Vérification des permissions cruciales
sudo mkdir -p /opt/sonarqube/data
sudo mkdir -p /opt/sonarqube/temp
sudo mkdir -p /opt/sonarqube/logs
sudo chown -R vagrant:vagrant /opt/sonarqube/data /opt/sonarqube/temp /opt/sonarqube/logs
sudo chmod -R 755 /opt/sonarqube/data /opt/sonarqube/temp /opt/sonarqube/logs
sudo chmod -R 777 /opt/sonarqube/temp

# Configuration de SonarQube - configuration COMPLÈTE avec tous les paramètres requis
# Création du service systemd
sudo bash -c 'cat > /etc/systemd/system/sonarqube.service << EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
User=vagrant
Group=vagrant
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh console
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
StandardOutput=syslog
LimitNOFILE=65536
LimitNPROC=4096
Restart=on-failure
RestartSec=60
StartLimitIntervalSec=300
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF'

# Configuration NOPASSWD pour vagrant (permet d'exécuter sudo sans mot de passe)
echo "vagrant ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/vagrant > /dev/null
sudo chmod 0440 /etc/sudoers.d/vagrant

# Rechargement de systemd et démarrage du service
sudo systemctl daemon-reload
sudo systemctl enable sonarqube
# sudo systemctl start sonarqube
cd /opt/sonarqube/bin/linux-x86-64
./sonar.sh console

# Affichage des informations de service
echo "=== SonarQube configuré et démarré ==="
echo "Il peut prendre quelques minutes pour démarrer complètement"
echo "Vous pourrez y accéder via http://192.168.56.12:9000"
echo "Identifiants par défaut : admin / admin"
echo ""
echo "Commandes utiles :"
echo "  - sudo systemctl status sonarqube : Vérifier l'état du service"
echo "  - sudo systemctl restart sonarqube : Redémarrer le service"
echo "  - sudo journalctl -fu sonarqube : Voir les logs du service"
echo ""
echo "Le service est configuré pour démarrer automatiquement au boot"
