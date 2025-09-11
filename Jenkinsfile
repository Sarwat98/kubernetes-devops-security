pipeline {
    agent any
    environment {
        SONARQUBE_ENV = 'SonarQube' // Optional: for clarity
        deploymentName = "devsecops"
        containerName  = "devsecops-container"
        serviceName    = "devsecops-svc"
        imageName      = "sawat98/numeric-service:${GIT_COMMIT}"
        applicationURL = "http://35.228.57.176"
        applicationURI = "compare/99"
        CHEF_LICENSE = 'accept-silent'      // harmless even though we use -t local://
    }
    
    stages {
        stage('Build Artifact') {
            steps {
                sh "mvn clean package -DskipTests=true"
                archiveArtifacts 'target/*.jar' //so that they can be downloaded later
            }
        }  
        
        stage('Unit Tests -- JUnit and Jacoco') {
            steps {
                sh "mvn test"
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
                    script {
                        try {
                            waitForQualityGate abortPipeline: true
                        } catch (Exception e) {
                            echo "⚠️ Quality Gate failed or timed out: ${e.message}"
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
                }
            }
        }
                
        stage('Mutation Testing - PIT') {
            steps {
                script {
                    try {
                        sh "mvn org.pitest:pitest-maven:mutationCoverage"
                    } catch (Exception e) {
                        echo "⚠️ PIT Mutation testing failed: ${e.message}"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }
        
        stage('Vulnerability Scan - Dependency  - Docker') {
            steps {
                parallel (
                    'Dependency Check': {
                        script {
                            try {
                                sh 'mvn org.owasp:dependency-check-maven:12.1.0:check -DautoUpdate=false'
                            } catch (Exception e) {
                                echo "⚠️ Dependency check found vulnerabilities"
                                currentBuild.result = 'UNSTABLE'
                            }
                        }
                    },
                    'Trivy Scan': {
                        script {
                            try {
                                sh "bash trivy-docker-image-scan.sh"
                            } catch (Exception e) {
                                echo "⚠️ Trivy scan found vulnerabilities"
                                currentBuild.result = 'UNSTABLE'
                            }
                        }
                    },
                )
            }
        }
        stage('OPA Conftest K8s') {
            steps {
                script {
                    try {
                        sh '''
                            echo "=== Running OPA Conftest Kubernetes Security Tests ==="
                            
                            # Create corrected Kubernetes security policy
                            cat > opa-k8s-security.rego << 'EOF'
        package kubernetes.security
        
        import rego.v1
        
        # Deny if Deployment is missing resource limits
        violation contains msg if {
            input.kind == "Deployment"
            container := input.spec.template.spec.containers[_]
            not container.resources.limits
            msg := sprintf("Container '%v' is missing resource limits", [container.name])
        }
        
        # Deny if container runs as root
        violation contains msg if {
            input.kind == "Deployment"
            container := input.spec.template.spec.containers[_]
            container.securityContext.runAsUser == 0
            msg := sprintf("Container '%v' should not run as root (UID 0)", [container.name])
        }
        
        # Deny if readOnlyRootFilesystem is not set to true
        violation contains msg if {
            input.kind == "Deployment" 
            container := input.spec.template.spec.containers[_]
            container.securityContext.readOnlyRootFilesystem != true
            msg := sprintf("Container '%v' should have readOnlyRootFilesystem set to true", [container.name])
        }
        
        # Warn if no security context is defined
        warn contains msg if {
            input.kind == "Deployment"
            container := input.spec.template.spec.containers[_]
            not container.securityContext
            msg := sprintf("Container '%v' should define a securityContext", [container.name])
        }
        
        # Deny if privileged containers are used
        violation contains msg if {
            input.kind == "Deployment"
            container := input.spec.template.spec.containers[_]
            container.securityContext.privileged == true
            msg := sprintf("Container '%v' should not run in privileged mode", [container.name])
        }
        
        # Deny if allowPrivilegeEscalation is not set to false
        violation contains msg if {
            input.kind == "Deployment"
            container := input.spec.template.spec.containers[_]
            container.securityContext.allowPrivilegeEscalation != false
            msg := sprintf("Container '%v' should set allowPrivilegeEscalation to false", [container.name])
        }
        
        # Warn if no resource requests are defined
        warn contains msg if {
            input.kind == "Deployment"
            container := input.spec.template.spec.containers[_]
            not container.resources.requests
            msg := sprintf("Container '%v' should define resource requests", [container.name])
        }
        
        # Deny if capabilities are not dropped
        violation contains msg if {
            input.kind == "Deployment"
            container := input.spec.template.spec.containers[_]
            not container.securityContext.capabilities.drop
            msg := sprintf("Container '%v' should drop capabilities", [container.name])
        }
        EOF
                            
                            echo "✅ Kubernetes policy created with correct syntax"
                            
                            # Validate Rego syntax
                            docker run --rm -v $(pwd):/project openpolicyagent/opa fmt /project/opa-k8s-security.rego
                            
                            # Run conftest against Kubernetes manifests
                            docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml
                            
                            echo "✅ OPA Kubernetes security validation passed"
                        '''
                    } catch (Exception e) {
                        echo "⚠️ OPA Kubernetes security check failed: ${e.message}"
                        
                        sh '''
                            echo "=== Kubernetes Security Violations Found ==="
                            docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml || true
                        '''
                        
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }
        stage('Build Docker and Push Image') {
            steps {
                withDockerRegistry([credentialsId: 'docker-registry-credentials', url: '']) {
                    sh 'printenv' // to see if the environment variables are set correctly
                    sh "docker build -t sawat98/numeric-service:${GIT_COMMIT} ."
                    sh "docker push sawat98/numeric-service:${GIT_COMMIT}"
                }
            }
        }
        
        stage('Vulnerability Scan - Kubernetes') {
            steps {
                parallel (
                    'OPA Conftest Scan': {
                        script {
                            try {
                                sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
                            } catch (Exception e) {
                                echo "⚠️ OPA Kubernetes scan found policy violations"
                                currentBuild.result = 'UNSTABLE'
                            }
                        }
                    },
                    'Kubesec Scan': {
                        script {
                            try {
                                sh "bash kubesec-scan.sh"
                            } catch (Exception e) {
                                echo "⚠️ Kubesec scan found security issues"
                                currentBuild.result = 'UNSTABLE'
                            }
                        }
                    },
                    'Trivy Scan': {
                        script {
                            try {
                                sh "bash trivy-k8s-scan.sh"
                            } catch (Exception e) {
                                echo "⚠️ Trivy Kubernetes scan found vulnerabilities"
                                currentBuild.result = 'UNSTABLE'
                            }
                        }
                    }
                )
            }
        }
        
        stage('Deploy to Kubernetes - DEV') {
            steps {
                withKubeConfig([credentialsId: 'kubeconfig']) {
                    script {
                        sh "sed -i 's|image:.*|image: sawat98/numeric-service:${GIT_COMMIT}|' k8s_deployment_service.yaml"
                        sh "kubectl apply -f k8s_deployment_service.yaml"
                    }
                }
            }
        }
        
        stage('InSpec') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    withEnv(['JAVA_TOOL_OPTIONS=', '_JAVA_OPTIONS=', 'MAVEN_OPTS=', 'JACOCO_AGENT=']) {
                        script {
                            try {
                                sh "bash inspec-scan.sh"
                            } catch (Exception e) {
                                echo "⚠️ InSpec scan found compliance issues"
                                currentBuild.result = 'UNSTABLE'
                            }
                        }
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
        
        stage('Integration Tests - DEV') {
            steps {
                script {
                    try {
                        withKubeConfig([credentialsId: 'kubeconfig']) {
                            sh 'bash integration-test.sh'
                        }
                    } catch (e) {
                        withKubeConfig([credentialsId: 'kubeconfig']) {
                            sh "kubectl -n default rollout undo deploy ${deploymentName}"
                        }
                        throw e
                    }
                }
            }
        }
        
        stage('OWASP ZAP Scan - DAST') {
            steps {
                withKubeConfig([credentialsId: 'kubeconfig']) {
                    script {
                        try {
                            sh "bash owasp-zap-scan.sh"
                        } catch (Exception e) {
                            echo "⚠️ OWASP ZAP scan found security vulnerabilities"
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
                }
            }
        }
        
        stage('Qualys WAS Scan') {
            steps {
                script {
                    try {
                        echo "=== Starting Qualys WAS Vulnerability Scan ==="
                        
                        qualysWASScan(
                            authRecord: 'none',
                            cancelOptions: 'none',
                            credsId: 'qualys-pass',
                            isSev1Vulns: true,
                            isSev2Vulns: true,
                            isSev3Vulns: true,
                            optionProfile: 'useDefault',
                            platform: 'EU_PLATFORM_2',
                            pollingInterval: '5',
                            scanName: "${env.JOB_NAME}_jenkins_build_${env.BUILD_NUMBER}",
                            scanType: 'VULNERABILITY',
                            severity1Limit: 5,
                            severity2Limit: 5,
                            severity3Limit: 5,
                            vulnsTimeout: '60*24',
                            webAppId: '346161461'
                        )
                        
                        echo "✅ Qualys WAS scan completed successfully"
                    } catch (Exception e) {
                        echo "⚠️ Qualys WAS scan failed or detected vulnerabilities: ${e.message}"
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }
        
        stage('Testing Slack Notifications') {
            steps {
                sh 'echo "Testing Slack Notifications"'
                sh 'exit 0' // Simulate a successful step
            }
        }
        
        stage('K8S CIS Benchmark Scan') {
            steps {
                script {
                    parallel (
                        'Master': {
                            try {
                                sh "bash cis-master.sh"
                            } catch (Exception e) {
                                echo "⚠️ CIS Master benchmark scan found issues"
                                currentBuild.result = 'UNSTABLE'
                            }
                        },
                        'Etcd': {
                            try {
                                sh "bash cis-etcd.sh"
                            } catch (Exception e) {
                                echo "⚠️ CIS Etcd benchmark scan found issues"
                                currentBuild.result = 'UNSTABLE'
                            }
                        },
                        'Kubelet': {
                            try {
                                sh "bash cis-kubelet.sh"
                            } catch (Exception e) {
                                echo "⚠️ CIS Kubelet benchmark scan found issues"
                                currentBuild.result = 'UNSTABLE'
                            }
                        }
                    )
                }
            }
        }
        
        stage('Promote to PROD') {
            steps {
                timeout(time: 2, unit: 'DAYS') {
                    input message: 'Do you want to promote the build to PROD?', ok: 'Yes, Promote'
                }
            }
        }
        
        stage('K8S Deployment -- PROD') {
            steps {
                parallel(
                    "Deployment": {
                        withKubeConfig([credentialsId: 'kubeconfig']) {
                            sh "sed -i 's#replace#${imageName}#g' k8s_PROD-deployment_service.yaml"
                            sh "kubectl -n prod apply -f k8s_PROD-deployment_service.yaml"
                        }
                    },
                    "Rollout Status": {
                        withKubeConfig([credentialsId: 'kubeconfig']) {
                            sh "bash k8s-PROD-deployment-rollout-status.sh"
                        }
                    }
                )
            }
        }
    }
    
    post { 
        always {
            script {
                // Publish test results and reports
                try {
                    junit 'target/surefire-reports/*.xml'
                } catch (Exception e) {
                    echo "⚠️ JUnit report publishing failed: ${e.message}"
                }
                
                try {
                    jacoco execPattern: 'target/jacoco.exec'
                } catch (Exception e) {
                    echo "⚠️ JaCoCo report publishing failed: ${e.message}"
                }
                
                try {
                    pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
                } catch (Exception e) {
                    echo "⚠️ PIT mutation report publishing failed: ${e.message}"
                }
                
                try {
                    dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
                } catch (Exception e) {
                    echo "⚠️ Dependency check report publishing failed: ${e.message}"
                }
                
                try {
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report', useWrapperFileDirectly: true])
                } catch (Exception e) {
                    echo "⚠️ OWASP ZAP report publishing failed: ${e.message}"
                }
                
                // Send Slack notification
                sendSlackNotification(currentBuild.result ?: 'SUCCESS')
            }
        } 
        
        success {
            echo '✅ Pipeline completed successfully!'
        }
        
        failure {
            echo '❌ Pipeline failed!'
        }
        
        unstable {
            echo '⚠️ Pipeline completed but with security findings that require review'
        }
    }
}

// Custom function to replace the shared library
def sendSlackNotification(String buildStatus) {
    buildStatus = buildStatus ?: 'SUCCESS'
    
    def color
    def emoji
    if (buildStatus == 'SUCCESS') {
        color = 'good'
        emoji = '✅'
    } else if (buildStatus == 'UNSTABLE') {
        color = 'warning' 
        emoji = '⚠️'
    } else {
        color = 'danger'
        emoji = '❌'
    }
    
    def msg = """
${emoji} *DevSecOps Pipeline ${buildStatus}*
*Job:* ${env.JOB_NAME}
*Build:* #${env.BUILD_NUMBER}
*Duration:* ${currentBuild.durationString}
*URL:* ${env.BUILD_URL}
    """.stripIndent()
    
    try {
        slackSend(color: color, message: msg)
        echo "📱 Slack notification sent successfully"
    } catch (Exception e) {
        echo "⚠️ Slack notification failed: ${e.message}"
        echo "💡 Make sure Slack Notification plugin is installed and configured"
    }
}
