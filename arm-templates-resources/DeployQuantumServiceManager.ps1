<#
.SYNOPSIS
Downloads the Quantum Service Manager and deploys it as a Windows service.

.PARAMETER VersionUrl
Specifies the URL of the Quantum Service Manager latest version file. Optional.
#>
param (
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)]

	[string]$VersionUrl = "https://github.com/OneBitSoftware/DevOps/releases/download/QSM-Latest/version.json"
	)

function Install-Service($VersionUrl)
{
	$serviceName = "QuantumSM";

	$QuantumSMInstallationPath = "C:\" + $serviceName
	New-Item -ItemType Directory -Force -Path $QuantumSMInstallationPath 

	$outFile = $QuantumSMInstallationPath + "\Quantum.Service.Manager.exe"
	$quantumCPEService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

	if ($true) {
		Write-Host "- The $serviceName Windows service was not found. Proceeding with registration."

		$localQSMExe = Get-ChildItem -Path $outFile -ErrorAction SilentlyContinue

		if ($null -eq $localQSMExe) {

			Write-Host "- Cannot locate the QuantumSM Windows service executable: $localQSMExe."

			Write-Host "- Get latest version from broadcast URL"
			$latestVersion = Invoke-RestMethod -Uri $VersionUrl
			$latestVersionString = "$($latestVersion.Major).$($latestVersion.Minor).$($latestVersion.Build).$($latestVersion.Revision)"

			Write-Host "- Build the latest version download URL for the EXE file"
			$newVersionUrl = "https://github.com/OneBitSoftware/DevOps/releases/download/QSM-$($latestVersionString)/Quantum.Service.Manager.exe"
			
			Write-Host "- Download the latest exe"
			Invoke-WebRequest -Uri $newVersionUrl -OutFile $outFile
		}

		$localQSMExe = Get-ChildItem -Path $outFile -ErrorAction SilentlyContinue

		try {
			Write-host "- Continuing with service registration..."
			$null = New-Service -Name $serviceName -DisplayName "Quantum Service Manager" -BinaryPathName $localQSMExe.FullName -StartupType Automatic -ErrorAction Stop
		}
		catch {
			Write-Host "- Registering the $serviceName failed. Make sure you are running as an Administrator and re-run this script."
			Write-Host $Error[0].Exception.Message
			Exit 1;
		}

		$quantumCPEService = Get-Service -Name $serviceName
		
		if ($null -ne $quantumCPEService -or $quantumCPEService.Status -eq "Stopped") 
		{
			try { 
				Start-Service $quantumCPEService -ErrorAction Stop
				Write-Host "- The $serviceName Windows service was registered and started."
			}
			catch { 
				Write-Host "- Starting the $serviceName service failed."
				Write-Host $Error[0].Exception.Message
				Exit 1;
			}
		}
	}	
	else {
		Write-Host "- The $serviceName Windows service already exists."
		try { 
			Start-Service $quantumCPEService -ErrorAction Stop
			Write-Host "- The $serviceName Windows service was registered and started."
		}
		catch { 
			Write-Host "- Starting the $serviceName service failed."
			Write-Host $Error[0].Exception.Message
			Exit 1;
		}
		Return $quantumCPEService;
	}
}

function Run-PreConfig()
{
	Write-Host "- Configuring winrm for remote access."
	winrm quickconfig -quiet
}

Run-PreConfig
Install-Service $VersionUrl
