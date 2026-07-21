# harness-java-app

Demo repo for integrating a sample Java app with Harness CI/CD on a local Minikube cluster: local tooling → Terraform (delegate + GitOps) → app → Git Experience config under `.harness/`.

## Assumption

A Harness account is already set up and ready for integration (account ID, connectors, delegate token, GitOps agent credentials as needed). This repo does not walk through creating the Harness account itself.

## Getting started

Follow these steps in order.

### 1. Infra prerequisites (`scripts/`)

Install local tooling and start a Minikube cluster for demos:

```bash
# Harness CLIs (hc + legacy harness)
./scripts/install-harness.sh

# Local Minikube cluster (Docker driver by default)
./scripts/minikube-demo.sh start
./scripts/minikube-demo.sh status
```

| Script | Purpose |
|--------|---------|
| [`scripts/install-harness.sh`](scripts/install-harness.sh) | Install `hc` and legacy `harness` CLIs |
| [`scripts/minikube-demo.sh`](scripts/minikube-demo.sh) | Create / start / stop / reset the demo Minikube cluster |

### 2. Deploy infrastructure (Terraform)

Deploy the Harness NG Kubernetes delegate and GitOps agent to the cluster.

See **[infra/README.md](infra/README.md)** (and [infra/RUNBOOK.md](infra/RUNBOOK.md) for the full procedure). Short version:

```bash
./scripts/minikube-demo.sh start

cd infra
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your Harness account / delegate / GitOps values

terraform init
terraform plan
terraform apply
```

### 3. Sample application (`app/`)

Spring Boot app used by the CI/CD pipeline (Maven test, Docker image, version/color UI for canary demos).

See **[app/README.md](app/README.md)** (and [app/RUNBOOK.md](app/RUNBOOK.md) for local deploy and Docker Hub publish).

```bash
cd app
docker run --rm -v "$PWD":/w -w /w maven:3.8-jdk-11 mvn -B clean test
# or: mvn -B clean test / mvn -B spring-boot:run
```

Kubernetes manifests live under `app/k8s/` and are referenced by the Harness service definition.

### 4. Harness CI/CD config (`.harness/`)

Git Experience YAML for the demo pipeline, service, environment, infrastructure, and reusable Stage templates:

```
.harness/
├── kz_java_demo_clickops.yaml          # CI (Maven + Docker push) → CD (K8s canary + approval)
└── orgs/default/projects/default_project/
    ├── services/                       # Kubernetes service + artifact
    ├── envs/                           # PreProduction environment + infra
    └── templates/                      # Reusable Stage templates (CI / canary CD)
```

These files sync with Harness via Git Experience. Connectors and secrets referenced in the YAML are expected to exist in your Harness project.

## Layout

| Path | Description |
|------|-------------|
| [`scripts/`](scripts/) | Local prereqs: CLI install, Minikube demo cluster |
| [`infra/`](infra/) | Terraform for Harness delegate + GitOps agent |
| [`app/`](app/) | Sample Java app + K8s manifests |
| [`.harness/`](.harness/) | Harness pipeline, service, env, infra, templates |
