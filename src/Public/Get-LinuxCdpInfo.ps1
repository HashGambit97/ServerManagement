# Requires -Module Posh-SSH -Version 3.0
function Get-LinuxCdpInfo
{
    <#
    .SYNOPSIS
        Retrieves CDP information from Linux machines.

    .DESCRIPTION
        The Get-LinuxCdpInfo cmdlet retrieves CDP information from Linux machines using SSH and tcpdump.  The cmdlet connects to the target machine, retrieves a list of active network interfaces, and then listens for CDP packets on those interfaces to extract information about connected switches and ports.

    .PARAMETER ComputerName
        Specifies the name of the system to target.

    .PARAMETER Interface
        Specifies a wildcard selection string of network interfaces to monitor for CDP packets.  The default
        value is 'eth0'.

    .PARAMETER Credential
        Specifies the credentials to use for connecting to the remote computer.

    .PARAMETER Concurrency
        Specifies the number of concurrent SSH sessions to use when connecting to multiple computers.  The default
        value is 8.

    .EXAMPLE
        Get-LinuxCdpInfo -ComputerName 'MyLinuxServer' -Credential (Get-Credential)
        Retrieves CDP information from 'MyLinuxServer' using the provided credentials.

    .NOTES
        Author: Trent Willingham
        Check out my other projects on GitHub https://github.com/HashGambit97
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string[]]$ComputerName,

        [Parameter()]
        [string[]]$Interface = 'eth0',

        [Parameter(Mandatory = $true)]
        [pscredential]$Credential,

        [parameter()]
        [int] $Concurrency = 8
    )

    begin
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '')]
        $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, ($Concurrency + 1))
        $RunspacePool.Open()
        $PowerShell = [powershell]::Create()
        $PowerShell.RunspacePool = $RunspacePool
        $Commands = New-Object -TypeName System.Collections.ArrayList

        $ScriptBlock = {
            param(
                [string]$ComputerName,
                [string]$Interface,
                [pscredential]$Credential
            )
            $PortAbbreviation = @{
                "FastEthernet"       = "Fa "
                "GigabitEthernet"    = "Gi "
                "TenGigabitEthernet" = "Te "
            }
            $InterfacesFromTcpdump = @()
            try
            {
                $SshSession = New-SSHSession -ComputerName $ComputerName -Credential $Credential -AcceptKey -Force

                $Result = Invoke-SSHCommand -SSHSession $SshSession -Command 'tcpdump -D'
                foreach ($Line in $Result.Output)
                {
                    if ($Line -notmatch '^[0-9]+.usbmon')
                    {
                        $InterfacesFromTcpdump += $Line.Trim().Split('.')[1]
                    }
                }
                Write-Debug -Message "Active interface list from tcpdump`n$($InterfacesFromTcpdump | Out-String)"

                foreach ($Filter in $Interface)
                {
                    $InterfaceList += $InterfacesFromTcpdump | Where-Object { $_ -like $Filter }
                    Write-Debug -Message "Interfaces matching filter $($Filter):`n$($InterfaceList | Out-String)"
                }

                foreach ($Interface in $InterfaceList)
                {
                    $Command = "tcpdump -i $Interface -v -nn -s 1500 -c 1 -G 60 'ether[20:2] == 0x2000'"
                    $Result = Invoke-SSHCommand -SSHSession $SshSession -Command $Command
                    Write-Debug -Message ($Result.Output | Out-String)

                    $NativeVlan = ($Result.Output | Where-Object { $_ -match '\(0x0a\)' }).ToString().Split(' ')[-1] -replace ("'", "")
                    $PortName = ($Result.Output | Where-Object { $_ -match '\(0x03\)' }).ToString().Split(' ')[-1] -replace ("'", "")
                    $PortAbbreviation.GetEnumerator() | ForEach-Object { $PortName = $PortName.Replace($_.Name, $_.Value) }
                    $SwitchAddress = ($Result.Output | Where-Object { $_ -match '\(0x02\)' }).ToString().Split(' ')[-1] -replace ("'", "")
                    $SwitchName = ($Result.Output | Where-Object { $_ -match '\(0x01\)' }).ToString().Split(' ')[-1] -replace ("'", "")
                    $Output = New-Object -TypeName PSObject -Property @{
                        'ComputerName'  = $ComputerName
                        'Interface'     = $Interface
                        'NativeVlan'    = $NativeVlan
                        'PortName'      = $PortName
                        'SwitchAddress' = $SwitchAddress
                        'SwitchName'    = $SwitchName
                    }
                    $Output.PSObject.TypeNames.Insert(0, 'ServerManagement.CdpInfo')
                    Write-Output -InputObject $Output
                }
            }
            catch
            {
                throw
            }
            finally
            {
                if ($SshSession)
                {
                    $SshSession.Disconnect()
                    $null = Remove-SSHSession $SshSession
                }
            } #finally
        }
    }

    process
    {
        if ($DebugPreference)
        {
            foreach ($Computer in $ComputerName)
            {
                & $ScriptBlock -ComputerName $Computer -Interface $Interface -Credential $Credential
            }
        }
        else
        {
            foreach ($Computer in $ComputerName)
            {
                if (Test-Connection -ComputerName $Computer -Count 1 -Quiet)
                {
                    $PowerShellInstance = [powershell]::Create()
                    $PowerShellInstance.RunspacePool = $RunspacePool
                    [void]$PowerShellInstance.AddScript($ScriptBlock)

                    [void]$PowerShellInstance.AddParameter('ComputerName', "$Computer")
                    [void]$PowerShellInstance.AddParameter('Credential', $Credential)
                    [void]$PowerShellInstance.AddParameter('Interface', "$Interface")
                    [void]$PowerShellInstance.AddParameter('DebugPreference', $DebugPreference)
                    [void]$PowerShellInstance.AddParameter('VerbosePreference', $VerbosePreference)

                    $Handle = $PowerShellInstance.BeginInvoke()

                    $Temp = '' | Select-Object -Property ComputerName, PowerShell, Handle
                    $Temp.ComputerName = $Computer
                    $Temp.PowerShell = $PowerShellInstance
                    $Temp.Handle = $Handle
                    [void]$Commands.Add($Temp)
                }
                else
                {
                    Write-Warning -Message "Cannot connect to computer '$Computer', because it is offline."
                }
            }
            $JobCount = $Commands.Count

            while ($Commands)
            {
                Write-Progress -Activity "Querying CDP Information" -Status "$($Commands.Count) Remaining" -PercentComplete (($JobCount - $Commands.Count) / $JobCount * 100)
                foreach ($Command in $Commands.ToArray())
                {
                    if ($Command.Handle.IsCompleted -eq $true)
                    {
                        Write-Output -InputObject $Command.PowerShell.EndInvoke($Command.Handle)
                        $Command.PowerShell.Dispose()
                        $Commands.Remove($Command)
                    }
                }
                Start-Sleep -Milliseconds 500
            }
        }
    }

    end
    {
        $RunspacePool.Close()
        $RunspacePool.Dispose()
    }
}
