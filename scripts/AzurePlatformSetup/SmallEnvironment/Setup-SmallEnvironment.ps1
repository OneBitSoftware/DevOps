
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
if ((Get-Service mongodb).Status -ne "Running") {
    Write-Host "MongoDB is not running as a service. Terminating." -ForegroundColor Red
    Exit 1;
}

# New - Use the MSI to install MongoDB Shell
msiexec.exe /l*v mdbshellinstall.log /quiet /i $mongoDbShellMsiFile INSTALLFOLDER="$MongoDbPath\Tools\" MSIINSTALLPERUSER=0

Remove-Item $mongoDbMsiFile -recurse -force
Remove-Item $mongoDbShellMsiFile -recurse -force

# Update mongo config with replica set settings
$mongoDbInstallLocation = "$MongoDbPath\Server\$MongoMajorVersion"
$mongoDbBinLocation = "$mongoDbInstallLocation\bin\"
$mongoDbConfigPath = "$mongoDbBinLocation\mongod.cfg"

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