#!/bin/bash
# Script d'installation SonarQube avec correction DNS

echo "=== Correction de la configuration DNS ==="
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'

echo "=== Mise à jour des packages ==="
sudo apt-get update

echo "=== Installation de Java et autres dépendances ==="
sudo apt-get install -y openjdk-17-jdk wget unzip

echo "=== Configuration système pour Elasticsearch ==="
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

echo "=== Téléchargement et installation de SonarQube ==="
cd /tmp
wget -q https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.0.65466.zip
unzip -q sonarqube-9.9.0.65466.zip
sudo mv sonarqube-9.9.0.65466 /opt/sonarqube

echo "=== Configuration du service SonarQube ==="
sudo bash -c 'cat > /etc/systemd/system/sonarqube.service << EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

echo "=== SonarQube installé (accessible sur http://localhost:9000) ==="
echo "Identifiants par défaut : admin/admin"