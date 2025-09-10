pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'localhost:5000'  // Adjust as needed
        DOCKER_IMAGE = 'kubernetes-devops-security'
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk'
        PATH = "${JAVA_HOME}/bin:${PATH}"
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
                        sh 'mvn clean compile'
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
                        // Try with cache first, fallback to no-update mode
                        def exitCode = sh(
                            script: '''
                                mvn org.owasp:dependency-check-maven:12.1.0:check || \
                                mvn org.owasp:dependency-check-maven:12.1.0:check -DautoUpdate=false
                            ''',
                            returnStatus: true
                        )
                        
                        if (exitCode != 0) {
                            echo "⚠️ Dependency check failed, but continuing pipeline..."
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
                }
            }
            post {
                always {
                    script {
                        if (fileExists('target/dependency-check-report.html')) {
                            publishHTML([
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'target',
                                reportFiles: 'dependency-check-report.html',
                                reportName: 'OWASP Dependency Check Report'
                            ])
                        } else {
                            echo "⚠️ No dependency check report generated"
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
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    if (fileExists('Dockerfile')) {
                        def dockerImage = docker.build("${DOCKER_IMAGE}:${BUILD_NUMBER}")
                        env.DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
                    }
                }
            }
        }
        
        stage('Container Security Scan') {
            when {
                expression { fileExists('Dockerfile') }
            }
            steps {
                script {
                    sh "trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    sh "grype ${DOCKER_IMAGE}:${BUILD_NUMBER} --fail-on high"
                }
            }
        }
        
        stage('Kubernetes Security Scan') {
            when {
                expression { fileExists('k8s') || fileExists('kubernetes') }
            }
            steps {
                script {
                    sh '''
                        find . -name "*.yaml" -o -name "*.yml" | grep -E "(k8s|kubernetes)" | while read manifest; do
                            echo "Scanning $manifest with kube-score..."
                            kube-score score "$manifest" || true
                            
                            echo "Scanning $manifest with kubesec..."
                            kubesec scan "$manifest" || true
                        done
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
