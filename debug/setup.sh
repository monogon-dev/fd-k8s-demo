#!/usr/bin/env bash
set -euo pipefail
# Shorthand script for the debugging steps outlined in README.md.

METROCTL=$(ls -t /tmp/metroctl-*/metroctl.sh | head -n 1)

metroctl () {
  $METROCTL $@
}

metroctl node add role KubernetesWorker $(metroctl node list | grep metropolis)

kubectl config use-context launch-cluster

NS=fd-dev-${USER}

! kubectl create ns $NS
kubectl config set-context --current --namespace=$NS
kubectl label --overwrite ns $NS pod-security.kubernetes.io/enforce=privileged

NODE=$(metroctl node describe | grep KubernetesWorker | head -n 1 | awk '{ print $1 }')

echo "Node: $NODE"
sed -i "s/nodeName: .*/nodeName: $NODE/" debug/debug.yaml

while ! kubectl get node $NODE; do
  sleep 1
done

while ! kubectl get serviceaccount default; do
  sleep 1
done

kubectl debug node/${NODE} --image=registry.fedoraproject.org/fedora-toolbox:40 -it --profile=sysadmin
