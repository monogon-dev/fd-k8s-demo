#!/usr/bin/env bash
set -euo pipefail

IMAGE=${IMAGE:-"europe-west3-docker.pkg.dev/monogon-infra/fd-dev/fd-k8s-demo:latest"}
NS=${NS:-"fd-dev-${USER}"}

NUM_NODES=100

# Build and push image
docker build -t $IMAGE .
docker push $IMAGE

kubectl config set-context --current --namespace=$NS

# Env cleanup
! kubectl create ns $NS
! kubectl delete pod leader-0
! kubectl delete replicaset follower

# Deploy leader
kubectl apply -f leader.yaml
kubectl apply -f follower.yaml
