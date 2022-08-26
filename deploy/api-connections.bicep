param location string = resourceGroup().location
param logicAppIdentityObjectId string
param apiConnectionSettings array

resource apiConnections 'Microsoft.Web/connections@2016-06-01' = [for (apiCon, i) in apiConnectionSettings: {
  name: apiCon.name
  location: location
  kind: 'V2'
  properties: {
    displayName: apiCon.displayName
    api: {
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/${apiCon.connectorName}'
    }
  }
}]

resource apiConnectionAPs 'Microsoft.Web/connections/accessPolicies@2016-06-01' = [for (apiCon, i) in apiConnectionSettings: {
  name: '${apiCon.name}/${logicAppIdentityObjectId}'
  location: location
  dependsOn: [apiConnections[i]]
  properties: {
    principal: {
      type: 'ActiveDirectory'
      identity: {
        tenantId: subscription().tenantId
        objectId: logicAppIdentityObjectId
      }
    }    
  }
}]

output runtimeUrls array = [for (apiCon, i) in apiConnectionSettings: {
  '${apiCon.name}': apiConnections[i].properties.connectionRuntimeUrl
}]

