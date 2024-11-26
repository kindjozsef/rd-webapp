# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

# Create the vNet
resource "azurerm_virtual_network" "vnet-rd-iac" {
  address_space           = ["10.0.0.0/16"]
  flow_timeout_in_minutes = "30"
  location                = azurerm_resource_group.rg.location
  name                    = "vnet-rd-iac"
  resource_group_name     = azurerm_resource_group.rg.name
}

# Create the subnets
resource "azurerm_subnet" "subnet-rd-iac-pe-keyvault" {
  address_prefixes                               = ["10.0.3.0/24"]
  default_outbound_access_enabled                = "true"
  name                                           = "subnet-rd-iac-pe-keyvault"
  private_endpoint_network_policies              = "Disabled"
  private_link_service_network_policies_enabled  = "false"
  resource_group_name                            = azurerm_virtual_network.vnet-rd-iac.resource_group_name
  virtual_network_name                           = azurerm_virtual_network.vnet-rd-iac.name
}

data "github_ip_ranges" "github-action-ips" {

}

# Create the Azure keyvault
resource "azurerm_key_vault" "keyvault-app-service" {
  access_policy {
    certificate_permissions = ["Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Recover", "Restore", "SetIssuers", "Update"]
    key_permissions         = ["Backup", "Create", "Delete", "Get", "GetRotationPolicy", "Import", "List", "Recover", "Restore", "Rotate", "SetRotationPolicy", "Update"]
    object_id               = var.admin_object_id
    secret_permissions      = ["Backup", "Delete", "Get", "List", "Recover", "Restore", "Set"]
    tenant_id               = var.tenant_id
  }

  access_policy {
    certificate_permissions = ["Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Recover", "Restore", "SetIssuers", "Update"]
    key_permissions         = ["Backup", "Create", "Delete", "Get", "GetRotationPolicy", "Import", "List", "Recover", "Restore", "Rotate", "SetRotationPolicy", "Update"]
    object_id               = var.admin_object_id_2
    secret_permissions      = ["Backup", "Delete", "Get", "List", "Recover", "Restore", "Set"]
    tenant_id               = var.tenant_id
  }

  enable_rbac_authorization       = "false"
  enabled_for_deployment          = "false"
  enabled_for_disk_encryption     = "false"
  enabled_for_template_deployment = "false"
  location                        = azurerm_resource_group.rg.location
  name                            = var.keyvault_name

  network_acls {
    bypass         = "None"
    default_action = "Deny"
    ip_rules = data.github_ip_ranges.github-action-ips.actions_ipv4
  }

  public_network_access_enabled = "true"
  purge_protection_enabled      = "false"
  resource_group_name           = azurerm_resource_group.rg.name
  sku_name                      = "standard"
  soft_delete_retention_days    = "90"

  tags = {
    rd_hmwrk = "5"
  }

  tenant_id = var.tenant_id
}