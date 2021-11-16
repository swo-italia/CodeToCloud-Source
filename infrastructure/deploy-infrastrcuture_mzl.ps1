$studentprefix = "mzl"
$resourcegroupName = "fabmedical-rg" + $studentprefix
$cosmosDBName = "fabmedical-cdb-" + $studentprefix
$webappName = "fabmedical-web-" + $studentprefix
$planName = "fabmedical-plan-" + $studentprefix
$location1 = "westeurope"
#$location2 = "northeurope"

#Create Resource Group
az group create --location $location1 --name $resourcegroupName | ConvertFrom-Json

# Create CosmosDB
az cosmosdb create --name $cosmosDBName `
--resource-group $resourcegroupName --kind MongoDB `
--locations regionName=$location1 failoverPriority=0 isZoneRedundant=False `
--enable-free-tier true --server-version 3.6 `
--capabilities "EnableServerless" --capabilities "EnableMongo" --capabilities "DisableRateLimitingResponses" `
| ConvertFrom-Json

# Create Azure App Service Plan
az appservice plan create --name $planName --resource-group $resourcegroupName --sku S1 --is-linux | ConvertFrom-Json

az webapp create --resource-group marzulo_eu --plan $planName --name $webappName -i nginx | ConvertFrom-Json

az cosmosdb keys list -n fabmedical-cdb-mzl -g $resourcegroupName --type connection-strings | ConvertFrom-Json

# Create Azure Web App COMPOSE CONTAINERS
az webapp create -g $resourcegroupName -p $planName -n $webappName `
--docker-registry-server-password $global:CTC_PAT `
--docker-registry-server-user swo-italia `
--multicontainer-config-file docker-compose.yml `
--multicontainer-config-type COMPOSE 

az webapp config container set `
--docker-registry-server-password $global:CTC_PAT `
--docker-registry-server-url https://ghcr.io `
--docker-registry-server-user swo-italia `
--multicontainer-config-file docker-compose.yml `
--multicontainer-config-type COMPOSE `
--name $webappName `
--resource-group $resourcegroupName 

az webapp config appsettings set -n $webappName -g $resourcegroupName --settings MONGODB_CONNECTION="mongodb://fabmedical-cdb-mzl:9O2Z1krWoI6PZGwaNszfTPrcjvGkhNhU1sWtqaraPP4WwJuQhQKCVI97oWnw0Y7MlyDzZg8QBGhcqGo3rFeJVw==@fabmedical-cdb-mzl.mongo.cosmos.azure.com:10255/contentdb?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@fabmedical-cdb-mzl@"
