# Runbook: Deploy Harness Delegate & GitOps with Terraform

Operational steps to bring up a local Minikube cluster and install the Harness NG delegate and GitOps agent via Terraform.

## 1. Prerequisites checklist

| Check | How |
|-------|-----|
| Docker running | `docker info` |
| Minikube installed | `minikube version` |
| kubectl installed | `kubectl version --client` |
| Terraform installed | `terraform version` |
| Harness credentials | Account ID, delegate token, GitOps agent secret + Redis password |

Get a delegate token: Harness → **Account Settings** → **Delegates** → **New Delegate** → Kubernetes → copy account ID and token (and preferred image tag if shown).

Get GitOps secrets: Harness → **GitOps** → create/install agent → copy agent secret (and Redis password from the generated overrides if provided).

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

Edit `terraform.tfvars` with:

- Delegate: account ID, token, image, name, namespace
- GitOps: `gitops_agent_secret`, `gitops_redis_password`, and optional org/project/agent IDs

Do **not** commit `terraform.tfvars`. Non-secret GitOps Helm values stay in `files/override.yaml`.

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
2. Installs chart `harness-delegate-ng` into `harness_namespace`
3. Installs chart `gitops-helm` as release `argocd` into `gitops_namespace`, merging `files/override.yaml` with secrets from tfvars

## 5. Verify

### Delegate

```bash
kubectl get ns harness-delegate-ng
kubectl get pods -n harness-delegate-ng
kubectl get deploy -n harness-delegate-ng
kubectl logs -n harness-delegate-ng -l app.kubernetes.io/name=harness-delegate-ng --tail=100
```

Expect pods `Running` / `Ready`. In Harness UI → **Delegates**, the named delegate should show as connected within a few minutes.

### GitOps agent

```bash
kubectl get ns harness-gitops
kubectl get pods -n harness-gitops
helm list -n harness-gitops
kubectl logs -n harness-gitops -l app.kubernetes.io/name=argocd-application-controller --tail=100
```

In Harness UI → **GitOps**, the agent should show as healthy/connected.

Useful status commands:

```bash
terraform show
helm list -A
```

## 6. Day-2 operations

### Change replicas, image, or values

Update `terraform.tfvars` and/or `files/override.yaml`, then:

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

If you wiped the cluster (`minikube-demo.sh reset` / `delete`), state may still think the release exists. Prefer destroy then apply (below), or `terraform apply -replace=...` only if you know what you are doing.

### View Helm release state

```bash
cd infra
terraform state show 'module.delegate.helm_release.delegate'
terraform state show 'helm_release.argocd'
```

## 7. Tear down

### Remove Terraform-managed releases (keep cluster)

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
| Pods `ImagePullBackOff` | Bad image tag / network | Fix image vars / `override.yaml`, re-apply |
| Delegate not connecting | Bad token, account ID, or endpoint | Check `terraform.tfvars`; inspect pod logs |
| GitOps agent not connecting | Bad `gitops_agent_secret` / identity IDs | Confirm secret and org/project/agent IDs in tfvars |
| GitOps Redis / auth errors | Bad `gitops_redis_password` | Update tfvars and re-apply |
| Delegate/agent never appears in UI | Outbound network blocked from Minikube | Ensure cluster can reach Harness endpoints |
| `terraform apply` wants to recreate | Cluster was reset under Terraform | `terraform destroy` then `apply`, or reset local state if API is gone |
| Insufficient CPU/memory | Minikube undersized | Defaults are 4 CPU / 4g; raise via `CPUS` / `MEMORY` on the script |

Debug pods:

```bash
kubectl describe pod -n harness-delegate-ng -l app.kubernetes.io/name=harness-delegate-ng
kubectl get pods -n harness-gitops
kubectl describe pod -n harness-gitops <pod-name>
kubectl logs -n harness-gitops <pod-name> --previous
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
- GitOps chart: https://github.com/harness/gitops-helm
