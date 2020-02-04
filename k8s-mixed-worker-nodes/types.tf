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
  nvme_instance_types = [
    "c5d.large",
    "c5d.xlarge",
    "c5d.2xlarge",
    "c5d.4xlarge",
    "c5d.9xlarge",
    "c5d.18xlarge",

    "f1.2xlarge",
    "f1.4xlarge",
    "f1.16xlarge",

    "i3.large",
    "i3.xlarge",
    "i3.2xlarge",
    "i3.4xlarge",
    "i3.8xlarge",
    "i3.16xlarge",
    "i3.metal",

    "i3en.large",
    "i3en.xlarge",
    "i3en.2xlarge",
    "i3en.3xlarge",
    "i3en.6xlarge",
    "i3en.12xlarge",
    "i3en.24xlarge",

    "m5d.large",
    "m5d.xlarge",
    "m5d.2xlarge",
    "m5d.4xlarge",
    "m5d.12xlarge",
    "m5d.24xlarge",
    "m5d.metal",

    "m5ad.large",
    "m5ad.xlarge",
    "m5ad.2xlarge",
    "m5ad.4xlarge",
    "m5ad.12xlarge",
    "m5ad.24xlarge",

    "p3dn.24xlarge",

    "r5d.large",
    "r5d.xlarge",
    "r5d.2xlarge",
    "r5d.4xlarge",
    "r5d.12xlarge",
    "r5d.24xlarge",
    "r5d.metal",

    "r5ad.large",
    "r5ad.xlarge",
    "r5ad.2xlarge",
    "r5ad.4xlarge",
    "r5ad.12xlarge",
    "r5ad.24xlarge",

    "z1d.large",
    "z1d.xlarge",
    "z1d.2xlarge",
    "z1d.3xlarge",
    "z1d.6xlarge",
    "z1d.12xlarge",
    "z1d.metal",
  ]

  nvme_ndevices_by_type = [0, // dummy
    // c5d
    1, 1, 1, 1, 1, 1,
    // f1
    1, 1, 4,
    // i3
    1, 1, 1, 2, 4, 8, 8,
    // i3en
    1, 1, 2, 1, 2, 4, 8,
    // m5d
    1, 1, 1, 2, 2, 4, 4,
    // m5ad
    1, 1, 1, 2, 2, 4,
    // p3dn
    2,
    // r5d
    1, 1, 1, 2, 2, 4, 4,
    // r5ad
    1, 1, 1, 2, 2, 4,
    // z1
    1, 1, 1, 1, 1, 2, 2,
  ]
}