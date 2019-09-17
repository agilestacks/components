# nvidia-driver

This component installs 2 daemonsets which install an nvidia driver as well as the k8s-device-plugin for nvidia.


Note that these daemonsets are defined to only run on nodes with the nvidia.com/gpu label.  They also tolerate the nvidia.com/gpu taint
