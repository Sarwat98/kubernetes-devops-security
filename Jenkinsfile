pipeline {
  agent any
  environment {
        SONARQUBE_ENV = 'SonarQube' // Optional: for clarity
    }

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
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.projectName="numeric-application"'
                }
            }
        }
        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

                
        stage('Mutation Testing - PIT') {
            steps {
                sh "mvn org.pitest:pitest-maven:mutationCoverage"
            }
            post {
                always {
                    pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
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
                    sh "sed -i 's|image:.*|image: farisali07/numeric-service:${GIT_COMMIT}|' k8s_deployment_service.yaml"
                    sh "kubectl apply -f k8s_deployment_service.yaml"
                }
            }
            }
        }
        }
}