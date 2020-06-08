#!/usr/bin/env bash
set -x
set -e

export PROJECT_NAME=confluence-backup
export AWS_DEFAULT_REGION=us-east-1
export DOCKER_REPO=$(aws ecr describe-repositories --query "repositories[?repositoryName==\`$PROJECT_NAME\`].[repositoryUri][0][0]" --output text)

aws ecr get-login-password | docker login --username AWS --password-stdin $DOCKER_REPO
docker build -t $PROJECT_NAME .
docker tag $PROJECT_NAME:latest $DOCKER_REPO:latest
docker push $DOCKER_REPO:latest

docker logout $DOCKER_REPO
