#!/bin/bash
# Script de vérification de déploiement
# Usage: ./verify.sh <DEPLOY_ENV>

set -e  # Arrêt en cas d'erreur

# Vérification des arguments
if [ $# -ne 1 ]; then
    echo "Usage: $0 <DEPLOY_ENV>"
    echo "Exemple: $0 STAGING"
    exit 1
fi

DEPLOY_ENV=$1

# Configuration selon l'environnement
if [ "$DEPLOY_ENV" = "STAGING" ]; then
    TOMCAT_URL="http://192.168.56.13:8080"
    CONTEXT_PATH="petclinic-staging"
    DB_NAME="petclinic_staging"
elif [ "$DEPLOY_ENV" = "PROD" ]; then
    TOMCAT_URL="http://192.168.56.13:8080"
    CONTEXT_PATH="petclinic-prod"
    DB_NAME="petclinic_prod"
else
    echo "Erreur: Environnement inconnu: $DEPLOY_ENV"
    echo "Les valeurs valides sont STAGING ou PROD"
    exit 1
fi

echo "=== Vérification du déploiement sur $DEPLOY_ENV ==="

# 1. Vérifier que l'application est accessible
echo "Vérification de l'accès à l'application..."
RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$TOMCAT_URL/$CONTEXT_PATH")

if [ "$RESPONSE_CODE" = "200" ] || [ "$RESPONSE_CODE" = "302" ]; then
    echo "✅ Application accessible (HTTP $RESPONSE_CODE)"
else
    echo "❌ Application non accessible (HTTP $RESPONSE_CODE)"
    exit 1
fi

# 2. Vérifier que la page d'accueil contient du contenu attendu
echo "Vérification du contenu de la page d'accueil..."
if curl -s "$TOMCAT_URL/$CONTEXT_PATH" | grep -q "PetClinic"; then
    echo "✅ Contenu de la page d'accueil vérifié"
else
    echo "❌ Contenu de la page d'accueil incorrect"
    exit 1
fi

# 3. Vérifier la connexion à la base de données (optionnel)
echo "Vérification de la connexion à la base de données..."
if curl -s "$TOMCAT_URL/$CONTEXT_PATH/owners" | grep -q "Find owners"; then
    echo "✅ Fonctionnalité utilisant la base de données vérifiée"
else
    echo "❌ Problème avec la fonctionnalité utilisant la base de données"
    exit 1
fi

echo "=== Vérification complète : déploiement réussi sur $DEPLOY_ENV ==="