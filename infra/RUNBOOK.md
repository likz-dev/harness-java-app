# Runbook: Deploy Harness Delegate with Terraform

Operational steps to bring up a local Minikube cluster and install the Harness NG delegate via Terraform.

## 1. Prerequisites checklist

| Check | How |
|-------|-----|
| Docker running | `docker info` |
| Minikube installed | `minikube version` |
| kubectl installed | `kubectl version --client` |
| Terraform installed | `terraform version` |
| Harness credentials | Account ID + delegate token from Harness UI |

Get a token: Harness → **Account Settings** → **Delegates** → **New Delegate** → Kubernetes → copy account ID and token (and preferred image tag if shown).

## 2. Start the local cluster

From the **repo root**:

```bash
./scripts/minikube-demo.sh start
```

Defaults: profile `demo`, `--cpus 4`, `--memory 4g`, Docker driver. Addons: ingress, metrics-server, dashboard.

Confirm:

```bash
./scripts/minikube-demo.sh status
kubectl config current-context   # expect: demo
kubectl get nodes
```

If kubectl is not on the `demo` context:

```bash
kubectl config use-context demo
# or
minikube update-context -p demo
```

## 3. Configure Terraform variables

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your real account ID, delegate token, image tag, and names. Do **not** commit this file.

## 4. Init, plan, apply

```bash
cd infra

terraform init
terraform plan
terraform apply
```

Approve the apply when prompted (`yes`), or use `terraform apply -auto-approve` for demos only.

What apply does:

1. Pulls the `harness/harness-delegate/kubernetes` module
2. Creates/uses namespace `harness_namespace` (via Helm `create_namespace`)
3. Installs chart `harness-delegate-ng` with your values

## 5. Verify the delegate

On the cluster:

```bash
kubectl get ns harness-delegate-ng
kubectl get pods -n harness-delegate-ng
kubectl get deploy -n harness-delegate-ng
kubectl logs -n harness-delegate-ng -l app.kubernetes.io/name=harness-delegate-ng --tail=100
```

Expect pods in `Running` / `Ready`. In Harness UI → **Delegates**, the named delegate should show as connected within a few minutes.

Useful status commands:

```bash
terraform show
helm list -n harness-delegate-ng
```

## 6. Day-2 operations

### Change replicas, image, or values

Update `terraform.tfvars` (or variables), then:

```bash
cd infra
terraform plan
terraform apply
```

### Re-run after Minikube restart

```bash
./scripts/minikube-demo.sh start
cd infra
terraform apply   # reconcile if the release drifted or namespace was wiped
```

If you wiped the cluster (`minikube-demo.sh reset` / `delete`), state may still think the release exists. Prefer destroy then apply (below), or `terraform apply -replace=module.delegate.helm_release.delegate` only if you know what you are doing.

### View Helm values Terraform computed

```bash
cd infra
terraform output   # if outputs are defined
# otherwise inspect state / module:
terraform state show 'module.delegate.helm_release.delegate'
```

## 7. Tear down

### Remove the delegate only (keep cluster)

```bash
cd infra
terraform destroy
```

### Stop Minikube (keep cluster disk)

```bash
./scripts/minikube-demo.sh stop
```

### Delete Minikube profile entirely

```bash
./scripts/minikube-demo.sh delete
```

If you delete the cluster without `terraform destroy`, remove stale state afterward:

```bash
cd infra
rm -f terraform.tfstate terraform.tfstate.backup
# or: terraform destroy  (will error if API is gone — then remove state files)
```

## 8. Troubleshooting

| Symptom | Likely cause | Action |
|---------|--------------|--------|
| `Docker is not running` | Daemon/Desktop down | Start Docker, retry `minikube-demo.sh start` |
| Helm/Terraform can't talk to API | Wrong kube context | `kubectl config use-context demo` |
| Pods `ImagePullBackOff` | Bad image tag / network | Fix `harness_delegate_image`, re-apply |
| Pods crash / not connecting | Bad token, account ID, or endpoint | Check `terraform.tfvars`; inspect pod logs |
| Delegate never appears in UI | Outbound network blocked from Minikube | Ensure cluster can reach `harness_manager_endpoint` |
| `terraform apply` wants to recreate | Cluster was reset under Terraform | `terraform destroy` then `apply`, or reset local state if API is gone |
| Insufficient CPU/memory | Minikube undersized | Defaults are 4 CPU / 4g; raise via `CPUS` / `MEMORY` env on the script |

Debug pods:

```bash
kubectl describe pod -n harness-delegate-ng -l app.kubernetes.io/name=harness-delegate-ng
kubectl logs -n harness-delegate-ng -l app.kubernetes.io/name=harness-delegate-ng --previous
```

## 9. Optional: cluster-admin for the delegate SA

If Harness pipelines need cluster-wide privileges, bind `cluster-admin` to the namespace default ServiceAccount (demo only — very privileged):

```hcl
provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_cluster_role_binding_v1" "harness_delegate_cluster_admin" {
  metadata {
    name = "harness-delegate-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = var.harness_namespace
  }

  depends_on = [module.delegate]
}
```

Then `terraform init` (to install the Kubernetes provider) and `terraform apply`.

## 10. Contact / ownership

- Terraform root: `infra/`
- Cluster helper: `scripts/minikube-demo.sh`
- Module docs: https://registry.terraform.io/modules/harness/harness-delegate/kubernetes/latest
