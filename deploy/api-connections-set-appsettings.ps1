<#
# This script will look for ARM output variables
# that provide API runtime URLS and set them as 
# AppSettings in the target Logic App service
# Format of ARM Output: ARM_runtimeUrls_0_office365users
# Format of App Setting: office365users_CONNECTION_RUNTIMEURL
#>
param (
    [string]$resourceGroupName,
    [string]$logicAppName,
    [string]$ARMOutputPrefix = "ARM_runtimeUrls"
)

$envVars = Get-ChildItem Env:
foreach ($var in $envVars) {
    if ($var.Name.StartsWith($ARMOutputPrefix)) {
        $varParts = $var.Name.Split("_")
        $apiConName = $varParts[-1]
        $apiUrl = $var.Value
        az webapp config appsettings set -g $resourceGroupName -n $logicAppName --settings $($apiConName)_CONNECTION_RUNTIMEURL=$apiUrl
    }    
}