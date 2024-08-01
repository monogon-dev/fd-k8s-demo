## Debugging

You can deploy a Monogon OS cluster locally for easy development, which is particularly handy if you want to experiment with different OS and kernel settings. Inside the monorepo, run this command to spin up a local cluster, which is very close to the real deployment and uses the same kernel build.

Apply patch to monorepo to accommodate criminally large Agave build artifacts and increase node resources:

```diff
diff --git a/metropolis/node/build/mkimage/main.go b/metropolis/node/build/mkimage/main.go
index 36950544..f73cc530 100644
--- a/metropolis/node/build/mkimage/main.go
+++ b/metropolis/node/build/mkimage/main.go
@@ -95 +95 @@ func main() {
-	cfg.Output, err = blockdev.CreateFile(outputPath, 512, 10*1024*1024)
+	cfg.Output, err = blockdev.CreateFile(outputPath, 512, 100*1024*1024)
diff --git a/metropolis/node/core/curator/state_cluster.go b/metropolis/node/core/curator/state_cluster.go
index 6cb0a3ad..e5951cc5 100644
--- a/metropolis/node/core/curator/state_cluster.go
+++ b/metropolis/node/core/curator/state_cluster.go
@@ -33 +33 @@ func DefaultClusterConfiguration() *Cluster {
-		StorageSecurityPolicy: cpb.ClusterConfiguration_STORAGE_SECURITY_POLICY_NEEDS_ENCRYPTION_AND_AUTHENTICATION,
+		StorageSecurityPolicy: cpb.ClusterConfiguration_STORAGE_SECURITY_POLICY_NEEDS_INSECURE,
diff --git a/metropolis/test/launch/cluster.go b/metropolis/test/launch/cluster.go
index 7ae5f835..91f75cad 100644
--- a/metropolis/test/launch/cluster.go
+++ b/metropolis/test/launch/cluster.go
@@ -280,2 +280,2 @@ func LaunchNode(ctx context.Context, ld, sd string, tpmFactory *TPMFactory, opti
-		"-machine", "q35", "-accel", "kvm", "-nographic", "-nodefaults", "-m", "2048",
-		"-cpu", "host", "-smp", "sockets=1,cpus=1,cores=2,threads=2,maxcpus=4",
+		"-machine", "q35", "-accel", "kvm", "-nographic", "-nodefaults", "-m", "128000",
+		"-cpu", "host", "-smp", "sockets=1,cpus=64,cores=32,threads=2,maxcpus=64",
```

Launch the dev cluster:

    bazel run --config dbg //metropolis:launch-cluster

Note that you get a clean state every time you run `launch-cluster`, which guarantees a clean testing environment.

Use the auto-generated wrapper to apply worker roles to all nodes:

    alias metroctl=/tmp/metroctl-[...]/metroctl.sh
    metroctl node add role KubernetesWorker $(metroctl node list | grep metropolis)

Switch your local kubectl config:

    kubectl config use-context launch-cluster

You should now see two worker nodes and the control plane:

    metroctl node describe
    kubectl get node

Set up namespace (see above):

    export NS=fd-dev-${USER}
    kubectl create ns $NS
    kubectl config set-context --current --namespace=$NS
    kubectl label --overwrite ns $NS pod-security.kubernetes.io/enforce=privileged

Deploy a Fedora host debugging pod with full privileges:

    kubectl debug node/metropolis-[...] --image=registry.fedoraproject.org/fedora-toolbox:40 -it --profile=sysadmin

Deploy FD debug pod after updating `nodeName` in `debug.yaml`:

    kubectl apply -f debug/debug.yaml

Show pod status:

    kubectl describe pod node-debugger-0

It'll spend some time fetching the image, then you can enter the interactive shell and run arbitrary commands inside the same environment that would run on the cluster.

Attach to console:

    kubectl attach pods/node-debugger-0 -i -t

Show nodes by region to pick a close one:

    kubectl get node -o wide -L topology.kubernetes.io/region

Reboot host from privileged node debug container:

    echo b |sudo tee /proc/sysrq-trigger
