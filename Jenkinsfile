pipeline {
  agent any

  environment {
    PATH = "/opt/homebrew/bin:/usr/local/bin:$PATH"
    ACR_NAME = 'goacr'
    ACR_LOGIN_SERVER = "${ACR_NAME}.azurecr.io"
    IMAGE_NAME = 'go-sample-app'
    HELM_RELEASE = 'go-sample-app'
    HELM_CHART_PATH = './myapp'
    KUBE_NAMESPACE = 'gonamespace'
  }

  parameters {
    choice(name: 'ENVIRONMENT', choices: ['dev', 'uat', 'prod'], description: 'Select target environment')
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
            docker build -t ${env.IMAGE_TAG} .
          """
        }
      }
    }

    stage('Push to ACR') {
      when { expression { !params.ROLLBACK } }
      steps {
        script {
          withCredentials([azureServicePrincipal('sp')]) {
            sh 'az login --service-principal -u $AZURE_CLIENT_ID -p="$AZURE_CLIENT_SECRET" -t $AZURE_TENANT_ID'
          }
          sh """
            az acr login --name ${ACR_NAME}
            echo "Pushing ${env.IMAGE_TAG}..."
            docker push ${env.IMAGE_TAG}
            echo "Image ${env.IMAGE_TAG} pushed to ${ACR_NAME}..."
          """
        }
      }
    }

    stage('Select AKS Cluster') {
      steps {
        script {
          if (params.ENVIRONMENT == 'dev') {
            env.AKS_RG = 'GO'
            env.AKS_CLUSTER = 'myAksCluster'
          } else if (params.ENVIRONMENT == 'uat') {
            env.AKS_RG = 'uat-rg'
            env.AKS_CLUSTER = 'aks-uat'
          } else {
            env.AKS_RG = 'prod-rg'
            env.AKS_CLUSTER = 'aks-prod'
          }
        }
      }
    }

    stage('Authenticate to AKS') {
      steps {
        script {
          withCredentials([azureServicePrincipal('sp')]) {
            sh """
              az login --service-principal -u $AZURE_CLIENT_ID -p="$AZURE_CLIENT_SECRET" -t $AZURE_TENANT_ID
              az aks get-credentials --resource-group ${env.AKS_RG} --name ${env.AKS_CLUSTER} --overwrite-existing
            """
          }
        }
      }
    }

    stage('Deploy to AKS with Helm') {
      when { expression { !params.ROLLBACK } }
      steps {
        script {
          sh """
            echo "Deploying with Helm to ${env.AKS_CLUSTER}..."
            helm upgrade --install ${HELM_RELEASE} ${HELM_CHART_PATH} \
              --namespace ${KUBE_NAMESPACE} \
              --create-namespace \
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
            echo "Rolling back Helm release on ${env.AKS_CLUSTER}..."
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
