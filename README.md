# K3d GPU Support

This is a simple repository for preparing a `k3s` + `nvidia/cuda` base image that enables a K3d cluster to have access to your host machine's NVIDIA, CUDA-capable GPU(s).

## Pre-Requisites

Access to GitHub and GitHub Container Registry. Please follow the [GitHub Container Registry instructions](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

Docker and all of its dependencies must be installed. To build and push a new version of the Docker image to the GHCR, Docker Buildx must be installed and configured correctly.

For the container GPU test, a NVIDIA GPU with CUDA cores and drivers must be present. Additionally, the CUDA toolkit and NVIDIA container toolkit must be installed.

For Kubernetes testing and pre-requisites, please see [Kubernetes Deployment](#kubernetes-deployment) for details.

## Usage

### Building and Pushing the Image

Run the `./build.sh` script to build and push a new image. Please see script for arguments and options.

## Kubernetes Deployment

Follow the instructions in the [zarf-package-k3d-airgap](https://github.com/defenseunicorns/zarf-package-k3d-airgap) repository for bootstrapping a K3d cluster that can access your NVIDIA GPUs.

You can also a use more abstracted version of the above Kubernetes deployment by following the instructions in the [uds-leapfrogai](https://github.com/defenseunicorns/uds-leapfrogai/tree/main/bundles/gpu) bundle repository.

## Test

Run:

```shell
kubectl apply -f test/cuda-vector-add.yaml
kubectl logs cuda-vector-add
```
