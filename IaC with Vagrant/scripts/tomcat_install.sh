#!/bin/bash

echo "=== Installation de Tomcat ==="

# Installation de Java 17
apt-get update
apt-get install -y openjdk-17-jdk

# Téléchargement et extraction de Tomcat
cd /tmp
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.15/bin/apache-tomcat-10.1.15.tar.gz
tar -xf apache-tomcat-10.1.15.tar.gz
mv apache-tomcat-10.1.15 /opt/tomcat

# Création de l'utilisateur tomcat
useradd -m -d /opt/tomcat -s /bin/false tomcat
chown -R tomcat:tomcat /opt/tomcat
chmod +x /opt/tomcat/bin/*.sh

# Configuration des utilisateurs pour l'interface d'administration
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

# Permettre les connexions distantes pour le manager
mkdir -p /opt/tomcat/conf/Catalina/localhost
cat > /opt/tomcat/conf/Catalina/localhost/manager.xml << EOF
<Context privileged="true" antiResourceLocking="false"
         docBase="\${catalina.home}/webapps/manager">
    <Valve className="org.apache.catalina.valves.RemoteAddrValve"
           allow="127\\.\\d+\\.\\d+\\.\\d+|::1|0:0:0:0:0:0:0:1|192\\.168\\.\\d+\\.\\d+" />
</Context>
EOF

# Création du service systemd pour Tomcat
cat > /etc/systemd/system/tomcat.service << EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
Environment=JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Démarrage du service Tomcat
systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat

echo "=== Tomcat installé ==="
echo "L'interface web sera disponible sur http://192.168.56.13:8080"
echo "Interface d'administration : http://192.168.56.13:8080/manager/html"
echo "Identifiants : admin / admin"