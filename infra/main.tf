# Create the resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

# Create Managed Identity for app service
resource "azurerm_user_assigned_identity" "managed-identity-app-service" {
  location            = azurerm_resource_group.rg.location
  name                = "app-service-mi"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_federated_identity_credential" "mi-identity-credential" {
  name                = "iot4tll72i4g2"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  parent_id           = azurerm_user_assigned_identity.managed-identity-app-service.id
  subject             = "repo:kindjozsef/rd-webapp:environment:Production"
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

resource "azurerm_subnet" "subnet-rd-iac-app-service" {
  address_prefixes                = ["10.0.1.0/24"]
  default_outbound_access_enabled = "true"

  delegation {
    name = "delegation"

    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      name    = "Microsoft.Web/serverFarms"
    }
  }

  name                                           = "subnet-rd-iac-app-service"
  private_endpoint_network_policies              = "Disabled"
  private_link_service_network_policies_enabled  = "true"
  resource_group_name                            = azurerm_virtual_network.vnet-rd-iac.resource_group_name
  service_endpoints                              = ["Microsoft.Storage"]
  virtual_network_name                           = azurerm_virtual_network.vnet-rd-iac.name
}

resource "azurerm_subnet" "subnet-rd-iac-pg-db" {
  address_prefixes                = ["10.0.2.0/24"]
  default_outbound_access_enabled = "true"

  delegation {
    name = "dlg-database"

    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }

  name                                           = "subnet-rd-iac-pg-db"
  private_endpoint_network_policies              = "Disabled"
  private_link_service_network_policies_enabled  = "true"
  resource_group_name                            = azurerm_virtual_network.vnet-rd-iac.resource_group_name
  service_endpoints                              = ["Microsoft.Storage"]
  virtual_network_name                           = azurerm_virtual_network.vnet-rd-iac.name
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
    certificate_permissions = []
    key_permissions         = []
    object_id               = var.terraform_account_object_id
    secret_permissions      = ["Backup", "Delete", "Get", "List", "Recover", "Restore", "Set"]
    tenant_id               = var.tenant_id
  }

  access_policy {
      key_permissions    = ["Get", "List"]
      object_id          = azurerm_linux_web_app.webapp.identity[0].principal_id
      secret_permissions = ["Get", "List"]
      tenant_id          = var.tenant_id
  }

  enable_rbac_authorization       = "false"
  enabled_for_deployment          = "false"
  enabled_for_disk_encryption     = "false"
  enabled_for_template_deployment = "false"
  location                        = azurerm_resource_group.rg.location
  name                            = var.keyvault_name

  network_acls {
    bypass         = "None"
    default_action = "Allow"
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

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_string" "db_username" {
  length           = 8
  special          = false
  numeric           = false
}

resource "azurerm_key_vault_secret" "keyvault-db-password" {
  name         = "pgdbpassword1"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.keyvault-app-service.id
}

resource "azurerm_key_vault_secret" "keyvault-db-username" {
  name         = "pgdbuser1"
  value        = random_string.db_username.result
  key_vault_id = azurerm_key_vault.keyvault-app-service.id
}

# Create Private DNS Zone
resource "azurerm_private_dns_zone" "dns-db" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name

  soa_record {
    email        = "azureprivatedns-host.microsoft.com"
    expire_time  = "2419200"
    minimum_ttl  = "10"
    refresh_time = "3600"
    retry_time   = "300"
    ttl          = "3600"
  }
}

resource "azurerm_private_dns_zone" "dns-keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name

  soa_record {
    email        = "azureprivatedns-host.microsoft.com"
    expire_time  = "2419200"
    minimum_ttl  = "10"
    refresh_time = "3600"
    retry_time   = "300"
    ttl          = "3600"
  }
}

# and records
resource "azurerm_private_dns_a_record" "dns-record-db" {
  name                = "eccdf4d557ee"
  records             = ["10.0.2.4"]
  resource_group_name = azurerm_private_dns_zone.dns-db.resource_group_name
  ttl                 = "30"
  zone_name           = "privatelink.postgres.database.azure.com"
}

resource "azurerm_private_dns_a_record" "tfer--rd-keyvault-123456" {
  name                = var.keyvault_name
  records             = ["10.0.3.4"]
  resource_group_name = azurerm_private_dns_zone.dns-keyvault.resource_group_name
  ttl                 = "3600"
  zone_name           = "privatelink.vaultcore.azure.net"
}

# and link
resource "azurerm_private_dns_zone_virtual_network_link" "vnet-link" {
  name                  = "btakxtaztlkdo"
  private_dns_zone_name = "${azurerm_private_dns_a_record.tfer--rd-keyvault-123456.zone_name}"
  registration_enabled  = "false"
  resource_group_name   = azurerm_private_dns_zone.dns-keyvault.resource_group_name
  virtual_network_id    = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/virtualNetworks/${azurerm_virtual_network.vnet-rd-iac.name}"
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet-link-db" {
  name                  = "btakxtaztlkdo"
  private_dns_zone_name = "${azurerm_private_dns_a_record.dns-record-db.zone_name}"
  registration_enabled  = "false"
  resource_group_name   = azurerm_private_dns_zone.dns-db.resource_group_name
  virtual_network_id    = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/virtualNetworks/${azurerm_virtual_network.vnet-rd-iac.name}"
}

# Create PE
resource "azurerm_private_endpoint" "tfer--keyvaultpe" {
  location = azurerm_key_vault.keyvault-app-service.location
  name     = "keyvaultpe"

  private_service_connection {
    is_manual_connection           = "false"
    name                           = "keyvaultpe_a172efd1-c06e-480a-87e6-e7f3a765918e"
    private_connection_resource_id = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.KeyVault/vaults/${azurerm_private_dns_a_record.tfer--rd-keyvault-123456.name}"
    subresource_names              = ["vault"]
  }

  resource_group_name = azurerm_private_dns_zone.dns-keyvault.resource_group_name
  subnet_id           = "/subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.Network/virtualNetworks/${azurerm_virtual_network.vnet-rd-iac.name}/subnets/${azurerm_subnet.subnet-rd-iac-pe-keyvault.name}"

  tags = {
    rd_hmwrk = "5"
  }
}

resource "azurerm_application_insights" "app_insights" {
  name                = "app-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "java"
}

# Create webapp
# Create the Linux App Service Plan

resource "azurerm_service_plan" "appserviceplan" {
  name                = "webapp-asp-75497123451"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "P1v3"
}

# Create the web app, pass in the App Service Plan ID
resource "azurerm_linux_web_app" "webapp" {
  name                  = "webapp-754971234513"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  service_plan_id       = azurerm_service_plan.appserviceplan.id
  https_only            = true
  virtual_network_subnet_id = azurerm_subnet.subnet-rd-iac-app-service.id
  site_config {
    minimum_tls_version = "1.2"
    ftps_state          = "FtpsOnly"
    application_stack  {
        java_version    = "17"
        java_server     = "JAVA"
        java_server_version = "17"
    }
  }
  app_settings = {
      APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.app_insights.connection_string
    }
  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.managed-identity-app-service.id
    ]
  }
}

resource "azurerm_role_assignment" "ra" {
  scope                = azurerm_linux_web_app.webapp.id
  role_definition_name = "Website Contributor"
  principal_id         = azurerm_user_assigned_identity.managed-identity-app-service.principal_id
}

# Deploy code from a public GitHub repo
resource "azurerm_app_service_source_control" "sourcecontrol" {
  app_id             = azurerm_linux_web_app.webapp.id
  repo_url           = "https://github.com/kindjozsef/rd-webapp"
  branch             = "master"
  use_manual_integration = true
  use_mercurial      = false
 }

 # Create postgresql flexible server

resource "azurerm_postgresql_flexible_server" "pg-server" {
  name                          = "kindjozsef-example-pg-server"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  version                       = "12"
  delegated_subnet_id           = azurerm_subnet.subnet-rd-iac-pg-db.id
  private_dns_zone_id           = azurerm_private_dns_zone.dns-db.id
  public_network_access_enabled = false
  administrator_login           = random_string.db_username.result
  administrator_password        = random_password.db_password.result
  zone                          = "1"

  storage_mb   = 32768
  storage_tier = "P4"

  sku_name   = "B_Standard_B1ms"
}