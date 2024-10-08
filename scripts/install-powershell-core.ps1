$ScriptsMainFolder = "C:\Install" # Full path with disk c:\install


# Create the install folder
New-Item -ItemType Directory -Path "C:\Install"

############################# Install PowerShell Core
$PowerShellMsiFilename = "PowerShell-7.4.1-win-x64.msi"
$PowerShellDownloadURL = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/$PowerShellMsiFilename"
$PowerShellOutFile = "$ScriptsMainFolder\$PowerShellMsiFilename"

Write-Host "Downloading $PowerShellDownloadURL"
Invoke-WebRequest -Uri $PowerShellDownloadURL -Method Get -OutFile $PowerShellOutFile
Write-Host "Downloading PowerShell Core completed."

Write-Host "Installing PowerShell Core"
msiexec.exe /l*v powershellinstall.log /quiet /i $PowerShellOutFile ENABLE_MU=0 USE_MU=0
Write-Host "Installing PowerShell Core completed."
############################# End PowerShell Core