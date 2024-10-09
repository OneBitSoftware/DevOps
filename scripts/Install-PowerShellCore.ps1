############################# Install PowerShell Core
$ScriptsMainFolder = "C:\Install" # Full path with disk c:\install
$PowerShellMsiFilename = "PowerShell-7.4.5-win-x64.msi"
$PowerShellDownloadURL = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.5/$PowerShellMsiFilename"
$PowerShellOutFile = "$ScriptsMainFolder\$PowerShellMsiFilename"

Write-Host "Downloading $PowerShellDownloadURL"
Invoke-WebRequest -Uri $PowerShellDownloadURL -Method Get -OutFile $PowerShellOutFile
Write-Host "Downloading PowerShell Core completed."

Write-Host "Installing PowerShell Core"
msiexec.exe /l*v powershellinstall.log /quiet /i $PowerShellOutFile ENABLE_MU=0 USE_MU=0
Write-Host "Installing PowerShell Core completed."
############################# End PowerShell Core