#!/bin/bash

echo "=== Configuration de base pour toutes les VMs ==="

# Mise à jour des paquets
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Installation des utilitaires de base
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    git \
    unzip \
    vim \
    net-tools

# Configuration de l'heure
timedatectl set-timezone UTC

echo "=== Configuration de base terminée ==="