function Get-LinuxCdpInfo {
    # Requires -Module Posh-SSH -Version 3.0
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

    begin {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
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
            try {
                $SshSession = New-SSHSession -ComputerName $ComputerName -Credential $Credential -AcceptKey -Force

                $Result = Invoke-SSHCommand -SSHSession $SshSession -Command 'tcpdump -D'
                foreach ($Line in $Result.Output) {
                    if ($Line -notmatch '^[0-9]+.usbmon') {
                        $InterfacesFromTcpdump += $Line.Trim().Split('.')[1]
                    }
                }
                Write-Debug -Message "Active interface list from tcpdump`n$($InterfacesFromTcpdump | Out-String)"

                foreach ($Filter in $Interface) {
                    $IfaceList += $InterfacesFromTcpdump | Where-Object { $_ -like $Filter }
                    Write-Debug -Message "Interfaces matching filter $($Filter):`n$($IfaceList | Out-String)"
                }

                foreach ($Iface in $IfaceList) {
                    $Command = "tcpdump -i $Iface -v -nn -s 1500 -c 1 -G 60 'ether[20:2] == 0x2000'"
                    $Result = Invoke-SSHCommand -SSHSession $SshSession -Command $Command
                    Write-Debug -Message ($Result.Output | Out-String)

                    $NativeVlan = ($Result.Output | Where-Object { $_ -match '\(0x0a\)' }).ToString().Split(' ')[-1] -replace ("'", "")
                    $PortName = ($Result.Output | Where-Object { $_ -match '\(0x03\)' }).ToString().Split(' ')[-1] -replace ("'", "")
                    $PortAbbreviation.GetEnumerator() | ForEach-Object { $PortName = $PortName.Replace($_.Name, $_.Value) }
                    $SwitchAdress = ($Result.Output | Where-Object { $_ -match '\(0x02\)' }).ToString().Split(' ')[-1] -replace ("'", "")
                    $SwitchName = ($Result.Output | Where-Object { $_ -match '\(0x01\)' }).ToString().Split(' ')[-1] -replace ("'", "")
                    $Output = New-Object -TypeName PSObject -Property @{
                        'ComputerName'  = $ComputerName
                        'Interface'     = $Iface
                        'NativeVlan'    = $NativeVlan
                        'PortName'      = $PortName
                        'SwitchAddress' = $SwitchAdress
                        'SwitchName'    = $SwitchName
                    }
                    $Output.PSObject.TypeNames.Insert(0, 'ServerManagement.CdpInfo')
                    Write-Output -InputObject $Output
                }
            }
            catch {
                throw
            }
            finally {
                if ($SshSession) {
                    $SshSession.Disconnect()
                    $null = Remove-SSHSession $SshSession
                }
            } #finally
        }
    }

    process {
        if ($DebugPreference) {
            foreach ($Computer in $ComputerName) {
                & $ScriptBlock -ComputerName $Computer -Interface $Interface -Credential $Credential
            }
        }
        else {
            foreach ($Computer in $ComputerName) {
                if (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
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
                else {
                    Write-Warning -Message "Cannot connect to computer '$Computer', because it is offline."
                }
            }
            $JobCount = $Commands.Count

            while ($Commands) {
                Write-Progress -Activity "Querying CDP Information" -Status "$($Commands.Count) Remaining" -PercentComplete (($JobCount - $Commands.Count) / $JobCount * 100)
                foreach ($Command in $Commands.ToArray()) {
                    if ($Command.Handle.IsCompleted -eq $true) {
                        Write-Output -InputObject $Command.PowerShell.EndInvoke($Command.Handle)
                        $Command.PowerShell.Dispose()
                        $Commands.Remove($Command)
                    }
                }
                Start-Sleep -Milliseconds 500
            }
        }
    }

    end {
        $RunspacePool.Close()
        $RunspacePool.Dispose()
    }
}
