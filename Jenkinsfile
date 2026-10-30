pipeline {
    agent any
    options { timestamps(); disableConcurrentBuilds(); buildDiscarder(logRotator(numToKeepStr: '12')) }
    parameters { choice(name: 'VERSION', choices: ['v1', 'v2', 'v3'], description: 'Release tag to build, publish and deploy') }
    environment {
        DOCKER_USER = 'vaibhav11464'
        IMAGE_NAME = 'agile-social-app'
        DOCKER_HOST = 'npipe:////./pipe/dockerDesktopLinuxEngine'
        PATH = "C:\\Program Files\\nodejs;D:\\Git\\cmd;C:\\Users\\vaibh\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin;${env.PATH}"
    }
    stages {
        stage('Checkout release') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: "refs/tags/${params.VERSION}"]], userRemoteConfigs: [[url: 'https://github.com/VAIBHAV11464/AGILE-SOCIAL_APP.git']], extensions: [[$class: 'CloneOption', noTags: false, shallow: false]]])
                powershell 'git log -1 --oneline; Get-Content release.json; if ((Get-Content release.json | ConvertFrom-Json).version -ne $env:VERSION) { throw "Release tag and application version differ" }'
            }
        }
        stage('Test application') {
            steps { bat 'call npm.cmd ci --ignore-scripts && call npm.cmd run check && call npm.cmd test' }
        }
        stage('Build Docker image') {
            steps {
                bat 'docker build --label org.opencontainers.image.revision=%GIT_COMMIT% -t %DOCKER_USER%/%IMAGE_NAME%:%VERSION% .'
                bat 'docker run --rm %DOCKER_USER%/%IMAGE_NAME%:%VERSION% npm test'
            }
        }
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'social-dockerhub', usernameVariable: 'HUB_USER', passwordVariable: 'HUB_TOKEN')]) {
                    powershell '''
                        $ErrorActionPreference = 'Stop'
                        $env:DOCKER_CONFIG = Join-Path $env:WORKSPACE '.pipeline-docker'
                        New-Item -ItemType Directory -Force $env:DOCKER_CONFIG | Out-Null
                        try {
                            $env:HUB_TOKEN | docker login --username $env:HUB_USER --password-stdin
                            if ($LASTEXITCODE -ne 0) { throw 'Docker Hub login failed' }
                            docker push "$($env:DOCKER_USER)/$($env:IMAGE_NAME):$($env:VERSION)"
                            if ($LASTEXITCODE -ne 0) { throw 'Docker push failed' }
                        } finally {
                            if (Test-Path -LiteralPath $env:DOCKER_CONFIG) { Remove-Item -LiteralPath $env:DOCKER_CONFIG -Recurse -Force }
                        }
                    '''
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'social-kubeconfig', variable: 'KUBECONFIG')]) {
                    powershell './scripts/deploy.ps1 -Version $env:VERSION -Image "$($env:DOCKER_USER)/$($env:IMAGE_NAME):$($env:VERSION)" -BuildId $env:BUILD_NUMBER'
                }
            }
        }
        stage('Verify deployed application') {
            steps {
                withCredentials([file(credentialsId: 'social-kubeconfig', variable: 'KUBECONFIG')]) {
                    powershell './scripts/verify.ps1 -Version $env:VERSION'
                }
            }
        }
    }
    post { success { echo "Release ${params.VERSION} was tested, published to Docker Hub and deployed successfully." } }
}
