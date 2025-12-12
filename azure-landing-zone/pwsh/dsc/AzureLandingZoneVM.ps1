# PowerShell DSC Configuration for Azure Landing Zone VMs
# This configuration ensures VMs are properly configured with security settings

Configuration AzureLandingZoneVM {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $false)]
        [string]$TimeZone = 'Eastern Standard Time'
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName SecurityPolicyDsc -ModuleVersion 2.10.0.0

    Node $ComputerName {
        
        # Ensure Windows Features are properly configured
        WindowsFeature RemoteDesktop {
            Name   = 'Remote-Desktop-Services'
            Ensure = 'Present'
        }

        WindowsFeature TelnetClient {
            Name   = 'TelnetClient'
            Ensure = 'Absent'
        }

        # Configure Registry settings for security
        Registry DisableAutoAdminLogon {
            Key       = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
            ValueName = 'AutoAdminLogon'
            ValueData = '0'
            ValueType = 'String'
            Ensure    = 'Present'
        }

        Registry EnableSecureBootUEFI {
            Key       = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecureBoot\State'
            ValueName = 'UEFISecureBootEnabled'
            ValueData = '1'
            ValueType = 'DWord'
            Ensure    = 'Present'
        }

        # Configure Time Zone
        Registry TimeZoneConfiguration {
            Key       = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'
            ValueName = 'TimeZoneKeyName'
            ValueData = $TimeZone
            ValueType = 'String'
            Ensure    = 'Present'
        }

        # Configure Windows Firewall
        Registry EnableFirewall {
            Key       = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile'
            ValueName = 'EnableFirewall'
            ValueData = '1'
            ValueType = 'DWord'
            Ensure    = 'Present'
        }

        # Ensure Windows Update service is running
        Service WindowsUpdate {
            Name        = 'wuauserv'
            State       = 'Running'
            StartupType = 'Automatic'
        }

        # Configure Local Security Policy
        UserRightsAssignment LogonAsService {
            Policy   = 'Log_on_as_a_service'
            Identity = @('NT SERVICE\ALL SERVICES')
        }

        UserRightsAssignment DenyNetworkLogon {
            Policy   = 'Deny_access_to_this_computer_from_the_network'
            Identity = @('Guest')
        }

        # Configure Account Policies
        AccountPolicy PasswordPolicy {
            Name                            = 'Password Policy'
            Enforce_password_history        = 24
            Maximum_Password_Age            = 90
            Minimum_Password_Age            = 1
            Minimum_Password_Length         = 14
            Password_must_meet_complexity_requirements = 'Enabled'
            Store_passwords_using_reversible_encryption = 'Disabled'
        }

        AccountPolicy AccountLockoutPolicy {
            Name                          = 'Account Lockout Policy'
            Account_lockout_duration      = 30
            Account_lockout_threshold     = 5
            Reset_account_lockout_counter_after = 30
        }

        # File and Folder configurations
        File TempDirectory {
            DestinationPath = 'C:\Temp'
            Type            = 'Directory'
            Ensure          = 'Present'
        }

        File LogsDirectory {
            DestinationPath = 'C:\Logs'
            Type            = 'Directory'
            Ensure          = 'Present'
        }

        # Environment variables
        Environment TempPath {
            Name   = 'TEMP'
            Value  = 'C:\Temp'
            Ensure = 'Present'
        }

        Environment TmpPath {
            Name   = 'TMP'
            Value  = 'C:\Temp'
            Ensure = 'Present'
        }
    }
}