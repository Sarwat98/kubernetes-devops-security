pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'localhost:5000'  // Adjust as needed
        DOCKER_IMAGE = 'kubernetes-devops-security'
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk'
        PATH = "${JAVA_HOME}/bin:${PATH}"
        NVD_API_KEY = credentials('nvd-api-key')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.BUILD_NUMBER = "${BUILD_NUMBER}"
                    env.GIT_COMMIT = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
                }
            }
        }
        
        stage('Build Application') {
            steps {
                script {
                    if (fileExists('pom.xml')) {
                        sh '''
                            echo "Building Maven project..."
                            mvn clean package -DskipTests
                            
                            # Verify JAR was created
                            ls -la target/
                            ls -la target/*.jar
                        '''
                    } else if (fileExists('package.json')) {
                        sh 'npm install'
                        sh 'npm run build'
                    }
                }
            }
        }
        
        
        stage('Unit Tests') {
            steps {
                script {
                    if (fileExists('pom.xml')) {
                        sh 'mvn test'
                    } else if (fileExists('package.json')) {
                        sh 'npm test'
                    }
                }
            }
            post {
                always {
                    script {
                        if (fileExists('target/surefire-reports/*.xml')) {
                            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                        }
                    }
                }
            }
        }
        stage('OWASP Dependency Check') {
            steps {
                script {
                    if (fileExists('pom.xml')) {
                        sh '''
                            mvn org.owasp:dependency-check-maven:12.1.0:check \
                                -Dnvd.api.key=${NVD_API_KEY} \
                                -Dnvd.api.delay=6000
                        '''
                    }
                }
            }
            post {
                always {
                    script {
                        if (fileExists('target/dependency-check-report.html')) {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'target',
                                reportFiles: 'dependency-check-report.html',
                                reportName: 'OWASP Dependency Check Report'
                            ])
                        }
                    }
                }
            }
        }



        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    script {
                        if (fileExists('pom.xml')) {
                            sh '''
                                mvn sonar:sonar \
                                    -Dsonar.projectKey=kubernetes-devops-security \
                                    -Dsonar.projectName="Kubernetes DevOps Security"
                            '''
                        } else {
                            sh '''
                                sonar-scanner \
                                    -Dsonar.projectKey=kubernetes-devops-security \
                                    -Dsonar.projectName="Kubernetes DevOps Security" \
                                    -Dsonar.sources=.
                            '''
                        }
                    }
                }
            }
        }

        
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    if (fileExists('Dockerfile')) {
                        // Verify JAR exists before building
                        if (fileExists('pom.xml')) {
                            sh 'ls -la target/*.jar'
                        }
                        
                        def dockerImage = docker.build("${DOCKER_IMAGE}:${BUILD_NUMBER}")
                        env.DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
                    }
                }
            }
        }
        
        stage('Container Security Scan') {
            parallel {
                stage('Trivy Scan') {
                    steps {
                        script {
                            def exitCode = sh(
                                script: 'trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${BUILD_NUMBER}',
                                returnStatus: true
                            )
                            
                            if (exitCode != 0) {
                                echo "⚠️ High/Critical vulnerabilities found in container"
                                currentBuild.result = 'UNSTABLE'
                            }
                        }
                    }
                }
                
                stage('Grype Scan') {
                    steps {
                        script {
                            def exitCode = sh(
                                script: 'grype ${DOCKER_IMAGE}:${BUILD_NUMBER} --fail-on critical',
                                returnStatus: true
                            )
                            
                            if (exitCode != 0) {
                                echo "🔥 CRITICAL vulnerabilities found - requires immediate attention"
                                echo "📊 Review full report for remediation steps"
                                currentBuild.result = 'UNSTABLE'
                                
                                // Generate detailed report
                                sh 'grype ${DOCKER_IMAGE}:${BUILD_NUMBER} -o json > grype-report.json'
                                sh 'grype ${DOCKER_IMAGE}:${BUILD_NUMBER} -o table > grype-report.txt'
                                
                                archiveArtifacts artifacts: 'grype-report.*', fingerprint: true
                            }
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        // Send security alert for critical findings
                        if (currentBuild.result == 'UNSTABLE') {
                            echo """
                            🚨 SECURITY ALERT 🚨
                            Critical vulnerabilities detected in build ${env.BUILD_NUMBER}
                            
                            Priority Actions Required:
                            1. Update Spring Boot to 2.7.18+
                            2. Update Spring Security to 5.8.13+  
                            3. Update Tomcat to 9.0.99+
                            4. Review complete vulnerability report
                            
                            Build marked as UNSTABLE - manual review required before deployment.
                            """
                        }
                    }
                }
            }
        }
        
        stage('Kubernetes Security Scan') {
            steps {
                script {
                    sh '''
                        echo "Looking for Kubernetes manifests..."
                        
                        # Search for any Kubernetes-related files
                        K8S_FILES=$(find . -name "*.yaml" -o -name "*.yml" | xargs grep -l "apiVersion\|kind:" 2>/dev/null || echo "")
                        
                        if [ -n "$K8S_FILES" ]; then
                            echo "Found Kubernetes manifests:"
                            echo "$K8S_FILES"
                            
                            for manifest in $K8S_FILES; do
                                echo "Scanning: $manifest"
                                kube-score score "$manifest" || true
                                kubesec scan "$manifest" || true
                            done
                        else
                            echo "No Kubernetes manifests found in repository"
                            echo "Repository appears to be a Java application without K8s deployment files"
                        fi
                    '''
                }
            }
        }
        
        stage('OWASP ZAP Security Test') {
            when {
                expression { fileExists('Dockerfile') }
            }
            steps {
                script {
                    sh '''
                        # Start application container for testing
                        docker run -d --name test-app -p 8081:8080 ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        sleep 30
                        
                        # Run OWASP ZAP baseline scan
                        docker run --rm --network host \
                            -v $(pwd):/zap/wrk/:rw \
                            -t owasp/zap2docker-stable zap-baseline.py \
                            -t http://localhost:8081 \
                            -r zap_report.html || true
                        
                        # Stop test container
                        docker stop test-app || true
                        docker rm test-app || true
                    '''
                }
            }
            post {
                always {
                    script {
                        if (fileExists('zap_report.html')) {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: '.',
                                reportFiles: 'zap_report.html',
                                reportName: 'OWASP ZAP Security Report'
                            ])
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo "✅ DevSecOps Pipeline completed successfully!"
        }
        failure {
            echo "❌ DevSecOps Pipeline failed!"
        }
    }
}
