try {
    $ScriptsMainFolder = "C:\Install" # Full path with disk c:\install

    # Create the install folder
    New-Item -ItemType Directory -Path $ScriptsMainFolder



    ############################# Install PowerShell Core
    $PowerShellMsiFilename = "PowerShell-7.4.5-win-x64.msi"
    $PowerShellDownloadURL = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.5/$PowerShellMsiFilename"
    $PowerShellOutFile = "$ScriptsMainFolder\$PowerShellMsiFilename"

    Write-Host "Downloading $PowerShellDownloadURL"
    Invoke-WebRequest -Uri $PowerShellDownloadURL -Method Get -OutFile $PowerShellOutFile
    Write-Host "Downloading PowerShell Core completed."

    Write-Host "Installing PowerShell Core"
    msiexec.exe /l*v powershellinstall.log /quiet /i $PowerShellOutFile ENABLE_MU=0 USE_MU=0 ADD_PATH=1
    Write-Host "Installing PowerShell Core completed."
    ############################# End PowerShell Core

    "1111p2222q3333".Split('pq')
} catch {
    $formatstring = "{0} : {1}`n{2}`n" +
                  "    + CategoryInfo          : {3}`n" +
                  "    + FullyQualifiedErrorId : {4}`n"
    $fields = $_.InvocationInfo.MyCommand.Name,
                $_.ErrorDetails.Message,
                $_.InvocationInfo.PositionMessage,
                $_.CategoryInfo.ToString(),
                $_.FullyQualifiedErrorId
    
    $formatstring -f $fields
    
    Write-Host -Foreground Red -Background Black ($formatstring -f $fields)
}