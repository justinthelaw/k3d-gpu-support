#!/bin/bash

set -euxo pipefail

DOCKERFILE=${DOCKERFILE:="./docker/Dockerfile"}
K3S_TAG=${K3S_TAG:="v1.28.8-k3s1"} # replace + with -, if needed
RC_TAG=${RC_TAG:="rc.1"} # identifies release candidate (non-stable) upgrades

IMAGE_REGISTRY=${IMAGE_REGISTRY:="ghcr.io/justinthelaw"}
IMAGE_REPOSITORY=${IMAGE_REPOSITORY:="k3d-gpu-support"}
IMAGE_TAG="$K3S_TAG-$RC_TAG"
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
  --push \
  -f ${DOCKERFILE} . # should be the path e.g., ./docker/Dockerfile.rc

docker buildx rm multiplatform

echo "Done!"
