###################################################
# Ensure the powershell moduel is insalled
Install-Module -Name Posh-SSH -Force -AllowClobber
###################################################

# Define switch details
$switches = @(
    @{IP = "192.168.0.83"; Username = "admin"; Password = "P@`$`$w0rd"}
    @{IP = "192.168.0.83"; Username = "admin"; Password = "P@`$`$w0rd"}
    # Add more switches as needed
)

# Define SNMPv3 credentials
$newAuthPassword = "AaBbCcDdEe1235"    # New SNMPv3 Auth Password
$newPrivPassword = "123456789AaBbDd"    # New SNMPv3 Priv Password
$snmpUser = "snmpv3user"                   # Existing SNMPv3 User
$snmpgroup = "SNMPv3GROUP"              # Existing SNMPv3 Group

# Load SSH session module
Import-Module Posh-SSH

# Iterate through each device
foreach ($switch in $switches) {
    try {
        # Remove all sessions
        Get-SSHSession | Remove-SSHSession 

        # Establish SSH session
        $session = New-SSHSession -ComputerName $switch.IP -Credential (New-Object PSCredential($switch.Username, (ConvertTo-SecureString $switch.Password -AsPlainText -Force)))
        
        if ($session -ne $null) {
            # Command to enter global configuration mode
            $configMode = "configure terminal"
            
            # Commands to update SNMPv3 passwords
            $authPassCmd = "snmp-server user $($snmpUser) $($snmpgroup) v3 auth sha $($newAuthPassword) priv aes 128 $($newPrivPassword)"
            $exitConfigCmd = "end"
            $saveConfigCmd = "write memory"

            # New steaming session
            $SSHStream = New-SSHShellStream -Index 0

            #Excecute commands
            $SSHStream.WriteLine("
                $configMode
                $authPassCmd
                $exitConfigCmd
                $saveConfigCmd
            ")
            $SSHStream.read()

            Write-Output "SNMPv3 password updated successfully on switch $($switch.IP)"
        } else {
            Write-Output "Failed to connect to switch $($switch.IP)"
        }
    }
    catch {
        Write-Output "Error updating SNMPv3 password on switch $($switch.IP): $_"
    }
    finally {
        # Close SSH session
        Remove-SSHSession -SessionId ($session.SessionId)
    }
}

