
DOCKERFILE := docker/Dockerfile
REGISTRY_NAME := registry
REGISTRY_PORT := 5000
SHELL_SCRIPT := build.sh
ORGANIZATION := temp
PLATFORM := linux/amd64
TAG := latest
K3D_CLUSTER_NAME := k3d-core-slim-dev:0.24.0

# Default target
all: create-registry build-k3d push-k3d

# Create local Docker registry
create-registry:
	@echo "Creating local Docker registry..."
	-@docker run -d -p ${REGISTRY_PORT}:5000 --name ${REGISTRY_NAME} registry:2
	@echo "Local registry created at localhost:${REGISTRY_PORT}"

build-k3d: create-registry
	@docker build --platform=${PLATFORM} -t ghcr.io/${ORGANIZATION}/k3d-gpu-support:${TAG} -f ${DOCKERFILE} .
	@docker tag ghcr.io/${ORGANIZATION}/k3d-gpu-support:${TAG} localhost:${REGISTRY_PORT}/${ORGANIZATION}/k3d-gpu-support:${TAG}

push-k3d: create-registry build-k3d
	@docker push localhost:${REGISTRY_PORT}/${ORGANIZATION}/k3d-gpu-support:${TAG}

uds: create-registry build-k3d push-k3d
	uds deploy ${K3D_CLUSTER_NAME} --set K3D_EXTRA_ARGS="--gpus=all --image=localhost:${REGISTRY_PORT}/${ORGANIZATION}/k3d-gpu-support:${TAG}" --confirm

test: create-registry build-k3d push-k3d
	@kubectl apply -f test/cuda-vector-add.yaml
	@kubectl wait --for=jsonpath='{.status.phase}'=Succeeded --timeout=15s pod -l app=gpu-pod
	@kubectl logs -l app=gpu-pod

# Clean up: Stop and remove the local registry
clean:
	@echo "Cleaning up..."
	@docker stop ${REGISTRY_NAME} || true
	@docker rm ${REGISTRY_NAME} || true

.PHONY: all create-registry build-k3d push-k3d clean
