# logic-apps-std-pipelines
A repo with sample standard logic app with ci and cd pipelines

## Handling Managed API Connections
Adding support for Managed API Connections to our CI and CD pipelines involves multiple pieces.  There are various related files in the deploy folder as well as the CI and CD yml pipelines in the pipelines folder. Below is some information about each file.

1. deploy/api-connnections.bicep
   - This is a bicep file that can create API Connections and related Access Policies. 
   - This will be run during the CD pipeline to create the needed API connections in the target resource groups as needed.  
   - The access policy grants permissions for the Logic App to use the API Connection.
   - The outputs of running the bicep file (defined at the bottom of the file) are the runtime urls of the API connections which will then be supplied to the logic app via App Settings during the CD pipeline.  (We’ll discuss more below.)
   - The file is a generic template with looping capability so what exactly it creates is determined by the parameters that are passed in. (See next file.) 
1. deploy/api-connections-bicep.parameters.json
   - This is the parameters file for the above bicep file.  The format is JSON.  The values in mine are example values.  
   - You technically don’t need this file as it will get generated automatically by a powershell script (#3 below) but it’s helpful to see an example of what will get generated.  
   - Other values needed by the bicep script will be provided directly from the CD pipeline.
1. deploy/api-connections-bicep-generator.ps1
   - This is a powershell script that reads the connections.json file of the Logic App and creates the parameters file (#2 above) to feed into the bicep script (#1 above).
   - This will ensure that when the CD pipeline runs it will create API Connections that match what is defined in the connections.json file.
   - This runs during the CI pipeline since it isn’t environment specific.
1. deploy/api-connections-parameterize-json.ps1
   - This is a powershell script that replaces hardcoded values in your local connections.json file with appsettings references.  Appsettings are a key/value store on the Logic App.  In this way we can deploy the same connections.json file to multiple logic apps and then just change their respective appsettings to have environment specific values.
   - We run this script during the CI step to put in the appsettings references.
   - We supply the actual environment specific appsettings values during the CD stages.
1. deploy/api-connections-set-appsettings.ps1
   - This is a powershell script run during the CD pipeline that takes the output of the bicep file (the runtime urls) and puts their values in the app settings of the target logic app.
1. pipelines/ci-pipeline.yml
   
   CI pipeline which:
      - Runs the script in #3 to generate parameter file for the bicep template
      - Runs the script in #4 to parameterize the connections.json file
      - Zips up the logic app for later deployment in CD
      - Copies the bicep file and the related parameters file to be run during CD
      - Copies the script in #5 to be run during CD
      - Publishes the three items above back to Azure DevOps so they can be retrieved later by the CD pipeline
1. pipelines/cd-pipeline.yml
   
   CD pipeline which:
      - Defines a bunch of variables
         - You’ll see APIUrl which you don’t need.  It’s one I use in my test Logic App.
      - In each of the Test and Prod stages
         - Run the bicep file with associated parameters file with the AzureResourceManagerTemplateDeployment task.
            - Also pass in the System Assigned Identity Object Id for the appropriate logic app.  This can be retrieved from the Identity blade of the logic app.
            - In the future we could also use bicep to deploy the Logic App itself and then that value can be passed along instead of you looking it up ahead of time.
               - The bicep for this is in the repo but not being run by the pipeline at the moment.
         - Retrieve the output from the api connections bicep file and turn them into Azure DevOps variables with the ARM Outputs task.
         - Deploy the Logic App with the AzureFunctionApp task.
            - Also setting various AppSettings
         - Run the api-connections-set-appsettings.ps1 script to read arm template outputs and pass as AppSettings to the logic app.  This runs using the AzureCLI task which allows authentication to happen using the already existing Service Connection.