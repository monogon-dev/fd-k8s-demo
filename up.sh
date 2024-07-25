#!/usr/bin/env bash
set -euo pipefail

IMAGE=${IMAGE:-"europe-west3-docker.pkg.dev/monogon-infra/fd-dev/fd-k8s-demo:latest"}
NAMESPACE=${USER}-$(date +%s)

NUM_NODES=100

docker build -t $IMAGE .
docker push $IMAGE
