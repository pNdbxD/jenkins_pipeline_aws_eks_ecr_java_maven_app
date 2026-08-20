#!/usr/bin/env groovy

pipeline {
    agent any
    tools {
        maven 'maven3916'
    }
    environment {
        DOCKER_REPO_SERVER = '319279230334.dkr.ecr.ap-southeast-2.amazonaws.com'
        APP_NAME = 'java-m-app'
        DOCKER_REPO = "${DOCKER_REPO_SERVER}/${APP_NAME}"
    }
    stages {
        stage('increment version') {
            steps {
                script {
                    echo 'incrementing app version...'
                    sh 'mvn build-helper:parse-version versions:set \
                        -DnewVersion=\\\${parsedVersion.majorVersion}.\\\${parsedVersion.minorVersion}.\\\${parsedVersion.nextIncrementalVersion} \
                        versions:commit'
                    def matcher = readFile('pom.xml') =~ '<version>(.+)</version>'
                    def version = matcher[0][1]
                    env.IMAGE_NAME = "$version-$BUILD_NUMBER"
                }
            }
        }
        stage('build app') {
            steps {
                script {
                    echo 'building the application...'
                    sh 'mvn clean package'
                }
            }
        }
        stage('build image') {
            steps {
                script {
                    echo "building the docker image..."
                    withCredentials([usernamePassword(credentialsId: 'jenkins-ecr-creds', passwordVariable: 'PASS', usernameVariable: 'USER')]){

//                         image is built on jenkins server (linux) so no need to use docker buildx for multi-platform build
                        sh "docker build -t ${DOCKER_REPO}:${IMAGE_NAME} ."
                        echo "docker repo and image ${DOCKER_REPO}:${IMAGE_NAME}"
                        sh 'echo $PASS | docker login -u $USER --password-stdin ${DOCKER_REPO_SERVER}'
                        sh "docker push ${DOCKER_REPO}:${IMAGE_NAME}"
                    }
                    echo "Docker image built!"
                }
            }
        }
        stage('deploy') {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
                AWS_DEFAULT_REGION = 'ap-southeast-2'
            }
            steps {
                script {
                   echo 'deploying docker image...'
                   sh '''
                   aws eks update-kubeconfig \
                     --name j-cluster \
                     --region ap-southeast-2
                   '''
                   sh "envsubst < kubernetes/deployment.yaml | kubectl apply -f -"
                   sh "envsubst < kubernetes/service.yaml | kubectl apply -f -" // substitutes environment variables in the service.yaml file and applies it to the Kubernetes cluster
                }
            }
        }
        stage('commit version update'){
            steps {
                script {
                    sshagent(credentials: ['gitlab-jenkins-ssh-key']) {
                        sh 'git remote set-url origin git@gitlab.com:devops-bt/11_aws_deploy-to-eks-cluster-from-jenkins.git'
                        sh 'git config user.name "Jenkins"'
                        sh 'git config user.email "jenkins@example.com"'

                        sh 'git add .'
                        sh "git commit -m 'Bump version to ${env.IMAGE_NAME ?: version}'"

                        sh 'git push origin HEAD:main'
                    }
                }
            }
        }
    }
}
