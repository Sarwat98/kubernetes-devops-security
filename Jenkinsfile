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

        stage('InSpec - K8s checks') {
             steps {
                // bind the kubeconfig to KUBECONFIG
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                // make sure any JaCoCo/Java agents don't interfere
                withEnv(['JAVA_TOOL_OPTIONS=', 'JACOCO_AGENT=', 'JACOCO_HOME=']) {
                    sh '''#!/usr/bin/env bash
                    set -euxo pipefail

                    echo "== sanity: kubectl can talk to the cluster =="
                    kubectl version --short
                    kubectl get ns | head
                    kubectl get deploy -n prod devsecops -o wide || true
                    kubectl get pods -n prod -l app=devsecops || true

                    echo "== ensure InSpec exists =="
                    if ! command -v inspec >/dev/null 2>&1; then
                        curl -sSL https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
                    fi
                    inspec version

                    echo "== run InSpec profile =="
                    test -d k8s-deploy-audit || { echo "Missing k8s-deploy-audit/ in workspace"; exit 2; }
                    cd k8s-deploy-audit

                    # first run
                    set +e
                    inspec exec . -t local:// \
                        --input ns=prod deploy_name=devsecops label_key=app label_val=devsecops \
                        --input ignore_containers='["istio-proxy"]' \
                        --reporter cli json:inspec.json junit:inspec-junit.xml
                    rc=$?
                    set -e
                    echo "InSpec exit code: $rc"

                    # if it failed, re-run with debug so the log shows why
                    if [ $rc -ne 0 ]; then
                        inspec exec . -t local:// \
                        --input ns=prod deploy_name=devsecops label_key=app label_val=devsecops \
                        --input ignore_containers='["istio-proxy"]' \
                        -l debug --reporter cli || true
                        exit $rc
                    fi
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