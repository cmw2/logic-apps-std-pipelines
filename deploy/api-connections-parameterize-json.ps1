<#
# This script will parameterize various settings in the Logic Apps Connection file
#>
param (
    [string]$inputConnectionsFilePath,
    [string]$outputConnectionsFilePath
)

if ([string]::IsNullOrEmpty($outputConnectionsFilePath)) {
    $outputConnectionsFilePath = $inputConnectionsFilePath
}

$connectionsObj = Get-Content $inputConnectionsFilePath | ConvertFrom-Json
$mApiCons = $connectionsObj.managedApiConnections

$newAuthJson = @"
{                    
    "type":"object",
    "value":{
        "type":"ManagedServiceIdentity"
    }
}
"@


foreach ($mApiCon in Get-Member -InputObject $mApiCons -membertype noteproperty)
{
    $name = $mApiCon.Name

    $apiId = $mApiCons.$name.api.id
    $apiParts = $apiId.Split("/")
    $apiParts[2] = "@appsetting('WORKFLOWS_SUBSCRIPTION_ID')"
    $apiParts[6] = "@appsetting('WORKFLOWS_LOCATION_NAME')"
    $mApiCons.$name.api.id = $apiParts -Join "/"
    
    $connectionId = $mApiCons.$name.connection.id
    $connectionParts = $connectionId.Split("/")
    $connectionParts[2] = "@appsetting('WORKFLOWS_SUBSCRIPTION_ID')"
    $connectionParts[4] = "@appsetting('WORKFLOWS_RESOURCE_GROUP_NAME')"
    $mApiCons.$name.connection.id = $connectionParts -Join "/"
    
    $newAuthObj = ConvertFrom-Json -InputObject $newAuthJson
    $mApiCons.$name.authentication = $newAuthObj

    $mApiCons.$name.connectionRuntimeUrl = "@appsetting('$($name)_CONNECTION_RUNTIMEURL')"    
}

$connectionsObj | ConvertTo-Json -Depth 10 | Out-File $outputConnectionsFilePath