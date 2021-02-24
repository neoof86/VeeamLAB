# USERDATA SCRIPT FOR AMAZON SOURCE WINDOWS SERVER AMIS
# BOOTSTRAPS WINRM VIA SSL
 
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore
$ErrorActionPreference = "stop"
 
# Remove any existing Windows Management listeners
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse
 
# Create self-signed cert for encrypted WinRM on port 5986
$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "packer-ami-builder"
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force
 
# Configure WinRM
#cmd.exe /c winrm set "winrm/config" '@{MaxTimeoutms="1800000"}'
#cmd.exe /c winrm set "winrm/config/winrs" '@{MaxMemoryPerShellMB="1024"}'
#cmd.exe /c winrm set "winrm/config/service" '@{AllowUnencrypted="false"}'
#cmd.exe /c winrm set "winrm/config/client" '@{AllowUnencrypted="false"}'
#cmd.exe /c winrm set "winrm/config/service/auth" '@{Basic="true"}'
#cmd.exe /c winrm set "winrm/config/client/auth" '@{Basic="true"}'
#cmd.exe /c winrm set "winrm/config/service/auth" '@{CredSSP="true"}'
#cmd.exe /c winrm set "winrm/config/listener?Address=*+Transport=HTTPS" "@{Port=`"5986`";Hostname=`"packer-ami-builder`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"
#cmd.exe /c netsh advfirewall firewall add rule name="WinRM-SSL (5986)" dir=in action=allow protocol=TCP localport=5986

Write-Output "Configuring Powershell Remoting"
cmd.exe /c net user winrm 'Letmein12!' /add /y
cmd.exe /c localgroup administrators winrm /add
# Configure WinRM
cmd.exe /c winrm quickconfig -q
cmd.exe /c winrm set "winrm/config" '@{MaxTimeoutms="1800000"}'
cmd.exe /c winrm set "winrm/config/winrs" '@{MaxMemoryPerShellMB="1024"}'
cmd.exe /c winrm set winrm/config/service '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set winrm/config/service/auth '@{Basic="true"}'
cmd.exe /c winrm set "winrm/config/listener?Address=*+Transport=HTTPS" "@{Port=`"5986`";Hostname=`"packer-ami-builder`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"
cmd.exe /c netsh advfirewall firewall add rule name="WinRM-SSL (5986)" dir=in action=allow protocol=TCP localport=5986
cmd.exe /c net stop winrm
cmd.exe /c sc config winrm start= auto
cmd.exe /c net start winrm

#winrm quickconfig -q

#winrm set winrm/config/service/auth '@{Basic="true"}'
#winrm set winrm/config/service '@{AllowUnencrypted="true"}'
#Set-Item -Force wsman:\localhost\client\trustedhosts *
#netsh advfirewall firewall add rule name="Open Port 5985" dir=in action=allow protocol=TCP localport=5985

#Set-Service -Name 'WinRM' -StartupType Automatic
#Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\WinRM' -Name 'DelayedAutoStart' -Value 0
cmd.exe /c netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
cmd.exe /c netsh advfirewall firewall add rule name="WinRM 5985" protocol=TCP dir=in localport=5985 action=allow
cmd.exe /c netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
#cmd.exe /c net stop winrm
#cmd.exe /c sc config winrm start= auto
#cmd.exe /c net start winrm

New-Item -Path "c:\" -Name "logfiles" -ItemType "directory"

#Set Windows Firewall to OFF
set-NetFirewallProfile -All -Enabled False

#Create User and Add to Local Administrator Group
$password = ConvertTo-SecureString 'Veeam1!' -AsPlainText -Force
new-localuser -Name autodeploy -Password $password
add-localgroupmember -Group administrators -Member autodeploy

Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
Get-Service sshd | Set-Service -StartupType Automatic
Start-Service sshd
