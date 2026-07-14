pipeline {
  agent none
  environment {
    REGISTRY = 'registry.k3d.localhost:5000'
    IMAGE    = 'spring-petclinic'
  }
  stages {
    stage('Build & Unit Tests') {
      agent { label 'java' }
      steps {
        script {
          env.IMAGE_TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
          echo "Image tag : ${env.IMAGE_TAG}"
        }
        sh './mvnw spring-javaformat:apply -q'
        sh './mvnw clean package -DskipTests -q'
        sh './mvnw test -Dtest="!OwnerRepositoryIntegrationTest,!PostgresIntegrationTest"'
      }
      post { always { junit 'target/surefire-reports/*.xml' } }
    }
    stage('Coverage') {
      agent { label 'java' }
      steps { sh './mvnw jacoco:report' }
      post { always { jacoco execPattern: 'target/jacoco.exec' } }
    }
    stage('Build & Push Image') {
      agent { label 'java' }
      steps {
        sh "docker build -t ${REGISTRY}/${IMAGE}:${env.IMAGE_TAG} ."
        sh "docker push ${REGISTRY}/${IMAGE}:${env.IMAGE_TAG}"
      }
    }
    stage('Deploy Staging') {
      agent { label 'java' }
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
