#!/bin/bash

set -euxo pipefail

K3S_TAG=${K3S_TAG:="v1.27.9-k3s1"} # replace + with -, if needed
IMAGE_REGISTRY=${IMAGE_REGISTRY:="ghcr.io/justinthelaw"}
IMAGE_REPOSITORY=${IMAGE_REPOSITORY:="k3d-gpu-support"}
IMAGE_TAG="$K3S_TAG-cuda"
IMAGE=${IMAGE:="$IMAGE_REGISTRY/$IMAGE_REPOSITORY:$IMAGE_TAG"}

echo "IMAGE=$IMAGE"

# due to some unknown reason, copying symlinks fails with buildkit enabled
# DIFF: removed extraneous build-arg for NVIDIA_CONTAINER_RUNTIME_VERSION
DOCKER_BUILDKIT=0 docker build \
  --build-arg K3S_TAG=$K3S_TAG \
  -t $IMAGE .
docker push $IMAGE
echo "Done!"