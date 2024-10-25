
############################################################ Start Windows Defender Exclusions

Add-MpPreference -ExclusionPath $ElasticInstallPath
Add-MpPreference -ExclusionPath $ElasticDataPath
Add-MpPreference -ExclusionPath $MongoDbPath
Add-MpPreference -ExclusionPath $ClientFolder
Add-MpPreference -ExclusionPath $MainFolder

Set-MpPreference -DisableRealtimeMonitoring $true


# To remove Windows Defender
# Remove-WindowsFeature Windows-Defender, Windows-Defender-GUI
############################################################ End Windows Defender Exclusions


############################################################ MongoDB Start

# MongoDB variables - Download the Community edition
$MongoDbPath = "E:\MongoDB"

$MongoMajorVersion = "7.0" # Used in path
$MongoMinorVersion = "14"
$MongoDbVersion = "$MongoMajorVersion.$MongoMinorVersion"
$MongoMsiFilename = "mongodb-windows-x86_64-$MongoDbVersion-signed.msi"
$MongoDownloadURL = "https://fastdl.mongodb.org/windows/$MongoMsiFilename"
$MongoDbConnectionString = "mongodb://localhost:27017/${CatalogDatabaseName}"
$MongoShellFilename = "mongosh-2.3.2-x64.msi"
$MongoShellDownloadURL = "https://downloads.mongodb.com/compass/$MongoShellFilename"


#Check if mongo is already installed
if ((Test-Path -path $MongoDbPath) -eq $True) 
{ 
    write-host "MongoDB is already installed. Terminating."
	Exit 1;
}

#Create mongo system directories
mkdir $MongoDbPath 

#Download MongoDB Server installation file
$mongoDbMsiFile = "$MongoDbPath\$MongoMsiFilename"
Write-Host "Downloading $MongoDownloadURL"
Invoke-WebRequest -Uri $MongoDownloadURL -Method Get -OutFile $mongoDbMsiFile
Write-Host "Downloading mongo complete."

#Download MongoDB Shell installation file
$mongoDbShellMsiFile = "$MongoDbPath\$MongoShellFilename"
Write-Host "Downloading $MongoShellDownloadURL"
Invoke-WebRequest -Uri $MongoShellDownloadURL -Method Get -OutFile $mongoDbShellMsiFile
Write-Host "Downloading mongo complete."


######## New - Use the MSI to install MongoDB Server
msiexec.exe /l*v mdbinstall.log /qb /i $mongoDbMsiFile INSTALLLOCATION="$MongoDbPath\Server\$MongoMajorVersion\" ADDLOCAL="ServerService"

# Loop and wait for the service to start
$limit = (Get-Date).AddMinutes(5)
while ($null -eq (Get-Service mongodb) -and (Get-Date) -le $limit) {
    Write-Host "Waiting 5 seconds for the mongodb service to start..."
    Start-Sleep -Seconds 5
}
Start-Sleep -Seconds 5
if ((Get-Service mongodb).Status -ne "Running") {
    Write-Host "MongoDB is not running as a service. Terminating." -ForegroundColor Red
    Exit 1;
}

# New - Use the MSI to install MongoDB Tools - Shell
msiexec.exe /l*v mdbshellinstall.log /quiet /i $mongoDbShellMsiFile INSTALLFOLDER="$MongoDbPath\Tools\" MSIINSTALLPERUSER=0

Remove-Item $mongoDbMsiFile -recurse -force
Remove-Item $mongoDbShellMsiFile -recurse -force

# Update mongo config with replica set settings
$mongoDbInstallLocation = "$MongoDbPath\Server\$MongoMajorVersion"
$mongoDbBinLocation = "$mongoDbInstallLocation\bin\"
$mongoDbConfigPath = "$mongoDbBinLocation\mongod.cfg"
cd\cd mon   
#Prepare config data
$MongoConfigContent = @"
# Quantum DMS additions to this flie
replication:
  replSetName: rs0
"@

Add-Content -Path $mongoDbConfigPath -Value $MongoConfigContent
Write-Host "Saved $mongoDbConfigPath"

Get-Service mongodb | Restart-Service

#Initiate replica set
$mongoExe = "$MongoDbPath\Tools\" + "mongosh.exe"
& $mongoExe --quiet --port 27017 --eval "rs.initiate()"
############################################################ MongoDB END


############################################################ Elasticsearch start
$ElasticsearchVersion = "7.17.18"
$ElasticsearchOutFile = "elasticsearch-$($ElasticsearchVersion)-windows-x86_64.zip"
$ElasticsearchMainFolder = "elasticsearch-$($ElasticsearchVersion)"
$ElasticsearchDownloadURL = "https://artifacts.elastic.co/downloads/elasticsearch/$ElasticsearchOutFile"
$ElasticInstallPath = "E:\Elasticsearch" # Will use a subfolder
$ElasticsearchInstallPathWithVersion = "$ElasticInstallPath\$ElasticsearchMainFolder"
$ElasticDataPath = "E:\ElasticsearchData"

#Create root elasticsearch directory
Write-Verbose "Creating root elasticsearch directory" -verbose
New-Item -ItemType Directory -Force -Path $ElasticInstallPath 

#Download installation file
Write-Host "Preparing to download and install Elasticsearch..." -ForegroundColor Cyan
Write-Host "Downloading Elasticsearch" $ElasticsearchDownloadURL
Invoke-WebRequest -Uri $ElasticsearchDownloadURL -Method Get -OutFile $ElasticsearchOutFile

#Unzip installation files
Expand-Archive -LiteralPath $ElasticsearchOutFile -DestinationPath $ElasticInstallPath

Remove-Item $ElasticsearchOutFile

#Create root elasticsearch datadirectory
Write-Verbose "Creating data directory" -verbose
New-Item -ItemType Directory -Force -Path $ElasticDataPath 

$elasticsearchConfigFile = "$ElasticsearchInstallPathWithVersion\config\elasticsearch.yml"

(Get-Content $elasticsearchConfigFile).Replace('#path.data: /path/to/data', "path.data: ${ElasticDataPath}") | Set-Content $elasticsearchConfigFile

#Create the target options file (doesn't work anymore)
$targetOptionsFile = "$ElasticsearchInstallPathWithVersion\config\jvm.options.d\memory.options"
$optionsContent = @"
# This file limits Elasticsearch memory use
-Xms1g
-Xmx1g

"@

New-Item $targetOptionsFile -ItemType File -Value $optionsContent

# Run elasticsearch installation
Write-Host "Installing Elasticsearch as a Windows service..."
& "$ElasticsearchInstallPathWithVersion\bin\elasticsearch-service.bat" install

Get-Service elasticsearch-service-x64 | Set-Service -StartupType AutomaticDelayedStart
# Set delayed start with PowerShell Core due to the new AutomaticDelayedStart parameter
# pwsh.exe -command "Get-Service elasticsearch-service-x64 | Set-Service -StartupType AutomaticDelayedStart"


#Manage elasticsearch as Windows service
Write-Host "Starting Elasticsearch service..."
#& "$ElasticsearchInstallPathWithVersion\bin\elasticsearch-service.bat" manager


#Start elasticsearch as Windows service
Write-Host "Starting Elasticsearch service..."
& "$ElasticsearchInstallPathWithVersion\bin\elasticsearch-service.bat" start


############################################################ Start Install Quantum PowerShell
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Get-PSRepository -Name 'PSGallery'
if ($null -eq (Get-Module -Name Quantum.DMS.PowerShell -ListAvailable))
{
    Write-Host "Installing Quantum.DMS.PowerShell..."
    Install-module Quantum.DMS.PowerShell -AcceptLicense -SkipPublisherCheck
    Write-Host "Installed Quantum.DMS.PowerShell."
}

Write-Host "Importing Quantum.DMS.PowerShell..."
Import-Module Quantum.DMS.PowerShell
Get-Module Quantum.DMS.PowerShell
Write-Host "Imported Quantum.DMS.PowerShell."
############################################################ End  Install Quantum PowerShell

############################################################ Start Azure DevOps Create Environment
$TenantNumber = "BLD01"
$TenantNameShort = "BLD"
$CatalogDatabaseName = "$TenantNumber-Catalog"
$ProjectName = "Quantum.DMS"
$Environment = "Azure"
$AzureDevOpsAccount = "https://onebitsoftware.visualstudio.com"
$AgentName = $env:COMPUTERNAME
$AgentInstallPath = "C:\azagent"
$EnvironmentName = "$TenantNameShort - Azure $TenantNumber - Application Server" # MUST FOLLOW THIS FORMAT as in the YAML '$(TenantNameShort) - $(Environment) $(TenantNumber) - Application Server'
$EnvironmentNameExternalPortal = "$TenantNameShort - Azure $TenantNumber - External Portal"
$ProjectName = "Quantum.DMS"
$AzureDevOpsPipelineFolder = "BLD"
$AzureDevOpsPipelineName = "BLD - Azure - Tenant $TenantNumber"

# Data that doesn't change
$pat = $PersonalAccessToken # DBC Environment Creation Token, expiry 2023-07-20.
$organizationName = "onebitsoftware"
$projectName = $ProjectName
$base64Token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "", $pat)))
$requestAuthenticationHeader = @{Authorization=("Basic {0}" -f $base64Token)}
$environmentApiUri = "https://dev.azure.com/$organizationName/$projectName/_apis/distributedtask/environments?api-version=7.1"
$environmentApiUrlBase = "https://dev.azure.com/$organizationName/$projectName/_apis/distributedtask/environments/"
$permissionApiUri = "https://dev.azure.com/$organizationName/$projectName/_apis/pipelines/pipelinePermissions/environment/"
$buildApiUrl = "https://dev.azure.com/$organizationName/$projectName/_apis/build/definitions/"
$pipelinesApiUrl = "https://dev.azure.com/$organizationName/$projectName/_apis/pipelines?api-version=7.1"
$repositoryName = $projectName
$repositoryId = "2abe1c8c-bb48-48b7-a457-ed27c00906f1"
$devBranchPipelineId = 16

$body = @{
    name = $EnvironmentName
    description = $EnvironmentName
}
## Create the environment
$requestBodyJson = $body | ConvertTo-Json
try {
    $requestResult = Invoke-RestMethod -Uri $environmentApiUri -Body $requestBodyJson -ContentType "application/json" -headers $requestAuthenticationHeader -Method POST -ErrorAction Stop
    $environmentId = $requestResult.id;
    Write-Host "Created environment $EnvironmentName with Id: $environmentId" -ForegroundColor Green
}
catch {
    if($_.ErrorDetails.Message){
        Write-Error "Inner Error: $_.ErrorDetails.Message"
    }
    else {
        Write-Error $_.Exception
    }
    Exit 1;
}
############################################################ End Azure DevOps Create Environment

############################################################ Get Environment Id
# We use this if scripts are partially executed, and also in the External Portal
$environmentByNameUrl = $environmentApiUrlBase + "?name=" + $EnvironmentName
$environmentResult = Invoke-RestMethod -Uri $environmentByNameUrl -headers $requestAuthenticationHeader -Method GET
$environmentResult.value
$environmentId = $environmentResult.value.id
############################################################ End Get Environment Id

############################################################ Create the Azure DevOps pipeline

$AdministrationServerApiUrl = "https://quantumdms-bld.swedencentral.cloudapp.azure.com:5001"
$ApplicationServerApiUrl = "https://quantumdms-bld.swedencentral.cloudapp.azure.com"
$MainFolder = "E:\QuantumDMSServer"
$ApplicationServerPath = "$MainFolder\Release\ApplicationServer"
$ExternalPortalServerPath = "$MainFolder\Release\ExternalPortal"
$AdministrationServerPath = "$MainFolder\Release\AdministrationServer"
$BackgroundTasksPath = "$MainFolder\Release\BackgroundTasks"
$ScheduledTasksPath = "$MainFolder\Release\ScheduledTasks"
$ApplicationServerExePath = "$ApplicationServerPath\Quantum.DMS.ApplicationServer.exe"
$AdministrationServerExePath = "$AdministrationServerPath\Quantum.DMS.API.Administrative.Server.exe"
$BackgroundTasksExePath = "$BackgroundTasksPath\Quantum.DMS.BackgroundTasks.exe"
$ScheduledTasksExePath = "$ScheduledTasksPath\Quantum.DMS.ScheduledTasks.exe"
$ExternalPortalExePath = "$ExternalPortalServerPath\Quantum.DMS.ExternalPortal.exe"
$ClientFolder = "E:\QuantumDMSClient"

# RabbitMQ variables
$RabbitMQHostname = "hostname"
$RabbitMQMode = "Disabled"
$RabbitMQPassword = ""
$RabbitMQUsername = ""
$RabbitMQVirtualHost = "009"

try {
    $pipelineBody = @{
        folder = $AzureDevOpsPipelineFolder
        name = $AzureDevOpsPipelineName
        configuration = @{
            type = "yaml"
            path = "/pipelines/onebit/Base-Environment.yml"
            repository = @{
                id = $repositoryId
                name = $repositoryName
                type= "azureReposGit"
            }
        }
    }
    $pipelinesApiUrl = "https://dev.azure.com/$organizationName/$projectName/_apis/pipelines?api-version=7.1"
    $pipelineBodyJson = $pipelineBody | ConvertTo-Json -Depth 99
    $pipelineRequest = Invoke-RestMethod -Uri $pipelinesApiUrl -Body $pipelineBodyJson -ContentType "application/json" -headers $requestAuthenticationHeader -Method POST
    Write-Host "Created pipeline with Id:" $pipelineRequest.id -ForegroundColor Green
    $pipelineId = $pipelineRequest.id

## Create the persmissions for the environment and pipeline
    $permissionsBody = 
        @{
            allPipelines = @{
                authorized = $false
                authorizedBy = $null
                authorizedOn = $null
            }
            pipelines = @(
                @{
                    id = $pipelineRequest.id
                    authorized = $true
                }
            )
        }

    $requestPermissionJson =  ConvertTo-Json -InputObject $permissionsBody -Depth 99
    $requstPermissionsEndUri = $permissionApiUri + $environmentId + "?api-version=7.1-preview.1"
    $requestPermissionResult = Invoke-RestMethod -Uri $requstPermissionsEndUri -Body $requestPermissionJson -ContentType "application/json" -headers $requestAuthenticationHeader -Method PATCH
    Write-Host "Added pipeline permissions to environment." -ForegroundColor Green

## Create the pipeline variables
    $pipelineVariableData = [pscustomobject]@{
        "TenantNumber" = @{
            "value" = $TenantNumber
            "allowOverride" = $true
        }
        "TenantNameShort" = @{
            "value" = $TenantNameShort
            "allowOverride" = $true
        }
        "Kestrel.Endpoints.AdministrationWebServer.Url" = @{
            "value" = $AdministrationServerApiUrl
            "allowOverride" = $true
        }
        "Kestrel.Endpoints.ApplicationWebServer.Url" = @{
            "value" = $ApplicationServerApiUrl
            "allowOverride" = $true
        }
        "Database.CatalogConnectionString" = @{
            "value" = $MongoDbConnectionString
            "allowOverride" = $true
        }
        "Logging.LogLevel.Default" = @{
            "value" = "Information"
            "allowOverride" = $true
        }
        "Logging.LogLevel.Microsoft" = @{
            "value" = "Information"
            "allowOverride" = $true
        }
        "Quantum.AdministrationServerFolder" = @{
            "value" = $AdministrationServerPath
            "allowOverride" = $true
        }
        "Quantum.ApplicationServerFolder" = @{
            "value" = $ApplicationServerPath
            "allowOverride" = $true
        }
        "Quantum.BackgroundTasksFolder" = @{
            "value" = $BackgroundTasksPath
            "allowOverride" = $true
        }
        "Quantum.ClientFolder" = @{
            "value" = $ClientFolder
            "allowOverride" = $true
        }
        "Quantum.ScheduledTasksFolder" = @{
            "value" = $ScheduledTasksPath
            "allowOverride" = $true
        }
        "Quantum.ExternalPortalFolder" = @{
            "value" = $ExternalPortalServerPath
            "allowOverride" = $true
        }
        "RabbitMQ.Hostname" = @{
            "value" = $RabbitMQHostname
            "allowOverride" = $true
        }
        "RabbitMQ.Mode" = @{
            "value" = $RabbitMQMode
            "allowOverride" = $true
        }
        "RabbitMQ.Password" = @{
            "value" = $RabbitMQPassword
            "allowOverride" = $true
        }
        "RabbitMQ.Username" = @{
            "value" = $RabbitMQUsername
            "allowOverride" = $true
        }
        "RabbitMQ.VirtualHost" = @{
            "value" = $RabbitMQVirtualHost
            "allowOverride" = $true
        }
        "ReverseProxy.Clusters.Quantum.Destinations.API.Address" = @{
            "value" = "[ ""$ApplicationServerApiUrl"" ]"
            "allowOverride" = $true
        }
        # "Kestrel.Endpoints.Https.Url" = @{
        #     "value" = $ExternalPortalPublicUrl
        #     "allowOverride" = $true
        # }
        # "Kestrel.Endpoints.Https.Certificate.Subject" = @{
        #     "value" = $ExternalPortalCertificateSubject
        #     "allowOverride" = $true
        # }
        # "Kestrel.Endpoints.Https.Certificate.Store" = @{
        #     "value" = $ExternalPortalCertificateStore
        #     "allowOverride" = $true
        # }
        # "Kestrel.Endpoints.Https.Certificate.Location" = @{
        #     "value" = $ExternalPortalCertificateLocation
        #     "allowOverride" = $true
        # }
        "Cors.AllowedOrigins" = @{
            "value" = "[ ""$ExternalPortalPublicUrl"" ]"
            "allowOverride" = $true
        }
        "AuthTokenGeneration.Audience" = @{
            "value" = $ApplicationServerApiUrl
            "allowOverride" = $true
        }
        "AuthTokenGeneration.Issuer" = @{
            "value" = $ApplicationServerApiUrl
            "allowOverride" = $true
        }
        "AuthTokenGeneration.Audiences" = @{
            "value" = "[ ""$ApplicationServerApiUrl"" ]"
            "allowOverride" = $true
        }
        "AuthTokenGeneration.Issuers" = @{
            "value" = "[ ""$ApplicationServerApiUrl"" ]"
            "allowOverride" = $true
        }
        "DeployApplicationServer" = @{
            "value" = $true
            "allowOverride" = $true
        }
        "DeployExternalPortal" = @{
            "value" = $false
            "allowOverride" = $true
        }
        "Environment" = @{
            "value" = $Environment
            "allowOverride" = $true
        }
        # Kestrel.Endpoints.ApplicationWebServer.Certificate.Path = C:\QuantumDMSServer\SSL\fullchain.pem
        # Kestrel.Endpoints.ApplicationWebServer.Certificate.KeyPath = C:\QuantumDMSServer\SSL\privkey.pem
        # AllowBasicAuthentication
        # AllowWindowsAuthentication
    }
    
    $buildApiEndUrl = $buildApiUrl+ $pipelineId + "?api-version=7.1"
    $getPipelineDefinitionResult = Invoke-RestMethod -Uri $buildApiEndUrl -ContentType "application/json" -headers $requestAuthenticationHeader -Method GET
    $getPipelineDefinitionResult | Add-Member -MemberType NoteProperty -Name variables -Value $pipelineVariableData -Force
    $updatePipelineJson =  ConvertTo-Json -InputObject $getPipelineDefinitionResult -Depth 99
    $updatePipelineDefinitionResult = Invoke-RestMethod -Uri $buildApiEndUrl -Body $updatePipelineJson -ContentType "application/json" -headers $requestAuthenticationHeader -Method PUT
    Write-Host "Updated pipeline with appropriate variables." -ForegroundColor Green
}
catch {
    if($_.ErrorDetails.Message){
        Write-Error "Inner Error: $_.ErrorDetails.Message"
    }
    else {
        Write-Error $_.Exception
    }

    $environmentApiUrlBase = "https://dev.azure.com/$organizationName/$projectName/_apis/distributedtask/environments/"
    Invoke-RestMethod -Uri "$environmentApiUrlBase$environmentId\?api-version=7.1-preview.1" -headers $requestAuthenticationHeader -Method DELETE
    Write-Host "The created environment $environmentId was removed due to a script error." -ForegroundColor Yellow
    Exit 1;
}
############################################################ Finished the Azure DevOps pipeline

############################################################ Certbot
# Setup certificate renewal
## Read command line params: https://eff-certbot.readthedocs.io/en/latest/using.html#certbot-command-line-options
## Get certbot https://github.com/certbot/certbot/releases/latest/download/certbot-beta-installer-win_amd64_signed.exe
## Install it.
## Open port 80
## Create a file in C:\Certbot\renewal-hooks\deploy called CopyForDotNet.bat with the contents:
# copy C:\Certbot\live\quantumdms-capasca.germanywestcentral.cloudapp.azure.com c:\QuantumDMSServer\SSL
## Run certbot certonly --standalone and check the results

# PS C:\Certbot>  certbot certonly --standalone
# Saving debug log to C:\Certbot\log\letsencrypt.log
# Please enter the domain name(s) you would like on your certificate (comma and/or
# space separated) (Enter 'c' to cancel): quantumdms-capasca.germanywestcentral.cloudapp.azure.com
# Requesting a certificate for quantumdms-capasca.germanywestcentral.cloudapp.azure.com

# Successfully received certificate.
# Certificate is saved at: C:\Certbot\live\quantumdms-capasca.germanywestcentral.cloudapp.azure.com\fullchain.pem
# Key is saved at:         C:\Certbot\live\quantumdms-capasca.germanywestcentral.cloudapp.azure.com\privkey.pem
# This certificate expires on 2024-05-31.
# These files will be updated when the certificate renews.
# Certbot has set up a scheduled task to automatically renew this certificate in the background.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# If you like Certbot, please consider supporting our work by:
#  * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
#  * Donating to EFF:                    https://eff.org/donate-le
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# PS C:\Certbot>

Invoke-WebRequest -Uri "https://github.com/certbot/certbot/releases/download/v2.9.0/certbot-beta-installer-win_amd64_signed.exe" -OutFile E:\Install\certbot-beta-installer-win_amd64_signed.exe

& E:\Install\certbot-beta-installer-win_amd64_signed.exe /S

# For this to work, the domain DNS settings must work. in my case, this was not ready.
# For an *.cloudapp.azure.com domain - this would be OK.
& "C:\Program Files\Certbot\bin\certbot.exe" certonly --standalone --email office@onebitsoftware.net -d dms.bld.bg --agree-tos --no-eff-email
# after successful execution of the above line, the C:\Certbot folder will be created

# This only works when port 80 is open in Windows Firewall AND in Azure, the network security group
New-NetFirewallRule -DisplayName "Allow Certbot" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -Enabled False

Get-NetFirewallRule -DisplayName "Allow Certbot" | Enable-NetFirewallRule

# See the triggered action
Get-ScheduledTask -TaskName "Certbot Renew Task"
$task = Get-ScheduledTask -TaskName "Certbot Renew Task"
$action = $task.Actions[0]
#$action.Arguments = "-NoExit -Command `"& 'C:\Program Files\Certbot\bin\certbot.exe' renew --non-interactive --force-renewal`" > c:\certbot\ps.log"
$action.Arguments = "-WindowStyle Hidden -File E:\Install\PerformSslUpdate.ps1"
Set-ScheduledTask -TaskName "Certbot Renew Task" -Action $action 
Get-ScheduledTask -TaskName "Certbot Renew Task" | Start-ScheduledTask

# Get-NetFirewallRule -DisplayName "Allow Certbot" | Remove-NetFirewallRule

# Create the SSL folder
New-Item -ItemType Directory -Force -Path E:\QuantumDMSServer\SSL

# Create the file to copy
New-Item "C:\Certbot\renewal-hooks\deploy\CopyForDotNet.bat" -ItemType File -Value "copy C:\Certbot\live\dms.bld.bg c:\QuantumDMSServer\SSL"

Get-NetFirewallRule -DisplayName "Allow Certbot" | Enable-NetFirewallRule
Get-NetFirewallRule -DisplayName "Allow Certbot" | Disable-NetFirewallRule
