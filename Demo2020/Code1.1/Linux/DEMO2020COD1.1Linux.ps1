###
#
# This script consists of 3 section, separate through todo comments:
#
# 0. Dependencies
# Section with links to download all needed dependencies
#
# 1. Init
# This block describes all the necessary constants and variables
#
# 2. Main functions
# Function block in which all necessary functions are defined
#
# 3. Start of check
# The verification process itself
#
###

# TODO: 0. Dependencies

# 1. Run powershell as Administrator
#
# 2. Copy and Paste the following script to install this package
# Install-Module -Name VMware.PowerCLI -Force
#
# OR
#
# https://code.vmware.com/web/tool/11.5.0/vmware-powercli

# TODO: 1. Init

$LOGIN_ESXi         = 'root'            # ESXi login
$PASS_ESXi          = 'P@ssw0rd'        # ESXi password
$LOGIN_VM           = 'root'            # VM Login
$PASS_VM            = 'toor'            # VM Password
$DELAY              = 0                 # Delay before start VM

# TODO: 2. Main functions

# Function for send Script to VM
# Return a Script output from VM, if all ok
#
# Use: SendScript -VM 'L-SRV' -Script 'hostnamectl' -Description 'Hostname'
Function SendScript
{
  Param( $VM,
         $Script,
         $Description,
         $Username,
         $Password )
 If ($null -ne $Description)
 {
   Write-Output "#########################--=$Description=--#########################" `
   | Out-File $FILE -Append -NoClobber
 }
 Write-Output "Script	     : $Script" | Out-File $FILE -Append -NoClobber
 If ( ($null -eq $Username) -or ($null -eq $Password) )
 {
   $Username = $LOGIN_VM
   $Password = $PASS_VM
 }
 else {
   Write-Output "Username     : $Username" | Out-File $FILE -Append -NoClobber
   Write-Output "Password     : $Password" | Out-File $FILE -Append -NoClobber
 }
  Invoke-VMScript   -vm $VM                                   `
                    -ScriptText $Script                       `
                    -GuestUser $Username                      `
                    -GuestPassword $Password                  `
                    -ScriptType Bash                          `
                    | Format-List -Property VM,ScriptOutput   `
                    | Out-File $FILE -Append -NoClobber

}

# Function for validate ip address
# Return True or False
#
# Use: isIP '1.1.1.1'
#
# OR
#
# Use: isIP $AnyIpAddress
Function isIP
{
  Param( [string]$ip )
  If ( $ip -match '^\d{0,3}.\d{0,3}.\d{0,3}.\d{0,3}$' )
  {
    return $True
  }
  else
  {
    return $False
  }
}

# TODO: 3. Start of check

# Set STAND_NUMBER
If ( $args[0] -is [int] )
{
  $STAND = $args[0]
}
else
{
  Do
  {
    $STAND = Read-Host "Stand number"
  } until ( $STAND -is [int] -eq $False )
}

# Set COMPETITOR
If ( $args[1] -is [string] )
{
  $COMPETITOR = $args[1]
}
else
{
  Do
  {
    $COMPETITOR = Read-Host "Competitor FirstnameLastname"
  } until ( $COMPETITOR.length -ge 2 )
}

# Set SERVER_IP
If ( isIp $args[2] )
{
  $SERVER_IP = $args[2]
}
else
{
  Do
  {
    $SERVER_IP = Read-Host "IP address ESXi"
  } until ( isIP $SERVER_IP -eq $False )
}

# Create output file
$FILE = [string]$STAND + '_RESULT' + '.txt'
Write-Output '' > $FILE

# Connect to Server and ignore invalid certificate
Set-PowerCLIConfiguration -DefaultVIServerMode Multiple     `
                          -InvalidCertificateAction Ignore  `
                          -Confirm:$false
Connect-VIServer -Server $SERVER_IP -User $LOGIN_ESXi -Password $PASS_ESXi

# Start all VMs and delay for VM power on
Get-VM | Where-Object { $_.PowerState -eq 'PoweredOff' } | Start-VM
Start-Sleep -s $DELAY

###########################--=START=--##################################

$DATE = Get-Date
Write-Output $DATE        | Out-File $FILE -Append -NoClobber
Write-Output $COMPETITOR  | Out-File $FILE -Append -NoClobber

# TODO: A1.1 Hostnames
SendScript -VM 'L-CLI-A', 'R-SRV', 'OUT-CLI'                     `
           -Script 'cat /etc/hostname'                `
           -Description 'Hostnames'
           
# TODO: A1.2 IPv4 connectivity
SendScript -VM 'L-CLI-B', 'R-CLI', 'L-SRV'                     `
           -Script 'ping -c 4 2.2.2.2'                `
           -Description 'IPv4 connectivity'

# TODO: A1.3 Software installation
SendScript -VM 'L-SRV', 'R-RTR', 'OUT-CLI'                       `
           -Script 'whereis tcpdump vim lynx curl'    `
           -Description 'Software installation'

# TODO: A1.4 Local hostname table
SendScript -VM 'OUT-CLI', 'L-RTR-B', 'R-SRV'               `
           -Script 'cat /etc/hosts'                   `
           -Description 'Local hostname table'

# TODO: A1.5 Name lookup order
SendScript -VM 'OUT-CLI', 'L-RTR-B', 'R-SRV'                   `
           -Script "grep '^hosts' /etc/nsswitch.conf" `
           -Description 'Name lookup order'

# TODO: A1.6 DHCP-A: Basic Operation
$SCRIPT = 'dhclient -r &> /dev/null; dhclient -v &> /dev/null; ip a | sed -n 7,9p; ip r'
SendScript -VM 'L-CLI-A'                              `
           -Script $SCRIPT                            `
           -Description 'DHCP-A: Basic Operation'

# TODO: A1.7 DHCP-A: Additional Parameters
SendScript -VM 'L-CLI-A'                              `
           -Script 'cat /etc/resolv.conf'             `
           -Description 'DHCP-A: Additional Parameters'

# TODO: A1.8 DHCP-B: Basic Operation
$SCRIPT = 'dhclient -r &> /dev/null; dhclient -v &> /dev/null; ip a | sed -n 7,9p; ip r'
SendScript -VM 'L-CLI-B'                              `
           -Script $SCRIPT                            `
           -Description 'DHCP-B: Basic Operation'

# TODO: A1.9 DHCP-B: Additional Parameters
SendScript -VM 'L-CLI-B'                              `
           -Script 'cat /etc/resolv.conf'             `
           -Description 'DHCP-B: Additional Parameters'

# TODO: A1.10 DNS: Forward zone
$SCRIPT = 'host l-srv.skill39.wsr; host server.skill39.wsr; host www.skill39.wsr'
SendScript -VM 'L-CLI-A'                              `
           -Script $SCRIPT                            `
           -Description 'DNS: Forward zone'

# TODO: A1.11 DNS: Reverse zone
$SCRIPT = 'host 172.16.20.10; host 192.168.20.10'
SendScript -VM 'L-CLI-A'                              `
           -Script $SCRIPT                            `
           -Description 'DNS: Reverse zone'

# TODO: A1.12 DNS: ISP Forwarders
SendScript -VM 'L-CLI-A'                                `
           -Script 'host ya.ru'                       `
           -Description 'DNS: ISP Forwarders'

# TODO: A1.14 DNS: Dynamic DNS
# 1. Resolve L-CLI-A
SendScript -VM 'L-CLI-B'                              `
           -Script 'host L-CLI-A'                     `
           -Description 'DNS: Dynamic DNS'

# 2. Rental exemption L-CLI-A
SendScript -VM 'L-CLI-A'                              `
           -Script 'dhclient -r &> /dev/null; sleep 5'

# 3. Resolve again
SendScript -VM 'L-CLI-B'                              `
           -Script 'host L-CLI-A'

# 4. Request address L-CLI-A
SendScript -VM 'L-CLI-A'                              `
           -Script 'dhclient -v &> /dev/null'

# 5. Resolve again
SendScript -VM 'L-CLI-B'                              `
           -Script 'host L-CLI-A'

# TODO: A1.15 Internet Gateway (Dynamic NAT)-LEFT
SendScript -VM 'L-CLI-A'                              `
           -Script 'ping 20.20.20.10 -c 4'            `
           -Description 'Internet Gateway (Dynamic NAT)-LEFT'

# TODO: A1.16 Internet Gateway (Dynamic NAT)-RIGHT
SendScript -VM 'R-CLI'                                `
           -Script 'ping 10.10.10.10 -c 4'            `
           -Description 'Internet Gateway (Dynamic NAT)-RIGHT'

# TODO: A1.17 DNS-Proxy
SendScript -VM 'OUT-CLI'                              `
           -Script 'host www.skill39.wsr 10.10.10.1'             `
           -Description 'DNS-Proxy'

# TODO: A2.1 LDAP: Users, Groups and OU
$SCRIPT = 'slapcat | grep dn'
SendScript -VM 'L-SRV'                                `
           -Script $SCRIPT                            `
           -Description 'LDAP: Users, Groups and OU'

# TODO: A2.2 LDAP: Clients authentication
# 1. Login from tux
$SCRIPT = 'test=`grep ^tux /etc/passwd`; [[ -z "$test" ]] && echo "LDAP Success and Local user not exist" || echo "Local user exist, LDAP authentication failed"'
SendScript -VM 'L-CLI-A'                              `
           -Script $SCRIPT                            `
           -Username 'tux'                            `
           -Password 'toor'                           `
           -Description 'LDAP: Clients authentication'

# 2. Login from user
$SCRIPT = 'test=`grep ^user /etc/passwd`; [[ -z "$test" ]] && echo "LDAP Success and Local user not exist" || echo "Local user exist, LDAP authentication failed"'
SendScript -VM 'L-CLI-B'                              `
           -Script $SCRIPT                            `
           -Username 'user'                           `
           -Password 'P@ssw0rd'

# TODO: A2.3 Syslog: L-SRV
$SCRIPT = 'logger -p auth.err AUTH FROM L-SRV; grep "AUTH FROM L-SRV" /opt/logs/L-SRV/auth.log'
SendScript -VM 'L-SRV'                                `
           -Script $SCRIPT                            `
           -Description 'Syslog: L-SRV'

# TODO: A2.4 Syslog: L-FW
$SCRIPT = 'grep 172.16.20.10 /etc/rsyslog.conf && logger -p err ERROR FROM L-FW'
SendScript -VM 'L-FW'                                `
           -Script $SCRIPT                           `
           -Description 'Syslog: L-FW'

$SCRIPT = 'grep "ERROR FROM L-FW" /opt/logs/L-FW/error.log'
SendScript -VM 'L-SRV'                                `
           -Script $SCRIPT

# TODO: A3.1 RA: OpenVPN basic
$SCRIPT = 'echo -e "\n Files: "; ls /opt/vpn /etc/openvpn; echo -e "\n Port: " ss -natu | grep 1122; echo -e "\n Unit status: " &&  systemctl status openvpn@server | cat | grep Active; echo -e "\n Config file: " && grep -v "^[# $ ;]" /etc/openvpn/*.conf | grep -v "^$"'
SendScript -VM 'L-FW'                                 `
           -Script $SCRIPT                            `
           -Description 'RA: OpenVPN basic'

# TODO: A3.2 RA: VPN Clients have full access to LEFT and RIGHT LANs
$SCRIPT = 'echo -e "\n Files: "; ls /opt/vpn; start_vpn.sh; sleep 5; echo -e "\n ping test LEFT: "; ping L-SRV.skill39.wsr -c 2'
SendScript -VM 'OUT-CLI'                              `
           -Script $SCRIPT                            `
           -Description 'RA: VPN Clients have full access to LAN'

# TODO: A3.3 IPSEC + GRE
$SCRIPT = 'ipsec status | grep connections:'
SendScript -VM 'R-FW'                                 `
           -Script $SCRIPT                            `
           -Description 'IPSEC + GRE'
$SCRIPT = 'ipsec status'
SendScript -VM 'L-FW'                                 `
           -Script $SCRIPT                            `

# TODO: A3.4 GRE Tunnel Cinnectivity
$SCRIPT = 'ping 10.5.5.1 -c 2'
SendScript -VM 'R-FW'                                 `
           -Script $SCRIPT                            `
           -Description 'GRE Tunnel Cinnectivity'
$SCRIPT = 'ping 10.5.5.2 -c 2'
SendScript -VM 'L-FW'                                 `
           -Script $SCRIPT                            `

# TODO: A3.5 FRR: Neigbours 
SendScript -VM 'L-FW','R-FW'                          `
           -Script 'vtysh -E -c "show ip ospf ne"'    `
           -Description 'FRR: Neigbours'

# TODO: A3.6 FRR: Local interfaces 
SendScript -VM 'L-FW','R-FW'                          `
           -Script 'vtysh -E -c "show run"'           `
           -Description 'FRR: Local interfaces'

# TODO: A3.7 FRR: Passive interfaces
SendScript -VM 'L-RTR-A','R-RTR'                      `
           -Script 'vtysh -E -c "show run"'           `
           -Description 'FRR: Local interfaces'

# TODO: A3.8 SSH: Users
SendScript -VM 'OUT-CLI'                              `
           -Script 'sshpass -p ssh_pass ssh -T -o StrictHostKeyChecking=no ssh_c@l-fw.skill39.wsr id'       `
           -Description 'SSH: Users'

SendScript -VM 'OUT-CLI'                              `
           -Script 'sshpass -p toor ssh -T -o StrictHostKeyChecking=no ssh_c@l-fw.skill39.wsr id'        `

# TODO: A3.9 SSH: Key authentication
SendScript -VM 'OUT-CLI'                              `
           -Script 'ssh -T -o StrictHostKeyChecking=no ssh_p@l-fw.skill39.wsr id'       `
           -Description 'SSH: Key authentication'

# TODO: A4.1 Apache: Port, PHP
SendScript -VM 'R-SRV'                                `
           -Script 'ss -natu | grep 80'                   `
           -Description 'Apache: Port'

SendScript -VM 'R-CLI'                                `
           -Script 'wget http://www.skill39.wsr -O-'                   `
           -Description 'Apache: index'

SendScript -VM 'R-CLI'                                `
           -Script 'wget http://www.skill39.wsr/date.php -O-'                   `
           -Description 'Apache: PHP'

# TODO: A4.2 rsync: L-SRV configuration
SendScript -VM 'L-SRV'                                `
           -Script 'cat /etc/rsyncd.conf; echo -e "\n Unit status: "; systemctl status rsync | grep Active'                            `
           -Description 'rsync: L-SRV configuration'

# TODO: A4.3 rsync: Client sync 
# 1. Create file
SendScript -VM 'L-SRV'                                `
           -Script 'rm -rf /opt/sync/*; echo rsync work! > /opt/sync/aasdfljaxczvi123; ls -las /opt/sync'                            `
           -Description 'rsync: Client sync'
           
# 2. Check sync
SendScript -VM 'L-CLI-A','L-CLI-B'                    `
           -Script 'echo -e "\n Script: "; cat /root/sync.sh; rm -rf /root/sync/*; echo -e "\n Before Sync: "; ls -las /root/sync/; sleep 61; echo -e "\n After Sync: "; ls -las /root/sync'
        
# TODO: A5.1 OpenSSL: CA
SendScript -VM 'R-FW'                                 `
           -Script '[[ -d /etc/ca ]] && ls -las /etc/ca || echo "Directory /etc/ca Not Exist!"'                          `
           -Description 'OpenSSL: CA'

# TODO: A5.2 Certificate Attributes
SendScript -VM 'R-FW'                                 `
           -Script 'head /etc/ca/cacert.pem'                          `
           -Description 'Certificate Attributes'

# TODO: A5.3 IPTables: Block traffic
$SCRIPT = 'iptables -t filter -L -v | grep Chain'
SendScript -VM 'L-FW'                                 `
           -Script $SCRIPT                            `
           -Description 'IPTables: Block traffic'

# TODO: A5.4 IPTables: Allow only nessesary traffic
$SCRIPT = 'iptables -t filter -L -v'
SendScript -VM 'L-FW'                                 `
           -Script $SCRIPT                            `
           -Description 'IPTables: Allow only nessesary traffic'

# TODO: A5.5 Firewalld: Block traffic 
$SCRIPT = 'firewall-cmd --list-all-zones'
SendScript -VM 'R-FW'                                 `
           -Script $SCRIPT                            `
           -Description 'IPTables: Allow only nessesary traffic'

$DATE = Get-Date
Write-Output $DATE        | Out-File $FILE -Append -NoClobber