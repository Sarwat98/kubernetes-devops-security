@Library('slack') _ // Import the Slack library for notifications

pipeline {
  agent any
  environment {
        SONARQUBE_ENV = 'SonarQube' // Optional: for clarity
        deploymentName = "devsecops"
        containerName  = "devsecops-container"
        serviceName    = "devsecops-svc"
        imageName      = "farisali07/numeric-service:${GIT_COMMIT}"
        applicationURL = "http://devsecops-demo-07.centralus.cloudapp.azure.com"
        applicationURI = "compare/99"
        CHEF_LICENSE = 'accept-silent'      // harmless even though we use -t local://
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
        } 

        // stage('SonarQube Analysis') {
        //     steps {
        //         withSonarQubeEnv("${SONARQUBE_ENV}") {
        //             sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.projectName="numeric-application"'
        //         }
        //     }
        // }

        // stage('Quality Gate') {  
        //     steps {
        //         timeout(time: 2, unit: 'MINUTES') {
        //             waitForQualityGate abortPipeline: true
        //         }
        //     }
        // }

                
        // stage('Mutation Testing - PIT') {
        //     steps {
        //         sh "mvn org.pitest:pitest-maven:mutationCoverage"
        //     }
        // }

        // stage('Vulnerability Scan - Dependency  - Docker') {
        //     steps {
        //         parallel (
        //             'Dependency Check': {
        //                 sh 'mvn dependency-check:check'
        //             },
        //             'Trivy Scan': {
        //                 sh "bash trivy-docker-image-scan.sh"
        //             },
        //             'OPA Conftest Scan': {
        //                 sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile' // --output json --output-file conftest-results.json
        //             }
        //         )
        //     }
        // }

        stage('Build Docker and Push Image') {
            steps {
                withDockerRegistry([credentialsId: 'docker-hub-token', url: '']) {
                    sh 'printenv' // to see if the environment variables are set correctly
                    sh "sudo docker build -t farisali07/numeric-service:${GIT_COMMIT} ."
                    sh "docker push farisali07/numeric-service:${GIT_COMMIT}"
                }
            }
        }

        // stage('Vulneraility Scan - Kubernetes') {
        //     steps {
        //         parallel (
        //             'OPA Conftest Scan': {
        //                 sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
        //             },
        //             'Kubesec Scan': {
        //                 sh "bash kubesec-scan.sh"
        //             },
        //             'Trivy Scan': {
        //                 sh "bash trivy-k8s-scan.sh"
        //             }
        //         )
        //     }
        // }

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

        stage('InSpec - in Docker') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                withEnv(['JAVA_TOOL_OPTIONS=', '_JAVA_OPTIONS=', 'MAVEN_OPTS=', 'JACOCO_AGENT=']) {
                    sh '''#!/usr/bin/env bash
                            set -Eeuo pipefail

                            docker run --rm \
                            -v "$PWD":/work \
                            -v "$KUBECONFIG":/root/.kube/config:ro \
                            -e KUBECONFIG=/root/.kube/config \
                            -e CHEF_LICENSE=accept-silent \
                            -e JAVA_TOOL_OPTIONS= -e _JAVA_OPTIONS= -e MAVEN_OPTS= -e JACOCO_AGENT= \
                            chef/inspec:5 sh -lc '
                                set -eu
                                cd /work

                                # OPTIONAL: install kubectl inside the container if not present
                                if ! command -v kubectl >/dev/null 2>&1; then
                                echo "Installing kubectl..."
                                curl -fsSL -o /usr/local/bin/kubectl \
                                    "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                                chmod +x /usr/local/bin/kubectl
                                fi

                                kubectl version --client --short || true
                                inspec version

                                inspec exec k8s-deploy-audit -t local:// \
                                --input ns=prod deploy_name=devsecops label_key=app label_val=devsecops \
                                --input ignore_containers="[\\\"istio-proxy\\\"]" \
                                --reporter cli json:inspec.json junit:inspec-junit.xml
                            '
                            '''
                }
                }
            }
        }
    

        stage('K8S Deployment -- DEV') {
            steps {
                parallel(
                    "Deployment": {
                        withKubeConfig([credentialsId: 'kubeconfig']) {
                            sh "bash k8s-deployment.sh"
                        }
                    },
                    "Rollout Status": {
                        withKubeConfig([credentialsId: 'kubeconfig']) {
                            sh "bash k8s-deployment-rollout-status.sh"
                        }
                    }
                )
            }
        }
        // stage('Integration Tests - DEV') {
        //     steps {
        //         script {
        //         try {
        //             withKubeConfig([credentialsId: 'kubeconfig']) {
        //             sh 'bash integration-test.sh'
        //             }
        //         } catch (e) {
        //             withKubeConfig([credentialsId: 'kubeconfig']) {
        //             sh "kubectl -n default rollout undo deploy ${deploymentName}"
        //             }
        //             throw e
        //         }
        //         }
        //     }
        // }

        // stage('OWASP ZAP Scan - DAST') {
        //     steps {
        //         withKubeConfig([credentialsId: 'kubeconfig']) {
        //             sh "bash owasp-zap-scan.sh"
        //         }
        //     }
        // }

        // stage('Burp DAST Scan') {
        //     steps {
        //         script {
        //             // Run Burp Suite DAST Scan
        //             // sh """
        //             //     java -jar /path/to/burp-suite.jar --project-file=/path/to/project.burp --headless --scan --url http://your-app-url
        //             // """
        //         }
        //     }
        // }

        // stage('Prompte to PROD') {
        //     steps {
        //         timeout(time: 2, unit: 'DAYS') {
        //             input message: 'Do you want to promote the build to PROD?', ok: 'Yes, Promote'
        //         }
        //     }
        // }

        // stage('Testing Slack Notifications') {
        //     steps {
        //         sh 'echo "Testing Slack Notifications"'
        //         sh 'exit 0' // Simulate a successful step
        //     }
        // }

        // stage('K8S CIS Benchmark Scan') {
        //     steps {
        //         script {
        //             parallel (
        //                 'Master': {
        //                     sh "bash cis-master.sh"
        //                 },
        //                 'Etcd': {
        //                     sh "bash cis-etcd.sh"
        //                 },
        //                 'Kubelet': {
        //                     sh "bash cis-kubelet.sh"
        //                 }
        //             )
        //         }
        //     }
        // }

        

        // stage('K8S Deployment -- PROD') {
        //     steps {
        //         parallel(
        //             "Deployment": {
        //                 withKubeConfig([credentialsId: 'kubeconfig']) {
        //                     sh "sed -i 's#replace#${imageName}#g' k8s_PROD-deployment_service.yaml"
        //                     sh "kubectl -n prod apply -f k8s_PROD-deployment_service.yaml"
        //                 }
        //             },
        //             "Rollout Status": {
        //                 withKubeConfig([credentialsId: 'kubeconfig']) {
        //                     sh "bash k8s-PROD-deployment-rollout-status.sh"
        //                 }
        //             }
        //         )
        //     }
        // }


   }

    // post { 
    //         always {
    //                     junit 'target/surefire-reports/*.xml'
    //                     jacoco execPattern: 'target/jacoco.exec'
    //                     pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
    //                     dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
    //                     publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report', useWrapperFileDirectly: true])
    //                     // sendNotification(currentBuild.currentResult ?: 'SUCCESS')
    //                     sendNotification currentBuild.result 
    //                     junit 'k8s-deploy-audit/inspec-junit.xml'
    //                     archiveArtifacts artifacts: 'k8s-deploy-audit/inspec.json', fingerprint: true
    //         } 
    //         success {
    //             echo 'Pipeline completed successfully!'
    //         }
    //         failure {
    //             echo 'Pipeline failed!'
    //         }
    //     }
}