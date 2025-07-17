pipeline {
  agent any

  environment {
    ACR_NAME = 'goacr'
    ACR_LOGIN_SERVER = "${ACR_NAME}.azurecr.io"
    IMAGE_NAME = 'go-sample-app'
    HELM_RELEASE = 'go-sample-app'
    HELM_CHART_PATH = './myapp'
    KUBE_NAMESPACE = 'gonamespace'
  }

  parameters {
    booleanParam(name: 'ROLLBACK', defaultValue: false, description: 'Rollback to previous Helm revision')
  }

  stages {
    stage('Checkout Source') {
      when { expression { !params.ROLLBACK } }
      steps {
        checkout scm
      }
    }

    stage('Build Docker Image') {
      when { expression { !params.ROLLBACK } }
      steps {
        script {
          env.IMAGE_TAG = "${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${BUILD_NUMBER}"
          sh """
            echo "Building Docker image ${env.IMAGE_TAG}..."
            /opt/homebrew/bin/docker build -t ${env.IMAGE_TAG} .
          """
        }
      }
    }

    stage('Push to ACR') {
      when { expression { !params.ROLLBACK } }
      steps {
        script {
          sh """
            echo "Logging into ACR..."
            az acr login --name ${ACR_NAME}
            echo "Pushing ${env.IMAGE_TAG}..."
            docker push ${env.IMAGE_TAG}
          """
        }
      }
    }

    stage('Deploy to AKS with Helm') {
      when { expression { !params.ROLLBACK } }
      steps {
        script {
          sh """
            echo "Deploying with Helm..."
            helm upgrade --install ${HELM_RELEASE} ${HELM_CHART_PATH} \
              --namespace ${KUBE_NAMESPACE} \
              --set image.repository=${ACR_LOGIN_SERVER}/${IMAGE_NAME} \
              --set image.tag=${BUILD_NUMBER}
          """
        }
      }
    }

    stage('Rollback') {
      when { expression { params.ROLLBACK } }
      steps {
        input message: 'Confirm rollback to previous Helm revision?'
        script {
          sh """
            echo "Rolling back Helm release..."
            helm rollback ${HELM_RELEASE} --namespace ${KUBE_NAMESPACE}
          """
        }
      }
    }
  }

  post {
    success {
      echo '✅ Pipeline finished successfully!'
    }
    failure {
      echo '❌ Pipeline failed!'
    }
  }
}
