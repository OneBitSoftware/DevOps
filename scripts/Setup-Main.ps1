param ([Parameter(Mandatory)]$username, [Parameter(Mandatory)]$password)

try {
    $ScriptsMainFolder = "C:\Install" # Full path with disk c:\install

    # Create the install folder
    New-Item -ItemType Directory -Path $ScriptsMainFolder

    ############################# Install PowerShell Core
    .\Install-PowerShellCore.ps1
    ############################# End PowerShell Core

    ############################# Install PsExec
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

    C:\ProgramData\chocolatey\bin\choco.exe install -y sysinternals
    ############################# Install PsExec

    psexec -i -h -u $username -p $password pwsh.exe "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.17\Downloads\0\Test-CreateFolder.ps1 *> test-createFolder.log"
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