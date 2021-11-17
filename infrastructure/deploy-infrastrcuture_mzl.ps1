param
(
    [string] $studentprefix = "mzl"
)

## DECLARE VARIABLES
#$studentprefix = "mzl"
$resourcegroupName = "fabmedical-rg-" + $studentprefix
$cosmosDBName = "fabmedical-cdb-" + $studentprefix
$webappName = "fabmedical-web-" + $studentprefix
$planName = "fabmedical-plan-" + $studentprefix
$location1 = "westeurope"
#$location2 = "northeurope"

#Create Resource Group
$rg = az group create --location $location1 --name $resourcegroupName | ConvertFrom-Json

# Create CosmosDB
az cosmosdb create --name $($cosmosDBName) `
--resource-group $($resourcegroupName) --kind MongoDB `
--locations regionName=$($location1) failoverPriority=0 isZoneRedundant=False `
--enable-free-tier true --server-version 3.6 `
--capabilities "EnableServerless" --capabilities "EnableMongo" --capabilities "DisableRateLimitingResponses"

# Create Azure App Service Plan
az appservice plan create --name $($planName) --resource-group $($resourcegroupName) --sku S1 --is-linux

# Create Azure Web App COMPOSE CONTAINERS
az webapp create -g $($resourcegroupName) -p $($planName) -n $($webappName) `
--multicontainer-config-file docker-compose.yml `
--multicontainer-config-type COMPOSE 

# Reconfigure Azure Web App GHCR credentials
az webapp config appsettings set --settings DOCKER_REGISTRY_SERVER_USERNAME="swo-italia" `
--name $($webappName) --resource-group $($resourcegroupName)

az webapp config appsettings set --settings DOCKER_REGISTRY_SERVER_URL="https://ghcr.io" `
--name $($webappName) --resource-group $($resourcegroupName)

az webapp config appsettings set --settings DOCKER_REGISTRY_SERVER_PASSWORD="$($env.CTC_PAT)" `
--name $($webappName) --resource-group $($resourcegroupName)

az webapp config appsettings set --settings WEBSITES_WEBDEPLOY_USE_SCM="false" `
--name $($webappName) --resource-group $($resourcegroupName)

az webapp config appsettings set --settings WEBSITES_ENABLE_APP_SERVICE_STORAGE="false" `
--name $($webappName) --resource-group $($resourcegroupName)

az webapp config appsettings set --settings WEBSITES_PORT = 80 `
--name $($webappName) --resource-group $($resourcegroupName)

# Reconfigure Azure Web App as COMPOSE and inform .yml
az webapp config container set `
--docker-registry-server-password $($env:CTC_PAT) `
--docker-registry-server-url https://ghcr.io `
--docker-registry-server-user swo-italia `
--multicontainer-config-file docker-compose.yml `
--multicontainer-config-type COMPOSE `
--name $webappName `
--resource-group $resourcegroupName 

# Reconfigure Azure Web App with DB Connection Information
$cosmodbpkey = az cosmosdb keys list -n fabmedical-cdb-mzl -g $resourcegroupName --type keys --query primaryMasterKey

az webapp config appsettings set -n $webappName -g $resourcegroupName `
--settings MONGODB_CONNECTION="mongodb://fabmedical-cdb-mzl:$($cosmodbpkey)@fabmedical-cdb-mzl.mongo.cosmos.azure.com:10255/contentdb?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@fabmedical-cdb-mzl@"

# Reconfigure MongoDB with current data
Set-Location ./content-init
docker run -e MONGODB_CONNECTION="mongodb://fabmedical-cdb-mzl:$($cosmodbpkey)@fabmedical-cdb-mzl.mongo.cosmos.azure.com:10255/contentdb?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@fabmedical-cdb-mzl@" `
ghcr.io/swo-italia/fabrikam-init

Set-Location ../infrastructure

# Restart the APP to read the MONGODB
az webapp restart -g $($resourcegroupName) -n $($webappName)
