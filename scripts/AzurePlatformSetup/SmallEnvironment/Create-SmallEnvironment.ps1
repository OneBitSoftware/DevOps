<#
.SYNOPSIS
    Creates a small environment in Azure.

.DESCRIPTION
    A PowerShell script that creates a small environment in Azure.

.PARAMETER VmSize
    The unique identifier of the client (app registration).

.PARAMETER AdministratorCredentials
    The credentials of the administrator user.

.OUTPUTS
    On success - the environment is created.
    On failure - an error message indicating what went wrong.

.EXAMPLE
    Create-SmallEnvironment -VmSize $vmSize -AdministratorCredentials $credentials
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Please provide the virtual machine size.")]
    [string]$VmSize,

    [Parameter(Mandatory = $true, HelpMessage = "Please pass a credentials object for the administrator user.")]
    [System.Management.Automation.PSCredential]$AdministratorCredentials
)

############# Environment Settings
$region = "Sweden Central" # swedencentral        
$resourceGroupName = "QuantumDMS-BLD-PROD"

$vmName = "QuantumDMS-VM01"
$vmSize = "Standard_D2_v5"
$vmStorageAccountName = "quantumdms$(Get-Random)" # Must be globally unique 

$virtualNetworkName = "quantumdms-vnet"
$virtualNetworkNicName = "quantumdms-nic"
$virtualNetworkAddressPrefixes = "192.168.0.0/16" # NOT SURE ABOUT THIS
$virtualNetworkSubnetName = "quantumdms-subnet"
$virtualNetworkSubnetPrefix = "192.168.1.0/24"

$nsgName = "quantumdms-nsg"
#$nsgRuleSSHName = "quantumdms-nsg-ssh"
$nsgRuleWebName = "quantumdms-nsg-web"
$nsgRuleAdminName = "quantumdms-nsg-admin"
$nsgRuleRdpName = "quantumdms-nsg-rdp"

$dataDiskName = "quantumdms-disk-data"
$osDiskName = "quantumdms-disk-os"
$dataDiskSize = 64

$publicIpName = "quantumdms-publicip"
$domainNameLabel = "quantumdms-bld"
$publicIPAllocationMethod = "Static"
############# Environment Settings

# Create Resource Group
New-AzResourceGroup -Name $resourceGroupName -Location $region

# Storage account
New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $vmStorageAccountName -Type Standard_LRS -Location $region -Kind StorageV2 -AccessTier Hot

# Create a subnet configuration
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $virtualNetworkSubnetName -AddressPrefix $virtualNetworkSubnetPrefix

# Create a virtual network
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $region -Name $virtualNetworkName -AddressPrefix $virtualNetworkAddressPrefixes -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $region -AllocationMethod $publicIPAllocationMethod -IdleTimeoutInMinutes 4 -Name "$publicIpName$(Get-Random)" -DomainNameLabel $domainNameLabel

# Create an inbound network security group rule for port 443
$nsgRuleWeb = New-AzNetworkSecurityRuleConfig -Name $nsgRuleWebName -Protocol Tcp `
-Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443 -Access Allow

# Create an inbound network security group rule for port 5001
$nsgRuleAdmin = New-AzNetworkSecurityRuleConfig -Name $nsgRuleAdminName -Protocol Tcp `
-Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 5001 -Access Allow

# Create an inbound network security group rule for port 3389
$nsgRuleRdp = New-AzNetworkSecurityRuleConfig -Name $nsgRuleRdpName -Protocol Tcp `
-Direction Inbound -Priority 1003 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

# Create a network security group
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $region -Name $nsgName -SecurityRules $nsgRuleWeb,$nsgRuleAdmin,$nsgRuleRdp

# Create a virtual network card and associate it with public IP address and NSG
$nic = New-AzNetworkInterface -Name $virtualNetworkNicName -ResourceGroupName $resourceGroupName -Location $region -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Virtual Machine
$virtualMachineConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize

Set-AzVMOperatingSystem -VM $virtualMachineConfig -Windows -ComputerName $vmName -Credential $credentials

Set-AzVMSourceImage -VM $virtualMachineConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2022-datacenter-azure-edition-core" -Version "latest"

# Set the operating system disk properties on a VM
$setDiskResult = Set-AzVMOSDisk -VM $virtualMachineConfig -CreateOption FromImage -StorageAccountType StandardSSD_LRS -Name $osDiskName
$setDiskResult | Set-AzVMBootDiagnostic -ResourceGroupName $resourceGroupName -StorageAccountName $vmStorageAccountName -Enable | Add-AzVMNetworkInterface -Id $nic.Id

# Create the VM
New-AzVM -ResourceGroupName $resourceGroupName -Location $region -VM $virtualMachineConfig
$vm = Get-AzVm -ResourceGroupName $resourceGroupName -Name $vmName

# Data disk
$diskConfig = New-AzDiskConfig -Location $region -CreateOption Empty -DiskSizeGB $dataDiskSize -SkuName StandardSSD_LRS
$newDataDisk = New-AzDisk -ResourceGroupName $resourceGroupName -DiskName $dataDiskName -Disk $diskConfig
Add-AzVMDataDisk -VM $vm -Name $dataDiskName -CreateOption Attach -ManagedDiskId $newDataDisk.Id -Lun 1
Update-AzVM -VM $vm -ResourceGroupName $vm.ResourceGroupName
Invoke-AzVMRunCommand -VM $vm -CommandId 'RunPowerShellScript' -ScriptString "Get-disk | where-Object Number -eq '1' | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -UseMaximumSize -DriveLetter E | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'QuantumDMS-Data'"

$command1 = "iwr -Uri `"https://raw.githubusercontent.com/OneBitSoftware/DevOps/refs/heads/main/scripts/Base/Install-PowerShellCore.ps1`" -OutFile `"E:\Install\Install-PowerShellCore.ps1`""
$command2 = "powershell `"E:\Install\Install-PowerShellCore.ps1`" -ScriptDownloadFolder `"E:\Install`" -PowerShellCoreVersion 7.4.5"
$psCommand = "mkdir E:\Install;e:;cd e:\install;powershell -c '$command1';$command2;"
$commandResult = Invoke-AzVMRunCommand -VM $vm -CommandId 'RunPowerShellScript' -ScriptString $psCommand

$ps7Command1 = "C:\Program Files\PowerShell\7\pwsh.exe"
$ps7CommandResult = Invoke-AzVMRunCommand -VM $vm -CommandId 'RunPowerShellScript' -ScriptString $ps7Command1
