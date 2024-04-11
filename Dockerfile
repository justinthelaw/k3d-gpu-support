# ORIGINAL TUTORIAL: https://k3d.io/v5.6.0/usage/advanced/cuda/#dockerfile
# MODIFIED IMPLEMENTATION: https://github.com/k3d-io/k3d/issues/1108#issue-1315509856
# "DIFF:" comments explain differences between tutorial and this modified implementation

# DIFF: updated base image to most recent k3s and cuda version
ARG K3S_TAG="v1.28.8-k3s1"
ARG CUDA_TAG="12.4.1-base-ubuntu22.04"

FROM rancher/k3s:$K3S_TAG as k3s

# DIFF: updated base image to most recent CUDA and base OS version combination
FROM nvidia/cuda:$CUDA_TAG

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get update && \
    apt-get -y install gnupg2 curl

# Install NVIDIA Container Runtime
RUN curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | apt-key add -

# DIFF: changed base OS for runtime grab
RUN curl -s -L https://nvidia.github.io/nvidia-container-runtime/ubuntu22.04/nvidia-container-runtime.list | tee /etc/apt/sources.list.d/nvidia-container-runtime.list

# DIFF: grab necessary NVIDIA toolkit and deps for base image's CUDA version - NVIDIA_CONTAINER_RUNTIME_VERSION arg is deprecated as well
RUN apt-get update && \
    apt-get -y install nvidia-container-toolkit-base nvidia-container-toolkit nvidia-container-runtime util-linux

# DIFF: configure containerd runtime within container
RUN nvidia-ctk runtime configure --runtime=containerd

# DIFF: different mount calls than the original k3s image, deliberate k3s deps copy
COPY --from=k3s /bin/* /bin/
RUN rm /usr/bin/mount
COPY --from=k3s /bin/sh /usr/bin/sh
COPY --from=k3s /bin/sh /bin/sh
COPY --from=k3s /etc /etc
COPY --from=k3s /bin/k3s /bin/k3s
COPY --from=k3s /bin/aux /bin/aux
COPY --from=k3s /lib/modules /lib/modules
COPY --from=k3s /run /run
COPY --from=k3s /lib/firmware /lib/firmware

# DIFF: need to set CRI variable
ENV CRI_CONFIG_FILE=/var/lib/rancher/k3s/agent/etc/crictl.yam

RUN mkdir -p /etc && \
    echo 'hosts: files dns' > /etc/nsswitch.conf

RUN chmod 1777 /tmp

# Provide custom containerd configuration to configure the nvidia-container-runtime
RUN mkdir -p /var/lib/rancher/k3s/agent/etc/containerd/

# DIFF: used MODIFIED IMPLEMENTATION config
COPY config.toml.tmpl /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl

# Deploy the nvidia driver plugin on startup
RUN mkdir -p /var/lib/rancher/k3s/server/manifests

# DIFF: using the updated NVIDIA device plugin daemonset: https://github.com/NVIDIA/k8s-device-plugin/
COPY device-plugin-daemonset.yaml /var/lib/rancher/k3s/server/manifests/nvidia-device-plugin-daemonset.yaml

VOLUME /var/lib/kubelet
VOLUME /var/lib/rancher/k3s
VOLUME /var/lib/cni
VOLUME /var/log

# DIFF: resolve fsnotify issues
RUN sysctl -w fs.inotify.max_user_watches=100000
RUN sysctl -w fs.inotify.max_user_instances=100000

ENV PATH="$PATH:/bin/aux"

ENTRYPOINT ["/bin/k3s"]
CMD ["agent"]