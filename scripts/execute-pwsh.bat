@echo off
echo Starting PowerShell 7 script execution... >> CC:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.17\Downloads\0\batch-log.txt 2>&1
C:\Program Files\PowerShell\7\pwsh.exe -File C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.17\Downloads\0\Test-CreateFolder.ps1 >> C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.17\Downloads\0\batch-log.txt 2>&1
echo PowerShell 7 script execution finished. >> C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.17\Downloads\0\batch-log.txt 2>&1
