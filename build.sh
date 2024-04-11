#!/bin/bash

set -euxo pipefail

K3S_TAG=${K3S_TAG:="v1.28.8-k3s1"} # replace + with -, if needed
CUDA_TAG=${CUDA_TAG:="12.4.1-base-ubuntu22.04"} # replace + with -, if needed

IMAGE_REGISTRY=${IMAGE_REGISTRY:="ghcr.io/justinthelaw"}
IMAGE_REPOSITORY=${IMAGE_REPOSITORY:="k3d-gpu-support"}
IMAGE_TAG="$K3S_TAG-cuda-$CUDA_TAG"
IMAGE=${IMAGE:="$IMAGE_REGISTRY/$IMAGE_REPOSITORY:$IMAGE_TAG"}

echo "IMAGE=$IMAGE"

# DIFF: use buildx for multi-platform images
docker buildx install
if docker buildx ls | grep -q "multiplatform"; then
    docker buildx rm multiplatform
fi
docker buildx create --use --name multiplatform

# DIFF: removed extraneous build-args, added platforms list, combined push
docker buildx build \
  --build-arg K3S_TAG=$K3S_TAG \
  --platform linux/amd64,linux/arm64 \
  -t $IMAGE \
  --push .

docker buildx rm multiplatform

echo "Done!"
