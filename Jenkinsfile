pipeline {
  agent none
  environment {
    REGISTRY  = 'registry.k3d.localhost:5000'
    IMAGE     = 'spring-petclinic'
    IMAGE_TAG = "${env.GIT_COMMIT?.take(7) ?: 'dev'}"
  }
  stages {
    stage('Build & Unit Tests') {
      agent { label 'java' }
      steps {
        sh './mvnw spring-javaformat:apply -q'
        sh './mvnw clean package -DskipTests -q'
        sh './mvnw test'
      }
      post { always { junit 'target/surefire-reports/*.xml' } }
    }
    stage('Coverage') {
      agent { label 'java' }
      steps { sh './mvnw jacoco:report' }
      post { always { jacoco execPattern: 'target/jacoco.exec' } }
    }
    stage('Integration Tests') {
      agent { label 'java' }
      steps {
        sh './mvnw verify -Pintegration-tests'
      }
      post { always { junit 'target/failsafe-reports/*.xml' } }
    }
    stage('Build & Push Image') {
      agent { label 'java' }
      steps {
        sh "docker build -t ${REGISTRY}/${IMAGE}:${IMAGE_TAG} ."
        sh "docker push ${REGISTRY}/${IMAGE}:${IMAGE_TAG}"
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
            --set app.image.tag=${IMAGE_TAG} --wait
        """
      }
    }
  }
  post {
    failure { echo "Pipeline echoue — consulter les logs de stage" }
    success { echo "Deploye : ${REGISTRY}/${IMAGE}:${IMAGE_TAG}" }
  }
}
