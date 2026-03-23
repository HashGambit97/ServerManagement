function Get-RDSession
{
    <#
    .SYNOPSIS
        Lists Remote Desktop sessions on a given server.

    .DESCRIPTION
        The Get-RDSession cmdlet retrieves a list of Remote Desktop sessions from a local or remote computer.

    .PARAMETER ComputerName
        Specifies the name of the system to target.  The default value is 'localhost'.

    .PARAMETER State
        Filters sessions by their connection state.  The default value is '*' (all states).

    .PARAMETER ClientName
        Filters sessions by the client name.  The default value is '*' (all client names).

    .PARAMETER UserName
        Filters sessions by the user name.  The default value is '*' (all user names).

    .EXAMPLE
        Get-RDSession -ComputerName 'Server01' -State 'Active'
        This command retrieves all active Remote Desktop sessions from the computer named 'Server01'.

    .EXAMPLE
        Get-RDSession -ComputerName 'Server01' -UserName 'JohnDoe'
        This command retrieves all Remote Desktop sessions from the computer named 'Server01' that are associated with the user 'JohnDoe'.

    .NOTES
        Author: Trent Willingham
        Check out my other projects on GitHub https://github.com/HashGambit97
    #>

    [CmdletBinding()]
    [OutputType('Cassia.Impl.TerminalServicesSession')]

    param(
        [Parameter(
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias('DSNHostName', 'Name', 'Computer')]
        [string]$ComputerName = 'localhost',

        [Parameter()]
        [ValidateSet('Active', 'Connected', 'ConnectQuery', 'Disconnected', 'Down', 'Idle', 'Initializing', 'Listening', 'Reset', 'Shadowing')]
        [Alias('ConnectionState')]
        [string]$State = '*',

        [Parameter()]
        [string]$ClientName = '*',

        [Parameter()]
        [string]$UserName = '*'
    )

    begin
    {
        try
        {
            Write-Verbose -Message 'Creating instance of the Cassia TSManager.'
            $TSManager = New-Object -TypeName Cassia.TerminalServicesManager
        }
        catch
        {
            throw
        }
    }

    process
    {
        Write-Verbose -Message ($LocalizedData.RemoteConnect -f $ComputerName)
        if (!(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet))
        {
            Write-Warning -Message ($LocalizedData.ComputerOffline -f $ComputerName)
            return
        }
        try
        {
            $TSRemoteServer = $TSManager.GetRemoteServer($ComputerName)
            $TSRemoteServer.Open()
            if (!($TSRemoteServer.IsOpen))
            {
                throw ($LocalizedData.RemoteConnectError -f $ComputerName)
            }

            $Session = $TSRemoteServer.GetSessions()
            if ($Session)
            {
                $Session | Where-Object { $_.ConnectionState -like $State -and $_.UserName -like $UserName -and $_.ClientName -like $ClientName } |
                    Add-Member -MemberType AliasProperty -Name IPAddress -Value ClientIPAddress -PassThru |
                        Add-Member -MemberType AliasProperty State -Value ConnectionState -PassThru
            }
        }
        catch
        {
            throw
        }
        finally
        {
            $TSRemoteServer.Close()
            $TSRemoteServer.Dispose()
        }
    }

    end
    {
    }
}
