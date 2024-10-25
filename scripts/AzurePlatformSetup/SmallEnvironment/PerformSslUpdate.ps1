Get-NetFirewallRule -DisplayName "Allow Certbot" | Enable-NetFirewallRule # Allows access through port 80

#Stop-QuantumService -ServiceType ApplicationServer
net stop quantumapp > c:\certbot\debug-certbot.log

(& 'C:\Program Files\Certbot\bin\certbot.exe' renew --non-interactive --force-renewal 2>&1 | out-string) > c:\certbot\debug-certbot.log

Copy-Item -Path "C:\Certbot\live\dms.bld.bg\*" -Destination "E:\QuantumDMSServer\SSL" -Recurse

#Start-QuantumService -ServiceType ApplicationServer
net start quantumapp > c:\certbot\debug-certbot.log

Get-NetFirewallRule -DisplayName "Allow Certbot" | Disable-NetFirewallRule