pipeline {
  agent {
    kubernetes {
      defaultContainer 'jnlp'
      yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest-jdk21
    env:
    - name: DOCKER_HOST
      value: tcp://localhost:2375
    resources:
      requests: {cpu: "1", memory: 2Gi}
      limits: {memory: 4Gi}
  - name: dind
    image: docker:27-dind
    securityContext: {privileged: true}
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
    args: ["--insecure-registry=registry.k3d.localhost:5000"]
    resources:
      requests: {cpu: 500m, memory: 1Gi}
      limits: {memory: 2Gi}
    volumeMounts:
    - {name: dind-storage, mountPath: /var/lib/docker}
  - name: helm
    image: alpine/helm:3.16.2
    command: ["cat"]
    tty: true
  volumes:
  - {name: dind-storage, emptyDir: {}}
'''
    }
  }
  options { timeout(time: 30, unit: 'MINUTES') }
  environment {
    REGISTRY  = 'registry.k3d.localhost:5000'
    IMAGE     = 'spring-petclinic'
  }
  stages {
    stage('Build & Unit Tests') {
		steps {
			script {
				env.IMAGE_TAG = sh(returnStdout: true,
				script: 'git rev-parse --short=7 HEAD').trim()
				}
			sh './mvnw spring-javaformat:apply -q'
			sh './mvnw clean package -DskipTests -q'
			sh './mvnw test'
		}
		post { always { junit 'target/surefire-reports/*.xml' } }
		}
    stage('Coverage') {
      steps { sh './mvnw jacoco:report' }
      post { always { jacoco execPattern: 'target/jacoco.exec' } }
    }

stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv('sonar-server') {
          sh 'SONAR_URL=http://sonarqube-sonarqube.sonarqube.svc.cluster.local:9000 && ./mvnw sonar:sonar -Dsonar.projectKey=spring-petclinic -Dsonar.host.url=${SONAR_URL}'
        }
        timeout(time: 5, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }
    stage('Integration Tests') {
      steps { sh './mvnw verify -Pintegration-tests' }
      post { always { junit 'target/failsafe-reports/*.xml' } }
    }
    stage('Build & Push Image') {
      steps {
        container('dind') {
          sh "docker build -f Dockerfile.ci -t ${REGISTRY}/${IMAGE}:${env.IMAGE_TAG} ."
          sh "docker push ${REGISTRY}/${IMAGE}:${env.IMAGE_TAG}"
        }
      }
    }
    stage('Deploy Staging') {
      steps {
        sh '''
          rm -rf infra
          git clone --depth 1 https://github.com/tahararib/spring-petclinic-infra.git infra
        '''
        container('helm') {
          sh '''
            helm upgrade --install petclinic-staging infra/helm/spring-petclinic \
              -n staging --create-namespace \
              -f infra/helm/spring-petclinic/values-staging.yaml \
              --set app.image.tag=${IMAGE_TAG} \
              --wait --timeout 5m
          '''
        }
      }
    }
  }
  post {
    failure { echo 'Pipeline echoue — consulter les logs de stage' }
    success { echo "Deploye : ${REGISTRY}/${IMAGE}:${env.IMAGE_TAG}" }
  }
}