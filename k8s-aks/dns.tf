data "azurerm_dns_zone" "base" {
  name                = var.base_domain
  resource_group_name = var.cloud_resource_group_name
}

resource "azurerm_dns_zone" "main" {
  name                = "${var.name}.${data.azurerm_dns_zone.base.name}"
  resource_group_name = var.cloud_resource_group_name
  # zone should belong to cluster resource group?
  # we cannot do this currently as components - such as Traefik and Cert Manager,
  # won't be able to manipulate DNS records
  # resource_group_name = "${var.aks_resource_group_name}"
}

resource "azurerm_dns_ns_record" "parent" {
  name                = var.name
  zone_name           = data.azurerm_dns_zone.base.name
  resource_group_name = var.cloud_resource_group_name
  ttl                 = 300
  records             = azurerm_dns_zone.main.name_servers
}

resource "azurerm_dns_cname_record" "api" {
  name                = "api"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = var.cloud_resource_group_name

  # resource_group_name = "${var.aks_resource_group_name}"
  ttl    = 300
  record = data.azurerm_kubernetes_cluster.k8s.fqdn
}

