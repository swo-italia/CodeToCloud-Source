# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  #id       = "/subscriptions/63cbb0dd-59fe-4cb9-a739-77e69b1ee643/resourceGroups/marzulo_eu"
  name     = var.resourcegroupName
  location = var.location_name
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = var.networkName
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a storage account
resource "azurerm_storage_account" "sa" {
  name                     = var.storageAcctName
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a ACR
resource "azurerm_container_registry" "example" {
  name                = var.containerRegistryName
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
}

# Create a CosmosDB
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_cosmosdb_account" "db" {
  name                 = var.cosmosDBName
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  offer_type           = "Standard"
  kind                 = "MongoDB"
  mongo_server_version = "3.6"

  enable_free_tier = true

  capabilities {
    name = "EnableMongo"
  }

  capabilities {
    name = "DisableRateLimitingResponses"
  }

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
    zone_redundant    = false
  }

  provisioner "local-exec" {
    command     = "docker run -ti -e MONGODB_CONNECTION=\"$MONGO_PKEY\" ghcr.io/swo-italia/fabrikam-init"
    working_dir = "/workspaces/CodeToCloud-Source/content-init"
    environment = {
      MONGO_PKEY = "mongodb://fabmedical-cdb-mzl:${azurerm_cosmosdb_account.db.primary_key}@fabmedical-cdb-mzl.mongo.cosmos.azure.com:10255/contentdb?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@fabmedical-cdb-mzl@"
    }
  }
}

resource "azurerm_app_service_plan" "main" {
  name                = var.planName
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "main" {
  name                    = var.webappName
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  app_service_plan_id     = azurerm_app_service_plan.main.id
  client_affinity_enabled = false

  site_config {
    always_on        = "true"
    app_command_line = ""
    ftps_state       = "Disabled"
    linux_fx_version = local.linux_fx_version

    use_32_bit_worker_process = "true"
  }

  app_settings = local.app_settings
}
