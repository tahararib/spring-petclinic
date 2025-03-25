#!/bin/bash

echo "=== Installation et configuration de Tomcat ==="

# Mise à jour du système et installation de Java 17
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk wget curl

# Vérification de l'installation de Java
if ! java -version &>/dev/null; then
    echo "Erreur : Java n'est pas installé correctement !"
    exit 1
fi

# Définition de JAVA_HOME
echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" | sudo tee -a /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Téléchargement et extraction de Tomcat
cd /home/vagrant

wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.39/bin/apache-tomcat-10.1.39.tar.gz

sudo mkdir /opt/tomcat

sudo tar xzvf apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1

# configuration de l'utilisateur vagrant
sudo chown -R vagrant:vagrant /opt/tomcat/
sudo chmod -R g+r /opt/tomcat/conf
sudo chmod g+x /opt/tomcat/conf
sudo chmod +x /opt/tomcat/bin/*.sh


# Création du répertoire temp s'il n'existe pas
sudo mkdir -p /opt/tomcat/temp
sudo chown -R vagrant:vagrant /opt/tomcat/temp

# Configuration des utilisateurs Tomcat pour l'administration
cat > /opt/tomcat/conf/tomcat-users.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
  <role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <role rolename="admin-gui"/>
  <user username="admin" password="admin" roles="manager-gui,manager-script,admin-gui"/>
  <user username="deployer" password="deployer" roles="manager-script"/>
</tomcat-users>
EOF

# Activation des connexions distantes pour le Tomcat Manager
sudo mkdir -p /opt/tomcat/conf/Catalina/localhost
cat > /opt/tomcat/conf/Catalina/localhost/manager.xml << EOF
<Context privileged="true" antiResourceLocking="false"
         docBase="\${catalina.home}/webapps/manager">
    <Valve className="org.apache.catalina.valves.RemoteAddrValve"
           allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1|192\\.168\\.\\d+\\.\\d+" />
</Context>
EOF

# Création du service systemd pour Tomcat
sudo bash -c 'cat > /etc/systemd/system/tomcat.service << EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=vagrant
Group=vagrant
Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom"

ExecStart=/opt/tomcat/bin/catalina.sh start
ExecStop=/opt/tomcat/bin/catalina.sh stop

Restart=always
RestartSec=10
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF'

# Rechargement de systemd et activation du service
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl restart tomcat

# Vérification du statut
sudo systemctl status tomcat --no-pager

echo "=== Tomcat installé et configuré avec succès ==="
echo "Accédez à l'interface web : http://192.168.56.13:8080"
echo "Interface d'administration : http://192.168.56.13:8080/manager/html"
echo "Identifiants : admin / admin"
echo ""
echo "Commandes utiles :"
echo "  - sudo systemctl status tomcat   # Vérifier le statut"
echo "  - sudo systemctl restart tomcat  # Redémarrer Tomcat"
echo "  - sudo journalctl -u tomcat -xe  # Voir les logs détaillés"
