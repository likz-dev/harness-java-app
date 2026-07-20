DOCKERHUB_USER ?= your-dockerhub-user
IMAGE_NAME ?= sample-java-app
IMAGE_TAG ?= 1.0.0

IMAGE := $(DOCKERHUB_USER)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: test package build push run

test:
	mvn -B clean test

package:
	mvn -B -DskipTests=false clean package

build:
	docker build -t $(IMAGE) .

push: build
	docker push $(IMAGE)

run:
	docker run --rm -p 8080:8080 -e APP_COLOR=$${APP_COLOR:-blue} $(IMAGE)
