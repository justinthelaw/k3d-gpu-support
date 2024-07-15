
REGISTRY_NAME := registry
REGISTRY_PORT := 5000
SHELL_SCRIPT := build.sh

# Default target
all: create-registry build

# Create local Docker registry
create-registry:
	@echo "Creating local Docker registry..."
	@docker run -d -p $(REGISTRY_PORT):5000 --name $(REGISTRY_NAME) registry:2
	@echo "Local registry created at localhost:$(REGISTRY_PORT)"

# Run the shell script with the local registry
build:
	@echo "Running build and push script..."
	@IMAGE_REGISTRY=localhost:$(REGISTRY_PORT) \
	 IMAGE_REPOSITORY=k3d-gpu-support \
	 K3S_TAG=v1.28.8-k3s1 \
	 RC_TAG=rc.1 \
	 DOCKERFILE=./docker/Dockerfile \
	 bash $(SHELL_SCRIPT)

# Clean up: Stop and remove the local registry
clean:
	@echo "Cleaning up..."
	@docker stop $(REGISTRY_NAME) || true
	@docker rm $(REGISTRY_NAME) || true

.PHONY: all create-registry build clean