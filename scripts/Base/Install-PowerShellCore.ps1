
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ScriptDownloadFolder,

    [Parameter(Mandatory = $true)]
    [string]$PowerShellCoreVersion
)

$powerShellMsiFilename = "PowerShell-$PowerShellCoreVersion-win-x64.msi"
$powerShellDownloadURL = "https://github.com/PowerShell/PowerShell/releases/download/v$PowerShellCoreVersion/$powerShellMsiFilename"
$powerShellOutFile = "$ScriptDownloadFolder\$powerShellMsiFilename"

Write-Host "Downloading $powerShellDownloadURL"
Invoke-WebRequest -Uri $powerShellDownloadURL -Method Get -OutFile $powerShellOutFile
Write-Host "Downloading PowerShell Core completed."

Write-Host "Installing PowerShell Core $PowerShellCoreVersion"
msiexec.exe /l*v powershellinstall.log /quiet /i $powerShellOutFile ENABLE_MU=0 USE_MU=0 ADD_PATH=1
Write-Host "Installing PowerShell Core $PowerShellCoreVersion completed."
