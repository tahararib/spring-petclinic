pipeline {
    agent {label 'master'}
    
    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['STAGING', 'PROD'], description: 'Choisir l\'environnement de déploiement')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Ignorer les tests')
        booleanParam(name: 'ARCHIVE_ARTIFACT', defaultValue: true, description: 'Archiver l\'artefact après le build')
    }
    
    environment {
        // Variables globales
        TOMCAT_URL = "https://192.168.56.13:8080"
        TOMCAT_USER = "deployer"
        TOMCAT_PASSWORD = "deployer"
        MYSQL_HOST = "192.168.56.14"
        MYSQL_USER = "petclinic"
        MYSQL_PASSWORD = "petclinic"
        APP_NAME = "petclinic"
        
        // Répertoire pour les artefacts
        ARTIFACTS_DIR = "${JENKINS_HOME}/artifacts/${APP_NAME}"
    }
    
    tools {
        jdk "localJDK"
        maven "localMaven"
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Nettoyage de l'espace de travail
                cleanWs()
                
                // Récupérer le code source depuis le dépôt
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                // Construction du projet avec le profil spécifique à l'environnement
                script {
                    def profile = params.DEPLOY_ENV.toLowerCase()
                    sh "mvn clean package -DskipTests=${params.SKIP_TESTS} -P${profile} -Dspring-javaformat.skip=true"
                }
                
                // Archiver l'artefact dans Jenkins si demandé
                script {
                    if (params.ARCHIVE_ARTIFACT) {
                        archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                    }
                }
            }
        }
        
        stage('Tests') {
            when {
                expression { return !params.SKIP_TESTS }
            }
            steps {
                // Exécution des tests
                sh "mvn test"
                
                // Publication des résultats des tests
                junit '**/target/surefire-reports/*.xml'
            }
        }
        
        stage('Deploy') {
            steps {
                // Déploiement en utilisant le script externe
                script {
                    // Rendre le script exécutable (au cas où)
                    sh "chmod +x scripts/deploy.sh"
                    
                    // Exécuter le script de déploiement
                    sh "./scripts/deploy.sh ${params.DEPLOY_ENV} target/${APP_NAME}.war"
                    
                    // Archiver l'artefact avec version dans un répertoire centralisé
                    def version = sh(script: "grep -m 1 '<version>' pom.xml | sed -E 's/.*<version>(.*)<\\/version>.*/\\1/'", returnStdout: true).trim()
                    def deployEnv = params.DEPLOY_ENV.toLowerCase()
                    
                    sh """
                        # Créer le répertoire des artefacts s'il n'existe pas
                        mkdir -p ${ARTIFACTS_DIR}/${deployEnv}
                        
                        # Copier le WAR avec un nom incluant la version
                        cp target/${APP_NAME}.war ${ARTIFACTS_DIR}/${deployEnv}/${APP_NAME}-${version}-${BUILD_NUMBER}.war
                        
                        # Créer un lien symbolique vers la dernière version
                        ln -sf ${ARTIFACTS_DIR}/${deployEnv}/${APP_NAME}-${version}-${BUILD_NUMBER}.war ${ARTIFACTS_DIR}/${deployEnv}/${APP_NAME}-latest.war
                    """
                }
            }
        }
        
        stage('Verify') {
            steps {
                // Vérification du déploiement
                script {
                    // Attendre un peu que l'application démarre complètement
                    sh "sleep 10"
                    
                    // Rendre le script exécutable (au cas où)
                    sh "chmod +x scripts/verify.sh"
                    
                    // Exécuter le script de vérification
                    sh "./scripts/verify.sh ${params.DEPLOY_ENV}"
                }
            }
        }
    }
    
    post {
        success {
            echo "Pipeline terminé avec succès. Application déployée sur ${params.DEPLOY_ENV}."
        }
        failure {
            echo "Le pipeline a échoué. Vérifiez les logs pour plus d'informations."
        }
        always {
            // Nettoyage de l'espace de travail
            cleanWs()
        }
    }
}

