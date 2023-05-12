pipeline {
    agent { label 'slave'}

    stages {
        stage('packer_build') {
            steps {
                withCredentials([string(credentialsId: 'github_access_token', variable: 'ACCESS_TOKEN')]) {
                    sh '''
                    /bin/bash ./env/scripts/jenkins_stage/packer_build.sh
                    '''
                }
            }
        }
    }

    // for EC2 slave
    post {
        // Clean after build
        always {
            cleanWs(
                cleanWhenNotBuilt: true,
                deleteDirs: true,
                disableDeferredWipeout: true,
                notFailBuild: true,
                // patterns: [[pattern: '.gitignore', type: 'INCLUDE'],
                //            [pattern: '.propsfile', type: 'EXCLUDE']]
            )
        }
    }
    
}