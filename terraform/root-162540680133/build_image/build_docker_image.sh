#!/usr/bin/env bash
set -x
set -e

export AWS_DEFAULT_REGION=us-east-1
export DOCKER_REPO=$(aws ecr describe-repositories --query 'repositories[?repositoryName==`repo-backup`].[repositoryUri][0][0]' --output text)

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $DOCKER_REPO
docker build -t repo-backup .
docker tag repo-backup:latest $DOCKER_REPO:latest
docker push $DOCKER_REPO:latest

docker logout $DOCKER_REPO