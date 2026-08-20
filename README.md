In this project we are building complete CI/CD pipeline with EKS and AWS ECR.
First we create aws eks cluster, ecr repository, and then we execute pipeline.

Pipeline steps:
- increment version
- build artifact for java 21 maven app
- build and push docker image to AWS ECR
- deploy app to aws eks
- commit version update to git

Gitlab was originally used for this project so commiting new version still refers to gitlab


### Build artifact for testing
    mvn clean package


### Create EKS cluster
    aws configure list
    aws configure
    
    eksctl create cluster \
      --name j-cluster \
      --version 1.36 \
      --region ap-southeast-2 \
      --nodegroup-name j-nodes \
      --node-type t3.small \
      --nodes 3 \
      --nodes-min 1 \
      --nodes-max 3


### Create ECR as Docker repository
    aws ecr create-repository \
      --repository-name java-m-app \
      --region ap-southeast-2 \
      --image-scanning-configuration scanOnPush=true \
      --encryption-configuration encryptionType=AES256


### IAM user for Jenkins
Create an IAM user with access keys. Attach a policy that can push to ECR


### Jenkins server
Install on the Jenkins agent:
- JDK 21
- Docker, and add the `jenkins` user to the `docker` group
- AWS CLI
- kubectl
- gettext-base (`envsubst`)



### Image pull secret on EKS
    aws eks update-kubeconfig --name j-cluster --region ap-southeast-2
    
    kubectl create secret docker-registry aws-reg-key \
      --docker-server=319279230334.dkr.ecr.ap-southeast-2.amazonaws.com \
      --docker-username=AWS \
      --docker-password="$(aws ecr get-login-password --region ap-southeast-2)" \
      --docker-email=

This password expires after 12 hours.



### use portforward to acess the app


use git pull on local machine, since we commit new version all the time
