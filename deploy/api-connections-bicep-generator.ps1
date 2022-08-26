<#
# This script will read the Managed API's in a Logic Apps Connection file and generate the json that is 
# placed in a ARM template parameters file which is in turn used by the api-connections.bicep file
# when run in the CD pipeline.
# Provide the path to the input connections.json file and the path for the output parameters file.
#>
param (
    [string]$connectionsFilePath,
    [string]$parametersFilePath
)

$parametersFileJson = @"
{
    "`$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "apiConnectionSettings": {
            "value": []
        }
    }
}
"@
$parametersFileObj = ConvertFrom-Json -InputObject $parametersFileJson

$connectionsObj = Get-Content $connectionsFilePath | ConvertFrom-Json
$mApiCons = $connectionsObj.managedApiConnections

foreach ($mApiCon in Get-Member -InputObject $mApiCons -membertype noteproperty)
{
    $name = $mApiCon.Name
    $apiId = $mApiCons.$name.api.id
    $connectorName = $apiId.Split("/")[-1]
    $displayName = $name
    
    $newSettingJson = @"
{                    
    "name": "$name",
    "connectorName": "$connectorName",
    "displayName": "$displayName"
}
"@
    $newSettingObj = ConvertFrom-Json -InputObject $newSettingJson
    $parametersFileObj.parameters.apiConnectionSettings.value += $newSettingObj
}

$parametersFileObj | ConvertTo-Json -Depth 10 | Out-File $parametersFilePath