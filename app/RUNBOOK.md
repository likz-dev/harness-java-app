# Runbook: Sample Java App

Operational guide to run the app locally and publish the image to Docker Hub.

---

## 1. Prerequisites

Complete these before following any procedure below.

### Always required

| Prerequisite | Why | How to check |
|--------------|-----|----------------|
| **Docker** installed and **daemon running** | Build image, run container, push to Docker Hub; also used when Maven is not installed locally | `docker info` (must not error) |
| Shell in the `app/` directory | All commands assume this cwd | `pwd` → `…/harness/app` |

### Required for native Maven workflow

| Prerequisite | Why | How to check |
|--------------|-----|----------------|
| **JDK 11** | Compile and run Spring Boot | `java -version` → 11.x |
| **Maven 3.8+** (`mvn` on `PATH`) | `mvn test`, `mvn package`, `mvn spring-boot:run` | `mvn -version` |

If `mvn` or `java` is missing, either install them (macOS: `brew install openjdk@11 maven`) or use the **Docker-only** commands in this runbook (`maven:3.8-jdk-11` image).

### Required to push to Docker Hub

| Prerequisite | Why | How to check |
|--------------|-----|----------------|
| **Docker Hub account** | Destination for `docker push` | Account at [hub.docker.com](https://hub.docker.com) |
| **Logged in** via CLI | Auth for push | `docker login` |

### Optional

| Tool | Why |
|------|-----|
| **make** | `make test` / `make build` / `make push` / `make run` shortcuts |
| **curl** | Smoke-test HTTP endpoints after start |

### Parameterized image name

Set these before build/push (defaults shown):

| Variable | Default | Example |
|----------|---------|---------|
| `DOCKERHUB_USER` | `your-dockerhub-user` | `jdoe` |
| `IMAGE_NAME` | `sample-java-app` | `sample-java-app` |
| `IMAGE_TAG` | `1.0.0` | `1.0.0` |

Image reference: `${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}`

---

## 2. Deploy locally (Maven — no container)

**Prerequisites:** JDK 11, Maven 3.8+, network for first dependency download.

### 2.1 Tests

```bash
cd /path/to/harness/app
mvn -B test
```

Expect: `Tests run: 2, Failures: 0` and `BUILD SUCCESS`.

### 2.2 Run the app

```bash
mvn -B spring-boot:run
```

Optional canary-style variant:

```bash
APP_COLOR=amber mvn -B spring-boot:run
```

### 2.3 Verify

Open http://localhost:8080 or:

```bash
curl -s http://localhost:8080/api/hello
curl -s http://localhost:8080/actuator/health
```

Stop with `Ctrl+C`.

---

## 3. Deploy locally (Docker only — no local Maven/JDK)

**Prerequisites:** Docker running. No local `mvn` or JDK required.

### 3.1 Tests (same image as CI)

```bash
cd /path/to/harness/app
docker run --rm -v "$PWD":/w -w /w maven:3.8-jdk-11 mvn -B test
```

### 3.2 Build the app image

```bash
export DOCKERHUB_USER=myuser          # or any local name for tagging
export IMAGE_NAME=sample-java-app
export IMAGE_TAG=1.0.0

docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} .
```

This multi-stage build runs `mvn test package` inside `maven:3.8-jdk-11`, then copies the JAR into `eclipse-temurin:11-jre`.

### 3.3 Run the container

```bash
docker run --rm -p 8080:8080 \
  -e APP_COLOR=blue \
  ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
```

Or with Make:

```bash
make run DOCKERHUB_USER=myuser IMAGE_TAG=1.0.0 APP_COLOR=green
```

### 3.4 Verify

```bash
curl -s http://localhost:8080/api/hello
curl -s http://localhost:8080/actuator/health
```

Open http://localhost:8080 — version and color chips should match `APP_COLOR` / image tag metadata.

---

## 4. Push to Docker Hub

**Prerequisites:** Docker running, Docker Hub account, successful local image build (section 3.2).

### 4.1 Log in

```bash
docker login
# Username + password or access token when prompted
```

### 4.2 Build (if not already)

```bash
cd /path/to/harness/app
export DOCKERHUB_USER=myuser          # your Docker Hub username
export IMAGE_NAME=sample-java-app
export IMAGE_TAG=1.0.0

docker build -t ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} .
```

### 4.3 Push

```bash
docker push ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
```

Or end-to-end with Make (build then push):

```bash
make push DOCKERHUB_USER=myuser IMAGE_NAME=sample-java-app IMAGE_TAG=1.0.0
```

### 4.4 Confirm

- CLI: `docker pull ${DOCKERHUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}`
- UI: `https://hub.docker.com/r/${DOCKERHUB_USER}/${IMAGE_NAME}`

---

## 5. Configuration reference

| Variable / property | Where | Purpose |
|---------------------|--------|---------|
| `APP_COLOR` | Env at runtime | UI accent / canary variant (`blue`, `green`, `amber`, `red`, `teal`) |
| `app.version` | Built from Maven `${project.version}` | Shown on `/` and `/api/*` |
| `server.port` | `8080` (default) | HTTP listen port |

---

## 6. Troubleshooting

| Symptom | Likely cause | Fix |
|---------|----------------|-----|
| `zsh: command not found: mvn` | Maven not on `PATH` | Install JDK 11 + Maven, or use section 3 Docker commands |
| `Unable to locate a Java Runtime` | No JDK installed | `brew install openjdk@11` or use Docker-only workflow |
| `docker info` fails / cannot connect | Docker daemon not running | Start Docker Desktop |
| `denied` / `unauthorized` on push | Not logged in, or wrong `DOCKERHUB_USER` | `docker login`; ensure tag user matches Hub username |
| Port already in use (`8080`) | Another process bound | Stop it, or `docker run -p 8081:8080 …` |
| Tests fail in Docker but work locally (or reverse) | Stale `target/` or env | Re-run; for Docker bind-mount, ensure `app/` is the mount root |

---

## 7. Checklist (demo day)

- [ ] Docker running (`docker info`)
- [ ] `cd` into `app/`
- [ ] Tests green (`mvn -B test` **or** Docker Maven one-liner)
- [ ] App responds on http://localhost:8080
- [ ] `docker login` succeeded
- [ ] Image pushed: `${DOCKERHUB_USER}/sample-java-app:${IMAGE_TAG}`
- [ ] Optional: second run with `APP_COLOR=amber` to show canary-style variant
