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
    [string]$ARMOutputPrefix = "ARM_RUNTIMEURLS"
)

$envVars = Get-ChildItem Env:
foreach ($var in $envVars) {
    #Write-Host "Checking $($var.Name)"
    if ($var.Name.StartsWith($ARMOutputPrefix)) {
        Write-Host "Processing $($var.Name)"
        $varParts = $var.Name.Split("_")
        $apiConName = $varParts[-1]
        $apiUrl = $var.Value
        #Write-Host "Setting appsetting $($apiConName)_CONNECTION_RUNTIMEURL=""$apiUrl"""
        Write-Host "az webapp config appsettings set -g $resourceGroupName -n $logicAppName --settings ""$($apiConName)_CONNECTION_RUNTIMEURL=$apiUrl"""
        az webapp config appsettings set -g $resourceGroupName -n $logicAppName --settings "$($apiConName)_CONNECTION_RUNTIMEURL=$apiUrl"
    }    
}