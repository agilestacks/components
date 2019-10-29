variable "domain_name" {
  type        = "string"
  description = "Domain name associated with DNS hosted zone"
}

variable "kubeconfig_context" {
  type = "string"
}

variable "namespace" {
  type    = "string"
  default = "gitlab"
}

variable "gitlab_ingress" {
  type = "string"
  default = "gitlab-cn-nginx-ingress-controller"
}

variable "component" {
  type = "string"
  default = "gitlab-cn-unicorn"
}

variable "azure_resource_group_name" {
  type    = "string"
  default = "superhub-eastus2"
}