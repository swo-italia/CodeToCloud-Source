#variable "resource_group_name" {
#  default = "fabmedical-rg-mzl"
#}

variable "location_name" {
  default = "westeurope"
}

variable "location_name_redundant" {
  default = "northeurope"
}

variable "studentprefix" {
  default = "mzl"
}

variable "resourcegroupName" {
  default = "fabmedical-rg-mzl"
}

variable "cosmosDBName" {
  default = "fabmedical-cdb-mzl"
}

variable "webappName" {
  default = "fabmedical-web-mzl"
}

variable "planName" {
  default = "fabmedical-plan-mzl"
}

variable "containerRegistryName" {
  ### alpha numeric characters only are allowed
  default = "fabmedicalacrmzl"
}

variable "storageAcctName" {
  ### can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
  default = "fabmedicalsanmzl"
}

variable "networkName" {
  default = "fabmedical-vnet-mzl"
}

variable "location1" {
  default = "westeurope"
}

variable "location2" {
  default = "northeurope"
}

variable "ctc_pat" {
  default = "x"
}

locals {
  mongo_pkey = "mongodb://fabmedical-cdb-mzl:${azurerm_cosmosdb_account.db.primary_key}@fabmedical-cdb-mzl.mongo.cosmos.azure.com:10255/contentdb?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@fabmedical-cdb-mzl@"

  app_settings = {
    #"WEBSITES_CONTAINER_START_TIME_LIMIT" = 230
    "WEBSITES_WEBDEPLOY_USE_SCM"          = "false"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = 80
    "DOCKER_REGISTRY_SERVER_USERNAME"     = "swo-italia"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://ghrc.io"
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = var.ctc_pat
    "MONGODB_CONNECTION"                  = local.mongo_pkey
  }

  container_type   = "COMPOSE"
  container_config = file("docker-compose.yml")

  #linux_fx_version = "COMPOSE|dmVyc2lvbjogIjMuNCIKc2VydmljZXM6CiAgYXBpOgogICAgaW1hZ2U6IGdoY3IuaW8vc3dvLWl0YWxpYS9mYWJyaWthbS1hcGk6bGF0ZXN0CiAgICBwb3J0czoKICAgICAgLSAiMzAwMTozMDAxIgogIHdlYjoKICAgIGltYWdlOiBnaGNyLmlvL3N3by1pdGFsaWEvZmFicmlrYW0td2ViOmxhdGVzdAogICAgZGVwZW5kc19vbjoKICAgICAgICAtIGFwaQogICAgZW52aXJvbm1lbnQ6CiAgICAgICAgQ09OVEVOVF9BUElfVVJMOiBodHRwOi8vYXBpOjMwMDEKICAgIHBvcnRzOgogICAgICAgIC0gIjMwMDA6ODAiCg=="

  file_base_64 = base64encode(local.container_config)

  linux_fx_version = "COMPOSE|${local.file_base_64}"

}
