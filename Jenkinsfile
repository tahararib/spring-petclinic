pipeline {
  agent {
    kubernetes {
      label 'java-dind'
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest-jdk21
    env:
    - name: DOCKER_HOST
      value: tcp://localhost:2375
  - name: dind
    image: docker:27-dind
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
    - name: DOCKER_DRIVER
      value: overlay2
"""
    }
  }
  environment {
    REGISTRY = 'registry.k3d.localhost:5000'
    IMAGE    = 'spring-petclinic'
  }
  stages {
    stage('Build & Unit Tests') {
      steps {
        script {
          env.IMAGE_TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
          echo "Image tag : ${env.IMAGE_TAG}"
        }
        sh 'chmod +x mvnw && ./mvnw spring-javaformat:apply -q'
        sh './mvnw clean package -DskipTests -q'
        sh './mvnw test -Dtest="!OwnerRepositoryIntegrationTest,!PostgresIntegrationTest,!PostgresIntegrationTests,!MySqlIntegrationTests"'
      }
      post { always { junit 'target/surefire-reports/*.xml' } }
    }
    stage('Coverage') {
      steps { sh './mvnw jacoco:report' }
      post { always { jacoco execPattern: 'target/jacoco.exec' } }
    }
    stage('Build & Push Image') {
      steps {
        sh """
          docker build \
            --add-host registry.k3d.localhost:\$(getent hosts host.docker.internal | awk '{print \$1}' || echo 172.17.0.1) \
            -t ${REGISTRY}/${IMAGE}:${env.IMAGE_TAG} .
          docker push ${REGISTRY}/${IMAGE}:${env.IMAGE_TAG}
        """
      }
    }
    stage('Deploy Staging') {
      steps {
        sh """
          helm upgrade --install petclinic-staging \
            ./helm/spring-petclinic \
            -n staging --create-namespace \
            -f helm/spring-petclinic/values-staging.yaml \
            --set app.image.tag=${env.IMAGE_TAG} --wait
        """
      }
    }
  }
  post {
    failure { echo "Pipeline echoue — consulter les logs de stage" }
    success { echo "Deploye : ${REGISTRY}/${IMAGE}:${env.IMAGE_TAG}" }
  }
}
