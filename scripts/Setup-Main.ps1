try {
    $ScriptsMainFolder = "C:\Install" # Full path with disk c:\install

    # Create the install folder
    New-Item -ItemType Directory -Path $ScriptsMainFolder

    ############################# Install PowerShell Core
    .\Install-PowerShellCore.ps1
    ############################# End PowerShell Core

    ############################# Execute custom PowerShell Core command
    Invoke-Command { & "pwsh.exe" } -NoNewScope
    pwsh Test-CreateFolder.ps1 
    ############################# End execute custom PowerShell Core command
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