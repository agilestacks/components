### GPU nodes

1. Hub component amends worker node's Ignition config to run `nvidia.service` to insert Nvidia driver kernel modules via `agilestacks/coreos-nvidia:{coreos-version}` (based on `srcd/coreos-nvidia`). Currently the only version built is `1800.6.0 `.
2. `kubectl label node NAME gpu=tesla|whatever` (manual task).
3. `kubectl apply -f nvidia-gpu-device-plugin.yml` to schedule [GKE's Nvidia](https://github.com/GoogleCloudPlatform/container-engine-accelerators/tree/master/cmd/nvidia_gpu) [Device Plugin](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/) to `gpu=` nodes (manual task).
4. Copy OpenGL libraries to host `/nvidia`. We should change the device plugin to mount volume from container that `nvidia.service` provides - in case there is a capability to do so in Kubernetes. (?)
```
source /etc/os-release
docker run -v /nvidia:/nvidia agilestacks/coreos-nvidia:$VERSION cp -rpd /opt/nvidia /
```
5. Test `kubectl run -ti --rm --limits=nvidia.com/gpu=1 --image=tensorflow/tensorflow:latest-gpu tensorflow /bin/bash`. Must use [limits](https://kubernetes.io/docs/tasks/manage-gpus/scheduling-gpus/)

The NVCC default link profile is to link statically to CUDA `--cudart=static`. Most people will be using Tensorflow / etc. derived images, so we don't need to bring full set of shared CUDA libraries into the container, just the OpenGL / OpenCL and libcuda.so.1 parts. We need to research the exact working model, at least for our data-science / ML sample template.
