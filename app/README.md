# Sample Java App

Spring Boot **2.7** (Java **11**) demo app for Harness CI/CD: Maven test, Docker image push, and **classic Kubernetes canary** deploy with a version/color UI.

Operational detail (local Maven, Docker Hub push, troubleshooting): **[RUNBOOK.md](RUNBOOK.md)**.  
Harness pipeline / service / infra live under [`.harness/`](../.harness/) at the repo root.

## What it demonstrates

| Capability | How |
|------------|-----|
| Unit tests | JUnit 5 via `mvn test` / Harness CI |
| Container image | Multi-stage `Dockerfile` → Docker Hub (`likzdev/harness-java-web-app:<tag>`) |
| K8s manifests | [`k8s/`](k8s/) Deployment + Service (Harness Go templates + `values.yaml`) |
| Canary rollout | Harness CD: canary (1 pod) → approve → delete canary → rolling primary |
| Visible canary signal | UI shows **version** (= image tag) and **variant** (`APP_COLOR`) |

## Prerequisites

| Tool | Required for | Notes |
|------|----------------|-------|
| **Docker** | Build/run/push image; or run Maven in a container | Daemon must be running |
| **JDK 11** + **Maven 3.8+** | Native `mvn` / `spring-boot:run` | Optional if you use `maven:3.8-jdk-11` via Docker |
| **Docker Hub account** | `docker push` / Harness Build and Push | — |
| **kubectl** + Minikube | Canary verify / cluster access | Cluster used by Harness delegate |
| **make** (optional) | `Makefile` shortcuts | — |

```bash
brew install openjdk@11 maven   # optional native toolchain
docker info && kubectl version --client
```

## Quick start (local)

```bash
cd app

# Tests (Docker — no local Maven required)
docker run --rm -v "$PWD":/w -w /w maven:3.8-jdk-11 mvn -B clean test

# Or native
mvn -B clean test
mvn -B spring-boot:run
# optional: APP_COLOR=amber APP_VERSION=42 mvn -B spring-boot:run
```

Open http://localhost:8080

## Endpoints

| Path | Description |
|------|-------------|
| `/` | Landing page (brand, version chip, color/variant chip) |
| `/api/hello` | JSON: message, version, color |
| `/api/version` | JSON: name, version, color |
| `/actuator/health` | Health probe (used by K8s readiness/liveness) |

## Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `APP_COLOR` | `blue` | UI accent: `blue`, `green`, `amber` (or `yellow`), `red`, `teal` |
| `APP_VERSION` | Maven `project.version` (e.g. `1.0.0`) | Version shown on `/` and `/api/*` |

In Harness CD:

- `APP_COLOR` ← pipeline variable **`appColor`** (dropdown at run time)
- `APP_VERSION` ← Docker image tag (`<+artifacts.primary.tag>`, same as `<+pipeline.sequenceId>` from CI)

Wired in [`k8s/values.yaml`](k8s/values.yaml) and injected as env on the Deployment.

## Kubernetes manifests

```
k8s/
  values.yaml              # image, replicas, APP_COLOR, APP_VERSION
  templates/
    deployment.yaml        # probes on /actuator/health, port 8080
    service.yaml           # ClusterIP 80 → 8080
```

Harness service points at these paths; image is `<+artifacts.primary.image>`.

## Harness CI → canary CD (overview)

Pipeline [`kz_java_demo`](../.harness/kz_java_demo_clickops.yaml):

1. **CI** — `mvn clean test`, then Build and Push `likzdev/harness-java-web-app:<+pipeline.sequenceId>`
2. **CD (classic K8s, not GitOps)**  
   - `K8sCanaryDeploy` (1 pod, track `canary`)  
   - Manual approval  
   - `K8sCanaryDelete`  
   - `K8sRollingDeploy` (full replica set, track `stable`)

During canary you temporarily have:

| Deployment | Track label | Role |
|------------|-------------|------|
| `harness-java-web-app` | `harness.io/track=stable` | Current primary |
| `harness-java-web-app-canary` | `harness.io/track=canary` | New version under test |

## Verify canary vs stable (Minikube)

`kubectl port-forward svc/...` sticks to **one** pod for the session, so refreshes usually never show the canary. Forward each Deployment instead (`port-forward` does **not** support `-l`):

```bash
kubectl -n default port-forward deployment/harness-java-web-app 8080:8080          # stable
# other terminal:
kubectl -n default port-forward deployment/harness-java-web-app-canary 8081:8080   # canary
```

Or resolve a pod by label:

```bash
kubectl -n default port-forward pod/$(kubectl -n default get pod -l harness.io/track=stable -o jsonpath='{.items[0].metadata.name}') 8080:8080
kubectl -n default port-forward pod/$(kubectl -n default get pod -l harness.io/track=canary -o jsonpath='{.items[0].metadata.name}') 8081:8080
```

- Stable: http://localhost:8080  
- Canary: http://localhost:8081  

After approval and rolling deploy, the canary Deployment is removed and primary pods run the new tag.

## Docker Hub (summary)

CI pushes `likzdev/harness-java-web-app`. For a manual local push (parameterized name):

```bash
docker login
export DOCKERHUB_USER=myuser IMAGE_NAME=sample-java-app IMAGE_TAG=1.0.0
docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} .
docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
```

See **[RUNBOOK.md](RUNBOOK.md)** for Makefile targets and full publish steps.

## Project layout

```
app/
  pom.xml                 # Spring Boot 2.7, Java 11, JUnit via spring-boot-starter-test
  Dockerfile              # maven:3.8-jdk-11 build → eclipse-temurin:11-jre
  Makefile
  README.md
  RUNBOOK.md
  k8s/                    # Harness CD manifests (canary-ready)
  src/main/java/…         # App, API, Thymeleaf home
  src/main/resources/     # templates, CSS, application.properties
  src/test/java/…         # JUnit 5 API tests
```
