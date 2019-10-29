# intel-gpu


This component provides a DaemonSet which installs the Kubernetes Device Plugin for Intel GPUs.

Note that it is restricted to nodes with the `gpu.intel.com/i915` label. It also tolerates the `gpu.intel.com/i915` taint.
