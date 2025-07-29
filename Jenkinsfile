pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' //so that they can be downloaded later
            }
        }  
      stage('Unit Tests -- JUnit and Jacoco') {
          steps {
              sh "mvn test"
          }
          post {
              always {
                  junit 'target/surefire-reports/*.xml'
                  jacoco execPattern: 'target/jacoco.exec'
              }
          }
      } 
        // stage('SonarQube Analysis') {
        //       steps {
        //           script {
        //               withSonarQubeEnv('sonarqube') {
        //                   sh "mvn sonar:sonar"
        //               }
        //           }
        //       }
        //   }
      stage('Build Docker and Push Image') {
          steps {
              withDockerRegistry([credentialsId: 'docker-hub-token', url: '']) {
                  sh 'printenv' // to see if the environment variables are set correctly
                  sh "docker build -t farisali07/numeric-service:${GIT_COMMIT} ."
                  sh "docker push farisali07/numeric-service:${GIT_COMMIT}"
              }
          }
      }
      stage('Deploy to Kubernetes - DEV') {
          steps {
            withKubeConfig([credentialsId: 'kubeconfig']) {
              script {
                  def k8sConfig = readYaml file: 'k8s_deployment_service.yaml'
                  k8sConfig.spec.template.spec.containers[0].image = "farisali07/numeric-service:${GIT_COMMIT}"
                  writeYaml file: 'k8s_deployment_service.yaml', data: k8sConfig
                  sh "kubectl apply -f k8s_deployment_service.yaml"
              }
          }
        }
      }
    }
}