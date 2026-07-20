# Sample Java App

Spring Boot 2.7 (Java 11) sample for CI demos: Maven build/test, Docker image, and a version/color UI ready for a later canary rollout.

For step-by-step local deploy and Docker Hub publish instructions, see **[RUNBOOK.md](RUNBOOK.md)**.

## Prerequisites

| Tool | Required for | Notes |
|------|----------------|-------|
| **Docker** | Build/run/push image; also an alternative to local Maven | Docker Desktop (or equivalent) running |
| **JDK 11** | Native `mvn` / `spring-boot:run` | Skip if you only use Docker |
| **Maven 3.8+** | Native `mvn test` / package / run | Skip if you only use `maven:3.8-jdk-11` via Docker |
| **Docker Hub account** | `docker push` | Username + login credentials |
| **make** (optional) | Shortcut targets in `Makefile` | Commands also work plain |

### Install on macOS (Homebrew)

```bash
# Option A — native Maven + JDK
brew install openjdk@11 maven

# Option B — Docker only (no local JDK/Maven)
# Install Docker Desktop, then use the docker run … maven:3.8-jdk-11 commands in the runbook.
```

### Verify

```bash
docker info          # daemon must be running
java -version        # optional if using Docker-only workflow
mvn -version         # optional if using Docker-only workflow
```

## Quick start

```bash
cd app

# Tests (Docker — works without local Maven)
docker run --rm -v "$PWD":/w -w /w maven:3.8-jdk-11 mvn -B clean test

# Or native Maven (requires JDK 11 + mvn)
mvn -B clean test

# Run locally via Maven
mvn -B spring-boot:run
# → http://localhost:8080
```

## Endpoints

| Path | Description |
|------|-------------|
| `/` | Landing page (version + color) |
| `/api/hello` | JSON hello |
| `/api/version` | JSON version metadata |
| `/actuator/health` | Health probe |

`APP_COLOR` sets the UI accent / variant (`blue`, `green`, `amber`, `red`, `teal`). Default: `blue`.
In Kubernetes / Harness CD, set env `APP_COLOR` and `APP_VERSION` (image tag shown on `/` and `/api/*`).

## Verify Harness canary vs stable (Minikube)

During a Harness canary step you get two Deployments:

- `harness-java-web-app` — stable / primary (`harness.io/track=stable`)
- `harness-java-web-app-canary` — canary (`harness.io/track=canary`)

`kubectl port-forward svc/...` sticks to **one** pod for the whole session, so refreshes usually never show the canary. Forward each Deployment in its own terminal (`port-forward` does not support `-l`):

```bash
kubectl -n default port-forward deployment/harness-java-web-app 8080:8080          # stable (e.g. v14)
# other terminal:
kubectl -n default port-forward deployment/harness-java-web-app-canary 8081:8080   # canary (e.g. v15)
```

Or pick a pod by label:

```bash
kubectl -n default port-forward pod/$(kubectl -n default get pod -l harness.io/track=stable -o jsonpath='{.items[0].metadata.name}') 8080:8080
kubectl -n default port-forward pod/$(kubectl -n default get pod -l harness.io/track=canary -o jsonpath='{.items[0].metadata.name}') 8081:8080
```

Open http://localhost:8080 for stable and http://localhost:8081 for canary.

## Docker Hub (summary)

```bash
docker login
export DOCKERHUB_USER=myuser IMAGE_NAME=sample-java-app IMAGE_TAG=1.0.0
docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} .
docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
```

Full details, troubleshooting, and Makefile usage: **[RUNBOOK.md](RUNBOOK.md)**.

## Project layout

```
app/
  pom.xml
  Dockerfile
  Makefile
  README.md
  RUNBOOK.md
  src/main/java/…      # Spring Boot app
  src/main/resources/  # templates, CSS, application.properties
  src/test/java/…      # JUnit tests
```
