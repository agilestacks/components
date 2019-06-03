variable "azure_location" {
}

variable "azure_resource_group_name" {
    default = "superhub"
}

variable "azure_client_id" {
}

variable "azure_client_secret" {
}

variable "azure_tenant_id" {
}

variable "azure_subscription_id" {
}

variable "server_name" {
    default = "postgresql"
}

variable "database_name" {
    default = "agilestacks"
}

variable "database_username" {
    default = "postgres"
}

variable "database_password" {
}

variable "database_version" {
    default = "10.0"
}

variable "database_sku_name" {
    default = "B_Gen5_2"
}

variable "database_sku_capacity" {
    default = "2"
}

variable "database_sku_tier" {
    default = "Basic"
}

variable "database_sku_family" {
    default = "Gen5"
}

variable "database_storage_mb" {
    default = "5120"
}
