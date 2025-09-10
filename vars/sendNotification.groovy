def call(String buildStatus = 'STARTED') {
    buildStatus = buildStatus ?: 'SUCCESS'
    
    def color
    if (buildStatus == 'SUCCESS') {
        color = '#00FF00'
    } else if (buildStatus == 'UNSTABLE') {
        color = '#FFFF00'
    } else {
        color = '#FF0000'
    }
    
    def msg = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
    
    slackSend(color: color, message: msg)
}
