#!/bin/bash

echo "=== Installation de SonarQube ==="

# Installation de Java 17
apt-get update
apt-get install -y openjdk-17-jdk

# Configuration système pour Elasticsearch (utilisé par SonarQube)
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | tee -a /etc/sysctl.conf

# Création de l'utilisateur sonarqube
useradd -m -d /opt/sonarqube -s /bin/bash sonarqube

# Téléchargement et extraction de SonarQube
cd /tmp
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.0.65466.zip
unzip sonarqube-9.9.0.65466.zip
mv sonarqube-9.9.0.65466 /opt/sonarqube
chown -R sonarqube:sonarqube /opt/sonarqube

# Création du service systemd pour SonarQube
cat > /etc/systemd/system/sonarqube.service << EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Démarrage du service SonarQube
systemctl daemon-reload
systemctl start sonarqube
systemctl enable sonarqube

echo "=== SonarQube installé ==="
echo "L'interface web sera disponible sur http://192.168.56.12:9000"
echo "Identifiants par défaut : admin / admin"