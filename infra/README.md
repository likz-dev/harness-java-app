# Harness Delegate — Terraform

Deploys a [Harness NG Kubernetes delegate](https://developer.harness.io/docs/platform/delegates/delegate-concepts/delegate-overview) to a local cluster (Minikube) using the official Helm-based Terraform module.

## What it deploys

| Component | Source |
|-----------|--------|
| Harness Delegate (NG) | `harness/harness-delegate/kubernetes` module `v0.2.3` |
| Helm release | Chart `harness-delegate-ng` into `var.harness_namespace` |

The Helm provider reads `~/.kube/config` (your active kubectl context).

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) running
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) and [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.0`
- A Harness account, account ID, and delegate token

## Layout

```
infra/
├── harness-delegate.tf   # module + helm provider
├── variables.tf          # input variables
├── terraform.tfvars      # local values (gitignored — do not commit)
├── .gitignore
├── README.md             # this file
└── RUNBOOK.md            # step-by-step ops guide
```

Related: `../scripts/minikube-demo.sh` starts a local Minikube cluster for demos.

## Quick start

See [RUNBOOK.md](./RUNBOOK.md) for the full procedure. Short version:

```bash
# from repo root
./scripts/minikube-demo.sh start

cd infra
cp terraform.tfvars.example terraform.tfvars   # if you use an example file
# edit terraform.tfvars with your Harness values

terraform init
terraform plan
terraform apply
```

## Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `harness_account_id` | yes | — | Harness account ID |
| `harness_delegate_token` | yes | — | Delegate token (sensitive) |
| `harness_delegate_name` | yes | — | Delegate name in Harness |
| `harness_deploy_mode` | yes | — | Usually `KUBERNETES` |
| `harness_namespace` | yes | — | Target namespace (e.g. `harness-delegate-ng`) |
| `harness_manager_endpoint` | yes | — | e.g. `https://app.harness.io` |
| `harness_delegate_image` | yes | — | Delegate container image |
| `harness_replicas` | no | `1` | Replica count |
| `harness_upgrader_enabled` | no | `false` | Enable auto-upgrader |
| `harness_additional_values` | no | `{ javaOpts = "-Xms64M" }` | Extra Helm values (merged) |

Set values in `terraform.tfvars` (gitignored) or via `TF_VAR_*` environment variables.

Example `terraform.tfvars`:

```hcl
harness_account_id         = "YOUR_ACCOUNT_ID"
harness_delegate_token     = "YOUR_DELEGATE_TOKEN"
harness_delegate_name      = "terraform-delegate"
harness_deploy_mode        = "KUBERNETES"
harness_namespace          = "harness-delegate-ng"
harness_manager_endpoint   = "https://app.harness.io"
harness_delegate_image     = "us-docker.pkg.dev/gar-prod-setup/harness-public/harness/delegate:<tag>"
harness_replicas           = 1
harness_upgrader_enabled   = true
```

## Security

- `*.tfvars`, state files, and `.terraform/` are gitignored — never commit tokens or state.
- Prefer a short-lived / demo-scoped delegate token.
- Local state (`terraform.tfstate`) stays on disk under `infra/`; treat it as sensitive.

## References

- [Harness Delegate Terraform module](https://registry.terraform.io/modules/harness/harness-delegate/kubernetes/latest)
- [Install a Kubernetes delegate](https://developer.harness.io/docs/platform/delegates/install-delegates/overview)
- [RUNBOOK.md](./RUNBOOK.md)
