[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]$AzureDevOpsAccount,
    [Parameter(Mandatory = $true)]$PersonalAccessToken,
    [Parameter(Mandatory = $true)]$AgentName,
    [Parameter(Mandatory = $true)]$PoolName,
    [Parameter(Mandatory = $true)]$runAsAutoLogon,
    [Parameter(Mandatory = $false)]$vmAdminUserName,
    [Parameter(Mandatory = $false)]$vmAdminPassword
)

Invoke-WebRequest -Uri https://raw.githubusercontent.com/OneBitSoftware/DevOps/azure/devops-agent/arm-templates-resources/InstallDevOpsAgent.ps1 -OutFile C:\Windows\Temp\InstallDevOpsAgent.ps1;
& "C:\Windows\Temp\InstallDevOpsAgent.ps1" -AzureDevOpsAccount $AzureDevOpsAccount, -PersonalAccessToken $PersonalAccessToken, -AgentName $AgentName, -PoolName $PoolName, -runAsAutoLogon $runAsAutoLogon, -vmAdminUserName $vmAdminUserName, -vmAdminPassword $vmAdminPassword

Invoke-WebRequest -Uri https://raw.githubusercontent.com/OneBitSoftware/DevOps/azure/devops-agent/arm-templates-resources/DeployQuantumServiceManager.ps1 -OutFile C:\Windows\Temp\DeployQuantumServiceManager.ps1;
& "C:\Windows\Temp\DeployQuantumServiceManager.ps1"

