# Harness Delegate & GitOps — Terraform

Deploys a [Harness NG Kubernetes delegate](https://developer.harness.io/docs/platform/delegates/delegate-concepts/delegate-overview) and the [Harness GitOps agent](https://developer.harness.io/docs/continuous-delivery/gitops/install-a-kubernetes-agent/) (Argo CD) to a local cluster (Minikube) using Helm via Terraform.

## What it deploys

| Component | Source |
|-----------|--------|
| Harness Delegate (NG) | `harness/harness-delegate/kubernetes` module `v0.2.3` |
| Harness GitOps Agent | Helm chart `gitops-helm` from `https://harness.github.io/gitops-helm/` |

The Helm provider reads `~/.kube/config` (your active kubectl context).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) running
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) and [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.0`
- A Harness account, account ID, delegate token, and GitOps agent secret

## Layout

```
infra/
├── harness-delegate.tf      # delegate module + helm provider
├── harness-gitops.tf        # GitOps / Argo CD helm_release
├── files/override.yaml      # non-secret GitOps Helm values
├── variables.tf             # input variables
├── terraform.tfvars         # local values incl. secrets (gitignored)
├── terraform.tfvars.example # placeholder values (safe to commit)
├── .gitignore
├── README.md
└── RUNBOOK.md
```

Related: `../scripts/minikube-demo.sh` starts a local Minikube cluster for demos.

## Quick start

See [RUNBOOK.md](./RUNBOOK.md) for the full procedure. Short version:

```bash
# from repo root
./scripts/minikube-demo.sh start

cd infra
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your Harness values (delegate + GitOps secrets)

terraform init
terraform plan
terraform apply
```

## Accessing an application in the browser

ClusterIP services (common for demo apps) are not reachable from your Mac directly. Use `kubectl port-forward` to tunnel a local port to the service.

Example — `podinfo` in the `default` namespace on port `9898`:

```bash
kubectl port-forward -n default svc/podinfo 9898:9898
```

Leave that terminal running, then open **http://localhost:9898** in your browser.

General form:

```bash
kubectl port-forward -n <namespace> svc/<service-name> <local-port>:<service-port>
```

## Variables

### Delegate

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `harness_account_id` | yes | — | Harness account ID (also used for GitOps) |
| `harness_delegate_token` | yes | — | Delegate token (sensitive) |
| `harness_delegate_name` | yes | — | Delegate name in Harness |
| `harness_deploy_mode` | yes | — | Usually `KUBERNETES` |
| `harness_namespace` | yes | — | Target namespace (e.g. `harness-delegate-ng`) |
| `harness_manager_endpoint` | yes | — | e.g. `https://app.harness.io` |
| `harness_delegate_image` | yes | — | Delegate container image |
| `harness_replicas` | no | `1` | Replica count |
| `harness_upgrader_enabled` | no | `false` | Enable auto-upgrader |
| `harness_additional_values` | no | `{ javaOpts = "-Xms64M" }` | Extra Helm values (merged) |

### GitOps

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `gitops_namespace` | no | `harness-gitops` | Namespace for the GitOps release |
| `gitops_org_identifier` | no | `default` | Harness org ID |
| `gitops_project_identifier` | no | `default_project` | Harness project ID |
| `gitops_agent_identifier` | no | `harnessagent` | GitOps agent ID |
| `gitops_agent_secret` | yes | — | Agent private key / secret (sensitive) |
| `gitops_redis_password` | yes | — | Redis password for the chart (sensitive) |

Non-secret chart settings live in `files/override.yaml`. Secrets and account/identity fields are injected from Terraform (`set_sensitive` / values merge).

Set values in `terraform.tfvars` (gitignored) or via `TF_VAR_*` environment variables. See `terraform.tfvars.example`.

## Security

- `*.tfvars`, state files, and `.terraform/` are gitignored — never commit tokens, agent secrets, or state.
- Keep secrets out of `files/override.yaml` (only non-secret overrides belong there).
- Prefer short-lived / demo-scoped credentials.
- Local state (`terraform.tfstate`) stays on disk under `infra/`; treat it as sensitive.

## References

- [Harness Delegate Terraform module](https://registry.terraform.io/modules/harness/harness-delegate/kubernetes/latest)
- [Install a Kubernetes delegate](https://developer.harness.io/docs/platform/delegates/install-delegates/overview)
- [GitOps Helm chart](https://github.com/harness/gitops-helm)
- [RUNBOOK.md](./RUNBOOK.md)
