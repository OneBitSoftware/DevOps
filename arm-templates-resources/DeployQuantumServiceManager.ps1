<#
.SYNOPSIS
Downloads the Quantum Service Manager and deploys it as a Windows service.

.PARAMETER DownloadUrl
Specifies the URL of the Quantum Service Manager download file. Optional.
#>
param (
    [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelinebyPropertyName=$true)]
    [string]$DownloadUrl = "https://github.com/OneBitSoftware/DevOps/releases/download/QSM-1.0.104.20870/Quantum.Service.Manager.exe"
	)

function Install-Service($downloadUrl)
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
			Write-Host "- Cannot locate the QuantumSM Windows service executable: $localQSMExe. Downloading it to the current folder."
			Invoke-WebRequest -Uri $downloadUrl -OutFile $outFile
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

				#Temporary test issue fix - start
				Write-Host "- Start sleep mode for 2 minutes"
				Get-Date; Start-Sleep -Seconds 120; Get-Date
				Write-Host "- End sleep mode"

				if ($quantumCPEService.Status -eq "Running") {
					try { 
						Write-Host "- The $serviceName Windows service is running. Attempting to stop it."
						Stop-Service $quantumCPEService -ErrorAction Stop -Confirm
					}
					catch { 
						Write-Host "- Stopping the $serviceName service failed. Run this script with elevated administrator privileges or stop it manually and run this script again."
						Write-Host $Error[0].Exception.Message
						Exit 1;
					}
				}

				if ($quantumCPEService.Status -eq "Stopped") {
					try { 
						Write-Host "- The $serviceName Windows service will now start."
						Start-Service $quantumCPEService -ErrorAction Stop -Confirm
					}
					catch { 
						Write-Host "- Starting the $serviceName service failed. Run this script with elevated administrator privileges or start it manually."
						Write-Host $Error[0].Exception.Message
						Exit 1;
					}
				}
				#Temporary test issue fix - end
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

function Run-QuickConfingWinRM()
{
	Write-Host "- Configuring winrm for remote access."
	winrm quickconfig -quiet
}

Run-QuickConfingWinRM
Install-Service $DownloadUrl
