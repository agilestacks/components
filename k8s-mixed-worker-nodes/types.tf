locals {
  gpu_instance_types = [
    "p3.2xlarge",
    "p3.8xlarge",
    "p3.16xlarge",
    "p3dn.24xlarge",
    "p2.xlarge",
    "p2.8xlarge",
    "p2.16xlarge",
    "g3s.xlarge",
    "g3.4xlarge",
    "g3.8xlarge",
    "g3.16xlarge",
  ]

  // https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html
  nvme_device_count_by_type = {
    "c5d.large": 1,
    "c5d.xlarge": 1,
    "c5d.2xlarge": 1,
    "c5d.4xlarge": 1,
    "c5d.9xlarge": 1,
    "c5d.18xlarge": 1,

    "f1.2xlarge": 1,
    "f1.4xlarge": 1,
    "f1.16xlarge": 4,

    "i3.large": 1,
    "i3.xlarge": 1,
    "i3.2xlarge": 1,
    "i3.4xlarge": 2,
    "i3.8xlarge": 4,
    "i3.16xlarge": 8,
    "i3.metal": 8,

    "i3en.large": 1,
    "i3en.xlarge": 1,
    "i3en.2xlarge": 2,
    "i3en.3xlarge": 1,
    "i3en.6xlarge": 2,
    "i3en.12xlarge": 4,
    "i3en.24xlarge": 8,

    "m5d.large": 1,
    "m5d.xlarge": 1,
    "m5d.2xlarge": 1,
    "m5d.4xlarge": 2,
    "m5d.12xlarge": 2,
    "m5d.24xlarge": 4,
    "m5d.metal": 4,

    "m5ad.large": 1,
    "m5ad.xlarge": 1,
    "m5ad.2xlarge": 1,
    "m5ad.4xlarge": 2,
    "m5ad.12xlarge": 2,
    "m5ad.24xlarge": 4,

    "p3dn.24xlarge": 2,

    "r5d.large": 1,
    "r5d.xlarge": 1,
    "r5d.2xlarge": 1,
    "r5d.4xlarge": 2,
    "r5d.12xlarge": 2,
    "r5d.24xlarge": 4,
    "r5d.metal": 4,

    "r5ad.large": 1,
    "r5ad.xlarge": 1,
    "r5ad.2xlarge": 1,
    "r5ad.4xlarge": 2,
    "r5ad.12xlarge": 2,
    "r5ad.24xlarge": 4,

    "z1d.large": 1,
    "z1d.xlarge": 1,
    "z1d.2xlarge": 1,
    "z1d.3xlarge": 1,
    "z1d.6xlarge": 1,
    "z1d.12xlarge": 2,
    "z1d.metal": 2
  }

}