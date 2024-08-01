# fd-k8s-demo

This repository contains demonstration code for deploying a dev cluster running Firedancer's `main` branch on a Kubernetes cluster. It was tested on a Monogon OS cluster, but should also work with any other standards-compliant k8s clusters with privileged access to host namespaces.

## Requirements

- Access to a k8s cluster with `kubectl`.
- `cluster-admin` permissions or a namespace already configured to allow root-level access.
- A public Docker registry to push/pull images from.
- Docker (or podman's wrapper binary) to build the image on your machine.

## How it works

By default, Kubernetes runs workloads inside Linux namespaces for resource isolation. However, these are optional, and it's possible to deploy privileged workloads which share most host namespaces except for the mount namespace (i.e. the container image).

## How to use

Set up your environment:

```shell
# Firedancer Docker image to use (replace by an image you can push).
export IMAGE=europe-west3-docker.pkg.dev/monogon-infra/fd-dev/fd-k8s-demo:latest

# Your k8s namespace.
export NS=fd-dev-${USER}
kubectl create namespace $NS
kubectl config set-context --current --namespace=$NS

# Allow workloads in the NS to run with (most) host privileges.
kubectl label --overwrite ns $NS pod-security.kubernetes.io/enforce=privileged
```

Deploy a demo cluster:

    ./up.sh

List pods:

    kubectl get pods

Run monitor:

    kubectl exec -it leader-0 -c validator -- fdctl monitor --config /etc/leader.toml

Check gossip:

    kubectl exec -it leader-0 -c validator -- solana -ul gossip

Get a shell:

    kubectl exec -it leader-0 -c validator bash

Once you're done, simply delete the namespace to clean up all objects:

    kubectl delete namespace $NS

## Limitations

This demo is intended for ephemeral, short-lived test clusters.

It runs in privileged mode in network namespace, eliminating almost all the resource isolation containers would otherwise afford us. It's up to the operator to avoid conflicts between workloads.

There can only be one node per physical machine, limiting scalability. For testing gossip scalability and similar, we'd recommend using regular containers with normal sockets.

We directly create a `Pod` object for the leader, which is the same as if you directly deploy the workload to a machine using SSH. Nothing manages that pod - if the machine is hit by lightning, Kubernetes doesn't reschedule it elsewhere. If you want persistent, fault-tolerant nodes, you should use `ReplicaSet` objects or a higher-level controller, but then you'd also have to worry about managing the leader's state and to make sure all workloads tolerate being rescheduled (and probably rewrite `up.sh` in something that isn't a shell script).
