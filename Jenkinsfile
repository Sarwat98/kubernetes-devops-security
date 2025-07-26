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
              // script {
              //     def app = docker.build("devsecops/numeric-service:${env.BUILD_ID}", "-f Dockerfile .")
              //     app.push()
              // }
              withDockerRegistry([credentialsId: 'docker-hub', url: '']) {
                  sh 'printenv' // to see if the environment variables are set correctly
                  sh "docker build -t farisali07/numeric-service:${GIT_COMMIT} ."
                  sh "docker push farisali07/numeric-service:${GIT_COMMIT}"
              }
          }
      }
    }
}